# 🚀 Dext - Modern Web Framework for Delphi

[![Delphi](https://img.shields.io/badge/Delphi-11%20Alexandria-red.svg)](https://www.embarcadero.com/products/delphi)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

**Dext** é um framework web moderno e minimalista para Delphi, inspirado no ASP.NET Core, oferecendo uma experiência de desenvolvimento produtiva e type-safe para criação de APIs RESTful.

## ✨ Features

- 🎯 **Minimal API** - Sintaxe limpa e expressiva para definição de endpoints
- 🔗 **Smart Model Binding** - Binding automático de Body, Query, Route, Headers
- 💉 **Dependency Injection** - Container DI nativo e integrado
- 🛣️ **Route Parameters** - Suporte a tipos primitivos e records
- 📦 **JSON Serialization** - Serialização/deserialização automática
- 🔧 **Type-Safe** - Handlers tipados com inferência automática
- ⚡ **Performance** - Otimizado para alta performance
- 🧩 **Extensível** - Arquitetura modular e plugável

## 📦 Instalação

### Requisitos

- Delphi 11 Alexandria ou superior
- Windows (suporte a outras plataformas em desenvolvimento)

### Quick Start

1. Clone o repositório:
```bash
git clone https://github.com/seu-usuario/dext.git
```

2. Adicione os paths ao seu projeto:
```
..\Core
..\Core\Drivers
```

3. Crie seu primeiro servidor:

```pascal
program HelloDext;

uses
  Dext.WebHost,
  Dext.Http.Interfaces,
  Dext.Core.ApplicationBuilder.Extensions;

begin
  var Host := TDextWebHost.CreateDefaultBuilder
    .Configure(procedure(App: IApplicationBuilder)
    begin
      TApplicationBuilderExtensions.MapGet<IHttpContext>(
        App, '/hello',
        procedure(Ctx: IHttpContext)
        begin
          Ctx.Response.Json('{"message":"Hello, Dext!"}');
        end
      );
    end)
    .Build;

  WriteLn('Server running on http://localhost:8080');
  Host.Run;
end.
```

## 🎯 Exemplos Rápidos

### GET com Route Parameter

```pascal
// GET /api/users/123
MapGet<Integer, IHttpContext>(App, '/api/users/{id}',
  procedure(UserId: Integer; Ctx: IHttpContext)
  begin
    Ctx.Response.Json(Format('{"userId":%d}', [UserId]));
  end
);
```

### POST com Body Binding

```pascal
type
  TCreateUserRequest = record
    Name: string;
    Email: string;
  end;

// POST /api/users
MapPost<TCreateUserRequest, IHttpContext>(App, '/api/users',
  procedure(Request: TCreateUserRequest; Ctx: IHttpContext)
  begin
    Ctx.Response.StatusCode := 201;
    Ctx.Response.Json(Format('{"name":"%s","email":"%s"}', 
      [Request.Name, Request.Email]));
  end
);
```

### Dependency Injection

```pascal
// Registrar serviço
.ConfigureServices(procedure(Services: IServiceCollection)
begin
  TServiceCollectionExtensions.AddSingleton<IUserService, TUserService>(Services);
end)

// Injetar em handler
MapGet<Integer, IUserService, IHttpContext>(
  App, '/api/users/{id}',
  procedure(UserId: Integer; UserService: IUserService; Ctx: IHttpContext)
  begin
    var UserName := UserService.GetUserName(UserId);
    Ctx.Response.Json(Format('{"name":"%s"}', [UserName]));
  end
);
```

### CRUD Completo

```pascal
// GET
MapGet<Integer, IHttpContext>(App, '/api/users/{id}', GetUser);

// POST
MapPost<TCreateUserRequest, IHttpContext>(App, '/api/users', CreateUser);

// PUT
MapPut<Integer, TUpdateUserRequest, IHttpContext>(App, '/api/users/{id}', UpdateUser);

// DELETE
MapDelete<Integer, IHttpContext>(App, '/api/users/{id}', DeleteUser);
```

## 📚 Documentação

- [📖 Minimal API Guide](Docs/MinimalAPI.md) - Guia completo da Minimal API
- [🔗 Model Binding](Docs/ModelBinding.md) - Detalhes sobre binding de parâmetros
- [💉 Dependency Injection](Docs/DependencyInjection.md) - Sistema de DI
- [📦 JSON Serialization](Docs/JSON.md) - Serialização JSON
- [🛣️ Routing](Docs/Routing.md) - Sistema de rotas

## 🏗️ Arquitetura

```
Dext Framework
│
├── Core
│   ├── ApplicationBuilder      # Configuração da aplicação
│   ├── HandlerInvoker          # Invocação de handlers
│   ├── ModelBinding            # Binding de parâmetros
│   └── Routing                 # Sistema de rotas
│
├── DI
│   ├── ServiceCollection       # Registro de serviços
│   └── ServiceProvider         # Resolução de dependências
│
├── Http
│   ├── Interfaces              # Abstrações HTTP
│   ├── Core                    # Implementação core
│   ├── Indy                    # Servidor Indy
│   └── Middleware              # Pipeline de middleware
│
└── Json
    ├── Serialization           # Serialização JSON
    └── Drivers                 # Drivers JSON (JsonDataObjects)
```

## 🔧 Componentes Principais

### TApplicationBuilder

Constrói o pipeline de processamento de requisições:

```pascal
var App := TDextWebHost.CreateDefaultBuilder
  .ConfigureServices(...)  // Registrar serviços
  .Configure(...)          // Configurar rotas e middleware
  .Build;                  // Construir aplicação
```

### THandlerInvoker

Invoca handlers com binding automático de parâmetros:

```pascal
Invoker.Invoke<T1, T2, T3>(Handler);
```

### TModelBinder

Realiza binding de parâmetros de múltiplas fontes:

```pascal
Binder.BindBody(TypeInfo(TUser), Context);
Binder.BindRoute(TypeInfo(Integer), Context);
Binder.BindQuery(TypeInfo(TFilter), Context);
```

## 🧪 Testes

Execute os testes de exemplo:

```bash
cd Sources\Tests
dcc32 -B Dext.MinimalAPITest.dpr
Dext.MinimalAPITest.exe
```

Teste com curl:

```bash
# GET
curl http://localhost:8080/api/users/123

# POST
curl -X POST http://localhost:8080/api/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John","email":"john@example.com"}'

# PUT
curl -X PUT http://localhost:8080/api/users/123 \
  -H "Content-Type: application/json" \
  -d '{"name":"Jane","email":"jane@example.com"}'

# DELETE
curl -X DELETE http://localhost:8080/api/users/123
```

## 🗺️ Roadmap

### v1.0 (Atual)
- [x] Minimal API básica
- [x] Model Binding (Body, Query, Route, Header, Services)
- [x] Route Parameters com primitivos
- [x] Dependency Injection
- [x] JSON Serialization
- [x] MapGet, MapPost, MapPut, MapDelete

### v1.1 (Próximo)
- [ ] Smart Binding (múltiplas fontes em um record)
- [ ] Middleware customizados
- [ ] Validação de modelos
- [ ] CORS configurável
- [ ] Rate limiting

### v2.0 (Futuro)
- [ ] WebSockets
- [ ] SignalR
- [ ] GraphQL
- [ ] OpenAPI/Swagger
- [ ] Autenticação JWT
- [ ] Entity Framework

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor:

1. Fork o projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Changelog

### [1.0.0] - 2025-11-19

#### Added
- Minimal API com extensões genéricas
- Model Binding de múltiplas fontes
- Route Parameters com tipos primitivos
- MapPut e MapDelete
- Dependency Injection integrado
- JSON Serialization automática
- Documentação completa

#### Fixed
- Correção de binding de route parameters
- Tratamento de erros de conversão de tipos

## 📄 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🙏 Agradecimentos

- Inspirado no ASP.NET Core Minimal APIs
- Comunidade Delphi
- Contribuidores do projeto

## 📧 Contato

- **Autor**: [Seu Nome]
- **Email**: [seu@email.com]
- **GitHub**: [@seu-usuario](https://github.com/seu-usuario)

---

**Desenvolvido com ❤️ usando Delphi**

⭐ Se este projeto foi útil, considere dar uma estrela!
