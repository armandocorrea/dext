# Multi-Tenancy Implementation in Dext Framework

This document describes the architecture and implementation details of the Multi-Tenancy support in the Dext Framework.

## 1. Overview

Dext implements a **"Tenant by Identification Field"** strategy (also known as Shared Database, Shared Schema). Every tenant-aware table contains a `TenantId` column that identifies which tenant owns the record.

The framework provides automatic:
- **Tenant ID Population**: Automatic assignment of the current `TenantId` during `SaveChanges`.
- **Query Filtering**: Automatic injection of `WHERE TenantId = :CurrentTenantId` in all queries.
- **Context Isolation**: Ensuring cross-tenant data leaks are prevented at the ORM level.

---

## 2. Core Components (`Dext.MultiTenancy.pas`)

### ITenant
Represents a tenant in the system.
```pascal
ITenant = interface
  property Id: string read GetId;
  property Name: string read GetName;
  property ConnectionString: string read GetConnectionString;
  property Properties: TDictionary<string, string> read GetProperties;
end;
```

### ITenantProvider
A scoped service that holds the "Current Tenant" for the duration of a request or execution context.
```pascal
ITenantProvider = interface
  property Tenant: ITenant read GetTenant write SetTenant;
end;
```

---

## 3. Data Layer Implementation

### ITenantAware (`Dext.Entity.Tenancy.pas`)
An interface that marks an entity as tenant-aware.
```pascal
ITenantAware = interface
  property TenantId: string read GetTenantId write SetTenantId;
end;
```

### TTenantEntity
A base class for entities that implement `ITenantAware`. 
*Note: This class inherits from `TObject` and implements `IInterface` manually without reference counting to avoid conflicts with the ORM's internal object management.*

### Automatic Population (`Dext.Entity.Context.pas`)
In `TDbContext.SaveChanges`, the framework checks if an entity implements `ITenantAware`. If it does and a `TenantProvider` is present, it automatically sets the `TenantId`.

```pascal
if Supports(Entity, ITenantAware, TenantAware) then
begin
  if TenantAware.TenantId = '' then
    TenantAware.TenantId := FTenantProvider.Tenant.Id;
end;
```

### Automatic Filtering (`Dext.Entity.DbSet.pas`)
The `TDbSet<T>` class intercepts queries and applies a global filter if the entity type supports `ITenantAware`.

```pascal
procedure TDbSet<T>.ApplyTenantFilter(const ASpecification: ISpecification<T>);
begin
  if FIgnoreQueryFilters then Exit;
  if not Supports(T, ITenantAware) then Exit;
  
  // Injects: WHERE TenantId = CurrentTenantId
  ASpecification.And(TProp<string>.Create('TenantId') = FContext.TenantProvider.Tenant.Id);
end;
```

---

## 4. Web Integration (`Dext.Web.MultiTenancy.pas`)

### TMultiTenancyMiddleware
This middleware is responsible for:
1. Resolving the tenant (e.g., from Header, Subdomain, or JWT).
2. Retrieving the `ITenant` object from a store.
3. Injecting the `ITenant` into the `ITenantProvider` (scoped service).

The `ITenantProvider` is then automatically injected into the `TDbContext` during its creation by the DI container.

---

## 5. Usage Example

### Entity Definition
```pascal
[Table('Products')]
TProduct = class(TTenantEntity)
  [PK, Column('Id')]
  property Id: Integer read FId write FId;
  [Column('Name')]
  property Name: string read FName write FName;
end;
```

### Querying
Queries automatically filtered:
```pascal
// Only returns products for the current tenant
Products := Context.Products.List; 
```

Bypassing filters (e.g., for admin tasks):
```pascal
// Returns products for ALL tenants
AllProducts := Context.Products.IgnoreQueryFilters.List;
```

---

## 6. Implementation Notes

- **Reference Counting**: Entities should generally not be reference-counted when managed by an ORM that uses its own identity maps and life-cycle management. `TTenantEntity` effectively disables ref-counting.
- **Thread Safety**: `ITenantProvider` is registered as a **Scoped** service, meaning each web request has its own instance.
- **Performance**: The tenant filter is applied at the expression level, allowing the SQL generator to produce optimized `WHERE` clauses that use database indexes on `TenantId`.
