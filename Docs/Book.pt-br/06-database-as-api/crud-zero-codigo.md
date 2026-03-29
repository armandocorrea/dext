# CRUD Sem Código

Gere APIs REST automaticamente a partir das suas entidades - sem escrever código repetitivo.

> 📦 **Exemplo**: [Web.DatabaseAsApi](../../../Examples/Web.DatabaseAsApi/)

## Início Rápido

Exponha um CRUD completo para uma entidade com apenas uma linha:

```pascal
type
  [Table('products')]
  TProduct = class
  public
    [PK, AutoInc] property Id: Integer;
    property Name: string;
    property Price: Double;
  end;

// Configurar no pipeline
App.Configure(procedure(App: IApplicationBuilder)
  begin
    // Mapeia GET, POST, PUT, DELETE para /api/products
    TDataApiHandler<TProduct>.Map(App, '/api/products');
  end);
```

## Endpoints Gerados

| Método | URL | Descrição |
|--------|-----|-----------|
| GET | `/api/products` | Listar todos (suporta paginação/filtros) |
| GET | `/api/products/{id}` | Buscar por ID único |
| POST | `/api/products` | Criar novo registro |
| PUT | `/api/products/{id}` | Atualizar registro existente |
| DELETE | `/api/products/{id}` | Excluir registro |

## Recursos Avançados

### Paginação e Ordenação

Use parâmetros de query para controlar os dados retornados:
- `?page=1&pageSize=20`
- `?orderBy=Name&desc=true`

### Filtragem Automática

Filtre registros diretamente pela URL:
- `?Name=Teclado` (Filtro exato)
- `?Price_gt=100` (Preço maior que 100)
- `?Status_in=Ativo,Pendente` (Filtro IN)

### Segurança e Políticas

Você pode restringir quais operações estão disponíveis:

```pascal
TDataApiHandler<TProduct>.Map(App, '/api/products', 
  procedure(Options: TDataApiOptions)
  begin
    Options.AllowedOperations := [ToRead, ToCreate]; // Apenas leitura e criação
    Options.RequireAuthorization := True;           // Requer JWT
  end);
```

### Suporte a UUID e IDs Customizados

O **Dext Database as API** integra o `TEntityIdResolver` para detectar e processar automaticamente o tipo da sua chave primária (`[PK]`). Ele converte o `{id}` da URL para o tipo de dado real da entidade de forma transparente.

Isso permite usar tipos modernos como `TUUID` ou identificadores customizados sem configurações adicionais:

```pascal
type
  [Table('system_logs')]
  TSystemLog = class
  public
    [PK] property Id: TUUID;
    property Message: string;
  end;

// A rota /api/logs/{id} aceitará UUIDs formatados na URL (ex: /api/logs/550e8400-e29b...)
TDataApiHandler<TSystemLog>.Map(App, '/api/logs');
```

---

[← Database as API](README.md) | [Próximo: Tempo Real →](../07-tempo-real/README.md)
