---
name: dext-database-as-api
description: Expose full REST CRUD endpoints automatically from Dext ORM entities with zero boilerplate using TDataApiHandler. Use when you need instant GET/POST/PUT/DELETE for an entity without writing controllers or services.
---

# Dext Database as API (Zero-Code CRUD)

Generate a complete REST API for an entity with a single line. No controller, no service, no repository needed.

## Core Import

```pascal
uses
  Dext.Web.DataApi; // TDataApiHandler<T>
```

> 📦 Example: `Web.DatabaseAsApi`

## Quick Start

```pascal
// Entity
type
  [Table('products')]
  TProduct = class
  public
    [PK, AutoInc] property Id: Integer;
    [Required, MaxLength(100)] property Name: string;
    property Price: Double;
    property Stock: Integer;
  end;

// In Startup Configure — maps all 5 CRUD endpoints using the fluent method
App.Builder
  .UseExceptionHandler
  .MapDataApi<TProduct>('/api/products') // Recommended fluent syntax
  .UseSwagger(...);
```

## Generated Endpoints

| HTTP | URL | Description |
|------|-----|-------------|
| `GET` | `/api/products` | List all (pagination + filters) |
| `GET` | `/api/products/{id}` | Find by ID |
| `POST` | `/api/products` | Create new record |
| `PUT` | `/api/products/{id}` | Update existing record |
| `DELETE` | `/api/products/{id}` | Delete record |

## Query Parameters (Auto-Supported)

### Pagination & Ordering

```
GET /api/products?page=1&pageSize=20
GET /api/products?orderBy=Name&desc=true
```

### Filtering

```
GET /api/products?Name=Keyboard       # Exact match
GET /api/products?Price_gt=100        # Greater than
GET /api/products?Price_lt=500        # Less than
GET /api/products?Stock_gte=1         # Greater or equal
GET /api/products?Status_in=Active,Pending  # IN filter
```

## Restricting Operations

```pascal
App.Builder.Map(TDataApiHandler<TProduct>, '/api/products',
  procedure(Options: TDataApiOptions)
  begin
    Options.AllowedOperations := [ToRead, ToCreate]; // Read + Create only
    Options.RequireAuthorization := True;             // Requires JWT
  end);
```

Available operations: `ToRead`, `ToCreate`, `ToUpdate`, `ToDelete`.

## Multiple Entities

```pascal
App.Builder
  .UseExceptionHandler
  .UseAuthentication
  .MapDataApi<TProduct>('/api/products')
  .MapDataApi<TCategory>('/api/categories')
  .MapDataApi<TOrder>('/api/orders',
    DataApiOptions<TOrder>.Default
      .Only([ToRead])
      .RequiresAuth)
  .UseSwagger(...);
```

## When to Use vs When to Write a Controller

| Use `TDataApiHandler` | Write a Controller/Service |
|-----------------------|---------------------------|
| Simple CRUD for internal/admin tools | Complex business logic on save/delete |
| Rapid prototyping | Validation beyond ORM attributes |
| Read-only data exposure | Custom response shapes |
| Admin dashboards | Multi-entity transactions |

## Examples

| Example | What it shows |
|---------|---------------|
| `Web.DatabaseAsApi` | Zero-code CRUD: `MapDataApi<T>`, `TUUID` PK support, snake_case JSON, Swagger auto-docs |

---

## ID Resolvers & UUID Support

**Dext Database as API** automatically detects your Primary Key (`[PK]`) type. It uses the `TEntityIdResolver` to transparently convert the `{id}` string from the URL into the entity's actual data type.

This enables native support for modern identifiers like `TUUID` (`Dext.Types.UUID`) without any extra configuration:

```pascal
type
  [Table('logs')]
  TLog = class
  public
    [PK] property Id: TUUID; // Automatically resolved from URL /api/logs/{id}
    property Message: string;
  end;

// Registration
App.Builder.MapDataApi<TLog>('/api/logs');
```
