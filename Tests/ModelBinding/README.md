# Model Binding Tests

This directory contains comprehensive tests for the Dext Framework's Model Binding system, covering both **Minimal API** and **Controllers**.

## Test Coverage

### Minimal API Tests (10 scenarios)

| Test | Description | Sources |
|------|-------------|---------|
| 1 | Pure Body Binding | JSON body only |
| 2 | Header Only Binding | X-Tenant-Id, Authorization |
| 3 | Query Only Binding | ?q=...&page=...&limit=... |
| 4 | Route Only Binding | /products/{id}/{category} |
| 5 | Header + Body | Multi-Tenancy pattern |
| 6 | Route + Body | Update pattern |
| 7 | Route + Query | Filter pattern |
| 8 | Header + Route + Body | Complex mixed |
| 9 | All Sources Combined | Header + Route + Query + Body |
| 10 | Service Injection | DI + Model Binding |

### Controller Tests (5 scenarios)

| Test | Description | Sources |
|------|-------------|---------|
| 11 | Header Binding | X-Tenant-Id in controller |
| 12 | Query Binding | Query params in controller |
| 13 | Body Binding | JSON body in controller |
| 14 | Mixed (Header + Body) | Multi-Tenancy in controller |
| 15 | Route + Query | Route params + query in controller |

## Running the Tests

### 1. Build and Start the Test Server

```powershell
# From the repository root
dext build Tests\ModelBinding\ModelBindingTest.dproj

# Or open in Delphi IDE and run (F9)
```

Alternatively, open `Tests\ModelBinding\ModelBindingTest.dproj` in Delphi IDE and press F9.

### 2. Run the Test Script

In a new terminal (while server is running):

```powershell
cd Tests\ModelBinding
.\Test.ModelBinding.ps1
```

## Expected Output

```
============================================================
  Dext Model Binding - Comprehensive Test Suite
  Testing: Minimal API + Controllers
============================================================

Target: http://localhost:8080

========== MINIMAL API TESTS ==========

[1] Pure Body Binding (JSON)
    PASS: Body: All fields from JSON
    PASS: Body: camelCase to PascalCase mapping

[2] Header Only Binding
    PASS: Header: X-Tenant-Id and Authorization
    PASS: Header: Only X-Tenant-Id (no token)

[3] Query Parameter Binding
    PASS: Query: All parameters
    PASS: Query: Partial parameters (defaults)
    PASS: Query: URL encoded value

[4] Route Parameter Binding
    PASS: Route: Integer and String params
    PASS: Route: Large ID

[5] Mixed: Header + Body (Multi-Tenancy)
    PASS: Mixed: TenantId from header, data from body
    PASS: Mixed: Missing required header should fail

[6] Mixed: Route + Body
    PASS: Route+Body: Id from route, data from body

[7] Mixed: Route + Query
    PASS: Route+Query: Category from route, sort/page from query

[8] Complex: Header + Route + Body
    PASS: Multi-source: All three sources

[9] Full: Header + Route + Query + Body
    PASS: All sources: Header, Route, Query, Body

[10] Service Injection + Model Binding
    PASS: Service+Binding: Create with injected service

========== CONTROLLER TESTS ==========

[11] Controller: Header Binding
    PASS: Controller: X-Tenant-Id from header

[12] Controller: Query Binding
    PASS: Controller: Query parameters

[13] Controller: Body Binding
    PASS: Controller: JSON body

[14] Controller: Mixed (Header + Body)
    PASS: Controller: TenantId from header, data from body
    PASS: Controller: Missing header should fail

[15] Controller: Route + Query
    PASS: Controller: Id from route, details from query

============================================================
  TEST SUMMARY
============================================================

  Minimal API Tests: 16
  Controller Tests:  6

  Passed: 22
  Failed: 0
  Total:  22

All tests passed! 🚀
```

## Key Test Types

### Minimal API Records

```pascal
// Header Only
TTenantRequest = record
  [FromHeader('X-Tenant-Id')]
  TenantId: string;
  [FromHeader('Authorization')]
  Token: string;
end;

// Query Only
TSearchRequest = record
  [FromQuery('q')]
  Query: string;
  [FromQuery('page')]
  Page: Integer;
end;

// Mixed: Header + Body (Multi-Tenancy)
TProductCreateRequest = record
  [FromHeader('X-Tenant-Id')]
  TenantId: string;
  // Body fields (default)
  Name: string;
  Description: string;
  Price: Currency;
  Stock: Integer;
end;

// All Sources Combined
TFullRequest = record
  [FromHeader('X-Api-Key')]
  ApiKey: string;
  [FromRoute('id')]
  ResourceId: Integer;
  [FromQuery('include')]
  Include: string;
  // Body fields (default)
  Data: string;
  Count: Integer;
end;
```

### Controller Endpoints

```pascal
[DextController('/api/controller')]
TModelBindingController = class
public
  // Header binding
  [DextGet('/header')]
  procedure GetWithHeader(Ctx: IHttpContext; Request: TControllerHeaderRequest);
  
  // Query binding
  [DextGet('/query')]
  procedure GetWithQuery(Ctx: IHttpContext; Request: TControllerQueryRequest);
  
  // Body binding
  [DextPost('/body')]
  procedure PostWithBody(Ctx: IHttpContext; Request: TControllerBodyRequest);
  
  // Mixed binding (Header + Body)
  [DextPost('/mixed')]
  procedure PostWithMixed(Ctx: IHttpContext; Request: TControllerMixedRequest);
  
  // Route + Query parameters
  [DextGet('/route/{id}')]
  procedure GetWithRoute(Ctx: IHttpContext; [FromRoute] Id: Integer; [FromQuery] Details: string);
end;
```

## Related Documentation

- [Model Binding Guide](../../Docs/Book/02-web-framework/model-binding.md)
- [Minimal APIs](../../Docs/Book/02-web-framework/minimal-apis.md)
- [Controllers](../../Docs/Book/02-web-framework/controllers.md)
- [Multi-Tenancy Example](../../Examples/Dext.Examples.MultiTenancy/)
- [Controller Example](../../Examples/Web.ControllerExample/)
