# 🆔 UUID Support in Dext

Dext Framework provides **first-class support** for UUIDs (Universally Unique Identifiers), strictly adhering to **RFC 9562**. This ensures compatibility with modern databases (especially PostgreSQL) and Web APIs, resolving common endianness issues found in standard Delphi implementations.

## 🚀 Why TUUID?

Standard Delphi `TGUID` has a historical limitation:
*   **Delphi `TGUID`**: Little-Endian for the first 3 parts (`D1`, `D2`, `D3`).
*   **Network/Database (RFC)**: Big-Endian (Network Byte Order).

This mismatch often leads to "shuffled" GUIDs when reading/writing to PostgreSQL or external APIs. **Dext `TUUID`** solves this by using Big-Endian storage internally, while providing seamless conversion to `TGUID` for Delphi compatibility.

---

## 🛠️ Key Features

*   **RFC 9562 Compliant**: Correct Big-Endian storage.
*   **UUID v7 Support**: Time-ordered UUIDs, optimized for database primary keys (reduced fragmentation).
*   **Native ORM Support**: Maps directly to `uuid` columns in PostgreSQL/CockroachDB and `UNIQUEIDENTIFIER` in SQL Server.
*   **Web Model Binding**: Automatically bind UUIDs from URL parameters, Query Strings, and JSON Bodies.
*   **JSON Serialization**: Serializes as clean, canonical strings (lowercase, hyphenated).

---

## 💻 Usage

### 1. Basic Usage (Dext.Types.UUID)

`TUUID` is a value type (record) with implicit operators for `string` and `TGUID`.

```pascal
uses
  Dext.Types.UUID;

var
  Id: TUUID;
begin
  // Generate random UUID (v4)
  Id := TUUID.NewV4;
  
  // Generate time-ordered UUID (v7) - Recommended for DB Keys
  Id := TUUID.NewV7;
  
  // Implicit String Conversion
  WriteLn('UUID: ' + Id); // Standard format: a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11
  
  // Implicit TGUID Conversion
  var Guid: TGUID := Id;
end;
```

### 2. Web API (Model Binding)

You can use `TUUID` directly in your Controller Actions or Minimal API endpoints.

```pascal
// Function with TUUID parameter
App.MapGet('/products/:id',
  function(Context: IHttpContext): IResult
  begin
    // Automatically binds from URL segment
    var Id := Context.Request.BindRoute<TUUID>('id');
    
    // ... lookup product ...
  end);

// DTO with TUUID
type
  TCreateUserCmd = record
    Id: TUUID;
    Name: string;
  end;

App.MapPost('/users',
  function(Context: IHttpContext): IResult
  begin
    // Automatically deserializes from JSON body
    var Cmd := Context.Request.BodyAs<TCreateUserCmd>;
    
    // ... use Cmd.Id ...
  end);
```

### 3. ORM (Dext.Entity)

Use `TUUID` as your Primary Key type. The ORM handles the correct mapping for each database.

```pascal
type
  [Table('orders')]
  TOrder = class
  private
    FId: TUUID;
    // ...
  public
    [PK]
    property Id: TUUID read FId write FId;
  end;

// Usage
var Order := TOrder.Create;
Order.Id := TUUID.NewV7; // Client-side generation (good for distributed systems)
DbContext.Orders.Add(Order);
DbContext.SaveChanges;
```

#### Database Mapping
*   **PostgreSQL**: `uuid` (Native type)
*   **SQL Server**: `uniqueidentifier`
*   **SQLite/MySQL**: `char(36)`

### 4. JSON Serialization

`TUUID` serializes to a standard canonical string.

```json
{
  "id": "0193e4a9-7f30-746b-9c79-123456789abc",
  "name": "Example Item"
}
```

Standard `TGUID` serializes with braces in Delphi (`{...}`), but **Dext.Json enforces standard UUID format** for both `TUUID` and `TGUID` to ensuring web compatibility.

---

## ⚡ Performance Note: UUID v7

For high-volume databases, prefer **UUID v7** (`TUUID.NewV7`). It includes a timestamp component ensuring that new IDs are (mostly) increasing. This significantly reduces B-Tree index fragmentation compared to random v4 UUIDs, improving insert performance and cache locality.

