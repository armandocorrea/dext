# Model Binding Analysis - Dext Framework

## ✅ STATUS: IMPLEMENTADO E TESTADO

**Data de Implementação**: 2026-01-15  
**Resultado Final**: ✅ **22/22 testes passaram** (100%)

## Resumo Executivo

Este documento apresenta uma análise detalhada do sistema de Model Binding do Dext Framework, identificando o comportamento atual (mesmo com falhas), as falhas encontradas, e propondo uma correção para garantir que o binding funcione corretamente tanto para **Minimal API** quanto para **Controllers**.

**Problema Original**: O campo `TenantId` marcado com `[FromHeader('X-Tenant-Id')]` não é preenchido em requests POST na Minimal API.

**Solução Implementada**: 
- Novo método `BindRecordHybrid` em `TModelBinder`
- `ResolveArgument<T>` atualizado para usar `BindRecordHybrid` para records
- `BindParameter` para controllers também usa `BindRecordHybrid` para records
- Suporte completo a binding misto (Header + Body + Query + Route)
- Tratamento gracioso de erros de parse JSON

**Testes**: Ver `Tests/ModelBinding/` para suite de testes completa.

---

## Índice

1. [Arquitetura Atual](#1-arquitetura-atual)
2. [Fluxo de Binding - Como Funciona Hoje](#2-fluxo-de-binding---como-funciona-hoje)
3. [Falhas Identificadas](#3-falhas-identificadas)
4. [Comportamento Esperado](#4-comportamento-esperado)
5. [Proposta de Correção](#5-proposta-de-correção)
6. [Plano de Implementação](#6-plano-de-implementação)
7. [Casos de Teste](#7-casos-de-teste)

---

## 1. Arquitetura Atual

### 1.1 Componentes Principais

```
┌─────────────────────────────────────────────────────────────────┐
│                         Model Binding System                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  📁 Dext.Web.ModelBinding.pas                                   │
│  ├── TBindingSource (enum): bsBody, bsQuery, bsRoute,           │
│  │   bsHeader, bsServices, bsForm                               │
│  ├── BindingAttribute (abstract base)                           │
│  ├── FromBodyAttribute                                           │
│  ├── FromQueryAttribute                                          │
│  ├── FromRouteAttribute                                          │
│  ├── FromHeaderAttribute  ◄─── Atributo usado no Multi-Tenancy  │
│  ├── FromServicesAttribute                                       │
│  ├── IModelBinder (interface)                                    │
│  ├── TModelBinder (implementation)                               │
│  └── TBindingSourceProvider                                      │
│                                                                  │
│  📁 Dext.Web.HandlerInvoker.pas                                 │
│  ├── THandlerInvoker                                             │
│  │   ├── ResolveArgument<T>()  ◄─── Usado pela Minimal API      │
│  │   ├── Invoke<T>()                                            │
│  │   ├── Invoke<T1, T2>()                                       │
│  │   └── InvokeAction()  ◄─── Usado por Controllers             │
│  └── THandler* types                                            │
│                                                                  │
│  📁 Dext.Web.ApplicationBuilder.Extensions.pas                  │
│  └── TApplicationBuilderExtensions                               │
│       └── MapPost/MapGet/etc  ◄─── Entry point Minimal API       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Fluxos de Binding

Existem **DOIS FLUXOS DISTINTOS** de binding no framework:

#### Fluxo A: Controllers (usa RTTI completo)
```
THandlerInvoker.InvokeAction()
    └── FModelBinder.BindMethodParameters(AMethod, AContext)
            └── BindParameter(AParam) [para cada parâmetro]
                    └── Lê atributos do TRttiParameter ✅
                    └── Suporta [FromHeader] ✅
```

#### Fluxo B: Minimal API (usa genéricos, sem RTTI de parâmetros)
```
TApplicationBuilderExtensions.MapPost<T1, T2, TResult>()
    └── THandlerInvoker.Invoke<T1, T2, TResult>(Handler)
            └── ResolveArgument<T1>() / ResolveArgument<T2>()
                    └── NÃO LÊ atributos dos tipos ❌
                    └── Aplica regras "mágicas" por convenção
```

---

## 2. Fluxo de Binding - Como Funciona Hoje

### 2.1 Controllers - `BindParameter(AParam: TRttiParameter)`

**Localização**: `Dext.Web.ModelBinding.pas` linhas 822-949

O método `BindParameter` funciona corretamente para Controllers porque:

1. Recebe `TRttiParameter` com informação RTTI completa
2. Itera sobre `AParam.GetAttributes` para encontrar atributos de binding
3. Suporta `FromHeaderAttribute` (linhas 881-893)

```pascal
// Linhas 881-893
else if Attr is FromHeaderAttribute then
begin
  ParamName := FromHeaderAttribute(Attr).Name;
  if ParamName = '' then ParamName := AParam.Name;

  WriteLn(Format('    📨 FromHeader: %s', [ParamName]));
  var Headers := AContext.Request.Headers;
  if Headers.ContainsKey(LowerCase(ParamName)) then
    Result := ConvertStringToType(Headers[LowerCase(ParamName)], AParam.ParamType.Handle)
  else
    Result := ConvertStringToType('', AParam.ParamType.Handle); // Default
  Exit;
end;
```

### 2.2 Minimal API - `ResolveArgument<T>`

**Localização**: `Dext.Web.HandlerInvoker.pas` linhas 147-201

O método `ResolveArgument<T>` **NÃO LÊATRIBUTOS** do tipo `T`. Comportamento atual:

```pascal
function THandlerInvoker.ResolveArgument<T>: T;
begin
  Result := Default(T);
  
  // 1. IHttpContext - OK
  if TypeInfo(T) = TypeInfo(IHttpContext) then
    Result := TValue.From<IHttpContext>(FContext).AsType<T>
    
  // 2. TGUID/TUUID - Route binding
  else if (TypeInfo(T) = TypeInfo(TGUID)) or (TypeInfo(T) = TypeInfo(TUUID)) then
  begin
    if FContext.Request.RouteParams.Count > 0 then
      Result := TModelBinderHelper.BindRoute<T>(FModelBinder, FContext)
    else
      Result := TModelBinderHelper.BindQuery<T>(FModelBinder, FContext);
  end
  
  // 3. Records/Classes - PROBLEMA: Assume Body ou Query baseado no Method
  else if (PTypeInfo(TypeInfo(T)).Kind = tkRecord) or 
          (PTypeInfo(TypeInfo(T)).Kind = tkClass) then
  begin
    // Para Classes, tenta DI primeiro
    // ...
    
    // Smart Binding: GET/DELETE -> Query, POST/PUT/PATCH -> Body
    if (FContext.Request.Method = 'GET') or (FContext.Request.Method = 'DELETE') then
      Result := TModelBinderHelper.BindQuery<T>(FModelBinder, FContext)
    else
      Result := TModelBinderHelper.BindBody<T>(FModelBinder, FContext);  // ❌ Só Body!
  end
  
  // 4. Interfaces - Services
  else if PTypeInfo(TypeInfo(T)).Kind = tkInterface then
    Result := FModelBinder.BindServices(TypeInfo(T), FContext).AsType<T>
    
  // 5. Primitives - Route/Query
  else
  begin
    // ...
  end;
end;
```

**PROBLEMA CRÍTICO**: Para POST com Records, `ResolveArgument<T>` chama apenas `BindBody`, que:
- Lê o JSON do body
- **NÃO considera campos marcados com `[FromHeader]` dentro do record**

### 2.3 BindBody - Comportamento Atual

**Localização**: `Dext.Web.ModelBinding.pas` linhas 289-405

```pascal
function TModelBinder.BindBody(AType: PTypeInfo; Context: IHttpContext): TValue;
begin
  // ...
  // Lê stream do body
  Stream := Context.Request.Body;
  // ...
  // Deserializa JSON diretamente
  JsonString := TEncoding.UTF8.GetString(Bytes);
  Settings := TDextSettings.Default.WithCaseInsensitive;
  Result := TDextJson.Deserialize(AType, JsonString, Settings);  // ❌ Ignora atributos!
end;
```

O `TDextJson.Deserialize` é um deserializador JSON puro que:
- Mapeia campos JSON para campos do record
- **NÃO conhece** atributos de binding como `[FromHeader]`
- Campos não presentes no JSON ficam com valor default (empty string)

### 2.4 BindHeader - Existe mas NÃO é Usado para Records Mistos

**Localização**: `Dext.Web.ModelBinding.pas` linhas 755-807

O método `BindHeader` existe e funciona corretamente para records que são **100% headers**:

```pascal
function TModelBinder.BindHeader(AType: PTypeInfo; Context: IHttpContext): TValue;
begin
  // ...
  for Field in RttiType.GetFields do
  begin
    var SourceProvider := TBindingSourceProvider.Create;
    try
      FieldName := SourceProvider.GetBindingName(Field);  // Lê [FromHeader('...')]
    finally
      SourceProvider.Free;
    end;

    var HeaderKey := FieldName.ToLower;
    if Headers.ContainsKey(HeaderKey) then
    begin
      FieldValue := Headers[HeaderKey];
      Field.SetValue(Result.GetReferenceToRawData, Val);
    end;
  end;
end;
```

**MAS**: Este método é chamado por `BindParameter` (Controllers) mas **NUNCA** por `ResolveArgument<T>` (Minimal API).

---

## 3. Falhas Identificadas

### 3.1 Falha Principal: Records Mistos não Suportados em Minimal API

**Exemplo do Multi-Tenancy:**

```pascal
TProductCreateRequest = record
  [FromHeader('X-Tenant-Id')]      // ← Deve vir do Header
  TenantId: string;
  
  // Estes devem vir do Body JSON
  Name: string;
  Description: string;
  Price: Currency;
  Stock: Integer;
end;
```

**Comportamento Atual:**
1. `MapPost<IService, TProductCreateRequest, IResult>` registra o endpoint
2. Request chega com:
   - Header: `X-Tenant-Id: uuid-do-tenant`
   - Body: `{"name": "Widget", "description": "...", "price": 99.99, "stock": 50}`
3. `Invoke<T1, T2, TResult>` é chamado
4. `ResolveArgument<TProductCreateRequest>` é chamado
5. Como é POST + Record → chama `BindBody`
6. `BindBody` deserializa apenas o JSON
7. `TenantId` fica vazio porque não está no JSON
8. Endpoint retorna `BadRequest("X-Tenant-Id header is required")`

### 3.2 Falha: TBindingSourceProvider.GetBindingSource Não Usado Corretamente

O `TBindingSourceProvider` existe e pode determinar a fonte de um campo:

```pascal
function TBindingSourceProvider.GetBindingSource(Field: TRttiField): TBindingSource;
begin
  for Attr in Field.GetAttributes do
  begin
    if Attr is BindingAttribute then
      Exit(BindingAttribute(Attr).Source);  // Retorna bsHeader, bsQuery, etc.
  end;
  // Default...
end;
```

**MAS**: Este método **NÃO É CHAMADO** durante o binding de records POST em Minimal API.

### 3.3 Falha: BindBody Não Faz Binding Híbrido

O `BindBody` atual faz apenas:
```
JSON Body → Record
```

Deveria fazer:
```
JSON Body + Headers + Query + Route → Record (respeitando atributos)
```

### 3.4 Inconsistência: Controllers vs Minimal API

| Feature | Controllers | Minimal API |
|---------|-------------|-------------|
| `[FromHeader]` em parâmetro | ✅ Funciona | ❌ Não há parâmetros RTTI |
| `[FromHeader]` em campo de Record | ❓ Não testado | ❌ Não funciona |
| `[FromQuery]` em parâmetro | ✅ Funciona | ❌ Não há parâmetros RTTI |
| `[FromQuery]` em campo de Record | ✅ Funciona (BindQuery) | ⚠️ Só GET/DELETE |
| `[FromBody]` implícito | ✅ Funciona | ✅ POST/PUT/PATCH |
| `[FromRoute]` em parâmetro | ✅ Funciona | ❌ Não há parâmetros RTTI |
| `[FromRoute]` em campo de Record | ✅ Funciona (BindRoute) | ⚠️ Limitado |
| Records mistos (Body + Header) | ❓ Não testado | ❌ Não funciona |

---

## 4. Comportamento Esperado

### 4.1 Binding de Records com Atributos Mistos

Para um record como:

```pascal
TProductCreateRequest = record
  [FromHeader('X-Tenant-Id')]
  TenantId: string;
  
  Name: string;  // Implícito: FromBody
  Description: string;
  Price: Currency;
  Stock: Integer;
end;
```

O binding deve:

1. **Analisar RTTI do record** para identificar atributos em cada campo
2. **Para cada campo:**
   - `[FromHeader]` → Ler do `Context.Request.Headers`
   - `[FromQuery]` → Ler do `Context.Request.Query`
   - `[FromRoute]` → Ler do `Context.Request.RouteParams`
   - `[FromServices]` → Resolver do `Context.GetServices`
   - Sem atributo ou `[FromBody]` → Ler do JSON body
3. **Combinar** todos os valores no record final

### 4.2 Prioridade de Binding

Quando não há atributo explícito, usar convenção por método HTTP:

| HTTP Method | Default Source |
|-------------|----------------|
| GET | FromQuery |
| DELETE | FromQuery |
| POST | FromBody |
| PUT | FromBody |
| PATCH | FromBody |

### 4.3 Fluxo Esperado para Minimal API

```
MapPost<Service, Request, Result>(path, handler)
    └── Invoke<Service, Request, Result>(handler)
            ├── ResolveArgument<Service>() → DI
            └── ResolveArgument<Request>() 
                    └── BindRecordHybrid<Request>() [NOVO]
                            ├── Para cada campo do Record:
                            │   ├── [FromHeader] → BindFromHeader
                            │   ├── [FromQuery] → BindFromQuery
                            │   ├── [FromRoute] → BindFromRoute
                            │   ├── [FromServices] → BindFromServices
                            │   └── default → BindFromBody (JSON)
                            └── Retorna Record completo
```

---

## 5. Proposta de Correção

### 5.1 Novo Método: `BindRecordHybrid`

Criar um novo método em `TModelBinder` que faça binding híbrido:

```pascal
function TModelBinder.BindRecordHybrid(AType: PTypeInfo; Context: IHttpContext): TValue;
var
  ContextRtti: TRttiContext;
  RttiType: TRttiType;
  Field: TRttiField;
  SourceProvider: TBindingSourceProvider;
  BindingSource: TBindingSource;
  FieldName: string;
  FieldValue: TValue;
  BodyJson: TJsonObject;
  BodyParsed: Boolean;
begin
  if AType.Kind <> tkRecord then
    raise EBindingException.Create('BindRecordHybrid only supports records');

  TValue.Make(nil, AType, Result);
  BodyParsed := False;
  BodyJson := nil;

  ContextRtti := TRttiContext.Create;
  try
    RttiType := ContextRtti.GetType(AType);
    SourceProvider := TBindingSourceProvider.Create;
    try
      for Field in RttiType.GetFields do
      begin
        // 1. Determinar fonte de binding
        BindingSource := SourceProvider.GetBindingSource(Field);
        FieldName := SourceProvider.GetBindingName(Field);

        // 2. Fazer binding conforme a fonte
        case BindingSource of
          bsHeader:
            FieldValue := BindFieldFromHeader(Field, FieldName, Context);
          
          bsQuery:
            FieldValue := BindFieldFromQuery(Field, FieldName, Context);
          
          bsRoute:
            FieldValue := BindFieldFromRoute(Field, FieldName, Context);
          
          bsServices:
            FieldValue := BindFieldFromServices(Field, Context);
          
          bsBody:
            begin
              // Parse body JSON once (lazy)
              if not BodyParsed then
              begin
                BodyJson := ParseBodyAsJson(Context);
                BodyParsed := True;
              end;
              FieldValue := BindFieldFromBodyJson(Field, FieldName, BodyJson);
            end;
        end;

        // 3. Setar valor no field
        if not FieldValue.IsEmpty then
          Field.SetValue(Result.GetReferenceToRawData, FieldValue);
      end;
    finally
      SourceProvider.Free;
      if Assigned(BodyJson) then
        BodyJson.Free;
    end;
  finally
    ContextRtti.Free;
  end;
end;
```

### 5.2 Atualizar `ResolveArgument<T>`

Modificar para usar o novo método:

```pascal
function THandlerInvoker.ResolveArgument<T>: T;
begin
  // ... código existente para IHttpContext, TGUID, etc ...
  
  // Para Records - usar binding híbrido
  else if PTypeInfo(TypeInfo(T)).Kind = tkRecord then
  begin
    // ✅ NOVO: Binding híbrido que respeita atributos
    var BoundValue := FModelBinder.BindRecordHybrid(TypeInfo(T), FContext);
    Result := BoundValue.AsType<T>;
  end
  
  // ... resto do código ...
end;
```

### 5.3 Ajustar `TBindingSourceProvider.GetBindingSource` para Records

Atualizar o default quando não há atributo:

```pascal
function TBindingSourceProvider.GetBindingSource(Field: TRttiField): TBindingSource;
begin
  for Attr in Field.GetAttributes do
  begin
    if Attr is BindingAttribute then
      Exit(BindingAttribute(Attr).Source);
  end;

  // ✅ Default: Body para campos sem atributo em Records usados em POST
  // (Alternativamente, poderia receber o HTTP Method como parâmetro)
  Result := bsBody;
end;
```

---

## 6. Plano de Implementação

### Fase 1: Implementação Core

1. **Criar métodos auxiliares** em `TModelBinder`:
   - `BindFieldFromHeader(Field, FieldName, Context): TValue`
   - `BindFieldFromQuery(Field, FieldName, Context): TValue`
   - `BindFieldFromRoute(Field, FieldName, Context): TValue`
   - `BindFieldFromServices(Field, Context): TValue`
   - `BindFieldFromBodyJson(Field, FieldName, BodyJson): TValue`

2. **Implementar `BindRecordHybrid`**

3. **Atualizar `ResolveArgument<T>`** para usar `BindRecordHybrid` para records

### Fase 2: Testes

1. **Adicionar testes unitários** para binding híbrido:
   - Record com apenas `[FromHeader]`
   - Record com apenas `[FromQuery]`
   - Record com apenas `[FromBody]` (implícito)
   - Record misto: `[FromHeader]` + Body implícito
   - Record misto: `[FromHeader]` + `[FromQuery]` + Body

2. **Testar o exemplo Multi-Tenancy**

### Fase 3: Documentação

1. Atualizar `Docs/model-binding.md`
2. Atualizar `Docs/minimal-api.md`
3. Adicionar exemplos no `Docs/Book/02-web-framework/model-binding.md`

### Fase 4: Cleanup

1. Remover logs de debug (`WriteLn`) do código de produção
2. Considerar otimizações (cache de RTTI, etc.)

---

## 7. Casos de Teste

### 7.1 Caso: Multi-Tenancy (Problema Original)

```pascal
// Record
TProductCreateRequest = record
  [FromHeader('X-Tenant-Id')]
  TenantId: string;
  
  Name: string;
  Description: string;
  Price: Currency;
  Stock: Integer;
end;

// Endpoint
App.MapPost<IProductService, TProductCreateRequest, IResult>('/api/products',
  function(Service: IProductService; Request: TProductCreateRequest): IResult
  begin
    // Request.TenantId DEVE estar preenchido com o valor do header
    Assert(Request.TenantId <> '');
  end);

// Request
POST /api/products
X-Tenant-Id: abc-123
Content-Type: application/json

{"name": "Widget", "description": "...", "price": 99.99, "stock": 50}
```

**Resultado Esperado:**
```
Request.TenantId = 'abc-123'
Request.Name = 'Widget'
Request.Description = '...'
Request.Price = 99.99
Request.Stock = 50
```

### 7.2 Caso: Apenas Headers

```pascal
TTenantRequest = record
  [FromHeader('X-Tenant-Id')]
  TenantId: string;
end;

// GET com header
GET /api/products
X-Tenant-Id: abc-123
```

**Resultado Esperado:** `Request.TenantId = 'abc-123'`

### 7.3 Caso: Header + Query

```pascal
TSearchRequest = record
  [FromHeader('Authorization')]
  Token: string;
  
  [FromQuery]
  Search: string;
  
  [FromQuery]
  Page: Integer;
end;

// GET com header e query
GET /api/products?search=widget&page=2
Authorization: Bearer xyz
```

**Resultado Esperado:**
```
Request.Token = 'Bearer xyz'
Request.Search = 'widget'
Request.Page = 2
```

### 7.4 Caso: Header + Route + Body

```pascal
TUpdateRequest = record
  [FromHeader('X-User-Id')]
  UserId: string;
  
  [FromRoute]
  Id: Integer;
  
  Name: string;  // FromBody implícito
end;

// PUT
PUT /api/items/42
X-User-Id: user-123
Content-Type: application/json

{"name": "Updated Name"}
```

**Resultado Esperado:**
```
Request.UserId = 'user-123'
Request.Id = 42
Request.Name = 'Updated Name'
```

---

## Apêndice A: Arquivos a Modificar

| Arquivo | Modificações |
|---------|-------------|
| `Sources/Web/Mvc/Dext.Web.ModelBinding.pas` | Adicionar `BindRecordHybrid` e métodos auxiliares |
| `Sources/Web/Mvc/Dext.Web.HandlerInvoker.pas` | Modificar `ResolveArgument<T>` |
| `Tests/ServerCors/Dext.ModelBinding.Tests.pas` | Adicionar testes para binding híbrido |
| `Examples/Dext.Examples.MultiTenancy/Features/MultiTenancy.Endpoints.pas` | Pode remover workarounds após fix |

## Apêndice B: Considerações de Performance

1. **Parse do Body uma única vez**: O JSON body deve ser parseado apenas uma vez, mesmo que múltiplos campos venham dele.

2. **Cache de Atributos**: Considerar cachear a análise RTTI dos records para evitar reflection repetitiva.

3. **Lazy Loading do Body**: Só parsear o body se houver pelo menos um campo que precise dele.

---

**Autor**: Claude (Assistente de IA)  
**Data**: 2026-01-15  
**Versão**: 1.0
