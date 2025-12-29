# Smart Properties - Type-Safe Query Expressions

Smart Properties is a powerful feature in Dext ORM that enables **type-safe query building without magic strings**. Instead of writing SQL fragments or using string-based column names, you write natural Delphi expressions that are automatically converted to SQL.

## Overview

Traditional ORMs often require you to use string literals for column names in queries:

```pascal
// Traditional approach - error prone, no IntelliSense
Users.Where('Age > 18 AND Name LIKE ''%John%''');
```

With Smart Properties, you write:

```pascal
// Smart Properties - type-safe, IntelliSense, refactorable
var u := Prototype.Entity<TUser>;
Users.Where(u.Age > 18).Where(u.Name.Contains('John'));
```

## Core Concepts

### 1. Smart Types (`Prop<T>`)

To enable smart query expressions, entity properties must be wrapped in `Prop<T>`. This generic record holds both the value and metadata needed for SQL generation.

You can use `Prop<T>` explicitly:

```pascal
type
  [Table('Users')]
  TUser = class
  private
    FId: Prop<Integer>;
    FName: Prop<string>;
    FAge: Prop<Integer>;
    FActive: Prop<Boolean>;
  public
    [PK, AutoInc]
    property Id: Prop<Integer> read FId write FId;
    property Name: Prop<string> read FName write FName;
    property Age: Prop<Integer> read FAge write FAge;
    property Active: Prop<Boolean> read FActive write FActive;
  end;
```

However, to keep your code clean and concise, Dext provides standard aliases (Recommended):

```pascal
type
  [Table('Users')]
  TUser = class
  private
    FId: IntType;      // Alias for Prop<Integer>
    FName: StringType; // Alias for Prop<string>
    FAge: IntType;     // Alias for Prop<Integer>
    FActive: BoolType; // Alias for Prop<Boolean>
  public
    [PK, AutoInc]
    property Id: IntType read FId write FId;
    property Name: StringType read FName write FName;
    property Age: IntType read FAge write FAge;
    property Active: BoolType read FActive write FActive;
  end;
```

### 2. Type Aliases

For cleaner code, Dext provides type aliases:

| Alias | Underlying Type |
|-------|-----------------|
| `IntType` | `Prop<Integer>` |
| `Int64Type` | `Prop<Int64>` |
| `StringType` | `Prop<string>` |
| `BoolType` | `Prop<Boolean>` |
| `FloatType` | `Prop<Double>` |
| `CurrencyType` | `Prop<Currency>` |
| `DateTimeType` | `Prop<TDateTime>` |
| `DateType` | `Prop<TDate>` |
| `TimeType` | `Prop<TTime>` |

### 3. Prototype Entities

A "prototype" is a special cached instance of your entity used for building queries. Instead of holding actual data, each `Prop<T>` field contains metadata (column name) that generates SQL expressions when operators are used.

**Key points:**
- Prototypes are **cached per type** for performance
- Created once, reused forever (no lifecycle concerns)
- Thread-safe (each thread gets its own instance)

### 4. BooleanExpression

`BooleanExpression` (alias: `BoolExpr`) is a hybrid record that can hold either:
- A **runtime Boolean value** (for in-memory filtering)
- An **IExpression** (for SQL generation)

This enables the same code to work for both query building and runtime evaluation.

## Query Syntax Options

Dext offers multiple ways to build queries. Choose the style that fits your use case.

---

### Option 1: Direct Prototype (Recommended)

The simplest and most performant approach. Prototypes are cached.

```pascal
var u := Prototype.Entity<TUser>;

// Simple query
var adults := Users.Where(u.Age >= 18).ToList;

// Multiple conditions (AND)
var activeAdults := Users
  .Where(u.Age >= 18)
  .Where(u.Active = True)
  .ToList;

// Complex expression
var result := Users.Where((u.Age >= 18) and u.Active).ToList;
```

**When to use:** Most scenarios. Best for performance.

---

### Option 2: Anonymous Methods with BooleanExpression

For complex expressions that benefit from a code block.

```pascal
// Using full type name
var result := Users.Where(
  function(u: TUser): BooleanExpression
  begin
    Result := (u.Age >= 18) and u.Name.StartsWith('J');
  end
).ToList;

// Using short alias BoolExpr
var result := Users.Where(
  function(u: TUser): BoolExpr
  begin
    if SomeCondition then
      Result := u.Age >= 21
    else
      Result := u.Age >= 18;
  end
).ToList;
```

**When to use:** 
- Complex conditional logic
- Multi-line expressions
- When you need local variables or calculations

---

### Option 3: Specification Methods

Using prototype from within Specifications (supports Joins).

```pascal
type
  TActiveAdultsSpec = class(TSpecification<TUser>)
  public
    constructor Create;
  end;

constructor TActiveAdultsSpec.Create;
var
  u: TUser;
begin
  inherited Create;
  u := Prototype;  // Uses cached prototype
  Where(TFluentExpression((u.Age >= 18) and (u.Active = True)));
end;

// For Joins - create prototypes for multiple types
constructor TUserWithOrdersSpec.Create;
var
  u: TUser;
  o: TOrder;
begin
  inherited Create;
  u := Prototype;                  // Main entity
  o := Prototype<TOrder>;          // Related entity for Join
  // Build join conditions...
end;
```

---

### Option 4: DbSet Prototype Methods

Similar to Specification, but from DbSet directly.

```pascal
var
  u: TUser;
  o: TOrder;
begin
  u := Users.Prototype;            // Main entity
  o := Users.Prototype<TOrder>;    // For Joins
  
  var result := Users
    .Where(u.Age >= 18)
    .ToList;
end;
```

---

### Option 5: Direct BooleanExpression Variable

Store expressions in variables for reuse or composition.

```pascal
var u := Prototype.Entity<TUser>;

// Store conditions
var ageCondition: BoolExpr := u.Age >= 18;
var activeCondition: BoolExpr := u.Active = True;
var combined: BoolExpr := ageCondition and activeCondition;

// Use the combined expression
var result := Users.Where(combined).ToList;

// Dynamic composition
if FilterByAge then
  combined := combined and (u.Age < 65);
  
var seniors := Users.Where(combined).ToList;
```

---

## Expression Operations

### Comparison Operators

```pascal
var u := Prototype.Entity<TUser>;

// Equality
var result := Users.Where(u.Age = 18).ToList;
var result := Users.Where(u.Name = 'John').ToList;

// Inequality
var result := Users.Where(u.Age <> 18).ToList;

// Greater/Less than
var result := Users.Where(u.Age > 18).ToList;
var result := Users.Where(u.Age >= 18).ToList;
var result := Users.Where(u.Age < 65).ToList;
var result := Users.Where(u.Age <= 65).ToList;
```

### String Operations

```pascal
var u := Prototype.Entity<TUser>;

// LIKE 'John%'
var result := Users.Where(u.Name.StartsWith('John')).ToList;

// LIKE '%son'
var result := Users.Where(u.Name.EndsWith('son')).ToList;

// LIKE '%mit%'
var result := Users.Where(u.Name.Contains('mit')).ToList;

// Custom LIKE pattern
var result := Users.Where(u.Name.Like('J_hn%')).ToList;
```

### Null Handling

```pascal
var u := Prototype.Entity<TUser>;

// IS NULL
var noEmail := Users.Where(u.Email.IsNull).ToList;

// IS NOT NULL
var hasEmail := Users.Where(u.Email.IsNotNull).ToList;
```

### Range and Collection Operations

```pascal
var u := Prototype.Entity<TUser>;

// BETWEEN
var result := Users.Where(u.Age.Between(30, 50)).ToList;

// IN (list)
var result := Users.Where(u.Age.In([25, 30, 35])).ToList;

// NOT IN
var result := Users.Where(u.Age.NotIn([18, 21])).ToList;
```

### Logical Operators

```pascal
var u := Prototype.Entity<TUser>;

// AND (using multiple Where calls - implicit AND)
var result := Users
  .Where(u.Age >= 18)
  .Where(u.Active = True)
  .ToList;

// AND (explicit)
var result := Users.Where((u.Age >= 18) and (u.Active = True)).ToList;

// OR
var result := Users.Where((u.Age < 18) or (u.Age > 65)).ToList;

// NOT
var result := Users.Where(not (u.Age = 25)).ToList;

// Complex combinations
var result := Users.Where(
  ((u.Age >= 18) and (u.Age <= 65)) or u.Active
).ToList;
```

## How It Works

### Expression Tree Generation

When you write `u.Age > 18`:

1. `u.Age` is a `Prop<Integer>` with injected metadata (column name = "Age")
2. The `>` operator is overloaded in `Prop<T>`
3. Instead of comparing values, it creates a `TBinaryExpression` node
4. The expression tree is stored in a `BooleanExpression` record
5. The SQL generator walks the tree and produces: `"Age" > 18`

### Prototype Caching

```pascal
// First call: creates and caches the prototype
var u1 := Prototype.Entity<TUser>;

// Second call: returns cached instance (no RTTI overhead)
var u2 := Prototype.Entity<TUser>;

// u1 and u2 are the SAME instance!
```

### BooleanExpression Internals

```pascal
BooleanExpression = record
private
  FRuntimeValue: Boolean;    // For in-memory evaluation
  FExpression: IExpression;  // For SQL generation
public
  // Factory methods
  class function FromQuery(const AExpr: IExpression): BooleanExpression;
  class function FromRuntime(const AValue: Boolean): BooleanExpression;
  
  // Logical operators
  class operator LogicalAnd(const Left, Right: BooleanExpression): BooleanExpression;
  class operator LogicalOr(const Left, Right: BooleanExpression): BooleanExpression;
  class operator LogicalNot(const Value: BooleanExpression): BooleanExpression;
end;

// Short alias
BoolExpr = BooleanExpression;
```

## Advantages

### ✅ Type Safety
Compile-time verification of property names. Typos are caught immediately.

### ✅ IntelliSense Support
Full IDE autocomplete for entity properties.

### ✅ Refactoring Friendly
Rename a property and all queries update automatically.

### ✅ SQL Injection Prevention
Values are always parameterized, never concatenated into SQL.

### ✅ Database Agnostic
The same query code works across SQLite, PostgreSQL, SQL Server, etc.

### ✅ Readable Code
Queries read like natural expressions.

### ✅ High Performance
Prototypes are cached - no repeated RTTI overhead.

### ✅ .NET Alignment
`BooleanExpression` aligns with .NET's `Expression<Func<T, bool>>` concept.

## Limitations

### 1. Entity Design
Entities must use `Prop<T>` types instead of plain types:

```pascal
// Won't work with Smart Properties
property Age: Integer read FAge write FAge;

// Works with Smart Properties
property Age: IntType read FAge write FAge;
```

### 2. No Lambda Shorthand
Delphi doesn't support `x => x.Age > 18` syntax. The closest we can get is:
```pascal
// Delphi requires explicit function declaration
function(u: TUser): BoolExpr begin Result := u.Age > 18; end
```

### 3. Complex Expressions
Some complex SQL operations may still require raw SQL or Specifications.

## Serialization & Deserialization
 
Dext's JSON serializer (`TDextJson`) handles `Prop<T>` transparently in both directions:
 
### Serialization (Entity -> JSON)
It automatically detects `Prop<T>` properties and serializes them as their underlying primitive values:
 
```json
// Auto-unwrapped JSON
{
  "id": 1,
  "name": "John Doe",
  "age": 30
}
```
 
### Deserialization (JSON -> Entity)
It correctly hydrates `Prop<T>` types from simple primitive JSON values. This is essential for Model Binding in Web APIs:
 
```pascal
// Example: POST /products receiving JSON
App.MapPost<TProduct, IResult>('/products', 
  function(P: TProduct): IResult
  begin
    // 'P.Name' and 'P.Price' (smart properties) are automatically populated from the JSON body
    Db.Products.Add(P);
    // ...
  end);
```
 
> **Note:** If you use third-party serializers (like `REST.Json` or `System.JSON`) directly, `Prop<T>` records might be serialized as complex objects (e.g., `{"Age": {"FValue": 30}}`). For REST APIs, we recommend using Dext's built-in serializer which handles this transparently.

## Best Practices

### 1. Use Direct Prototype for Simple Queries
```pascal
var u := Prototype.Entity<TUser>;
var result := Users.Where(u.Age > 18).ToList;
```

### 2. Use Anonymous Methods for Complex Logic
```pascal
var result := Users.Where(
  function(u: TUser): BoolExpr
  begin
    if CurrentUserIsAdmin then
      Result := True  // No filter
    else
      Result := u.DepartmentId = CurrentUserDeptId;
  end
).ToList;
```

### 3. Use Specifications for Reusable Business Rules
```pascal
type
  TPremiumCustomerSpec = class(TSpecification<TCustomer>)
  public
    constructor Create;
  end;

// Reusable across the application
var premium := Customers.Query(TPremiumCustomerSpec.Create).ToList;
```

### 4. Choose Your Verbosity Level
```pascal
// Verbose but explicit
function(u: TUser): BooleanExpression

// Short and practical
function(u: TUser): BoolExpr
```

## Related Units

| Unit | Description |
|------|-------------|
| `Dext.Entity.SmartTypes` | Core `Prop<T>`, `BooleanExpression`, type aliases |
| `Dext.Entity.Prototype` | `Prototype.Entity<T>` factory with cache |
| `Dext.Specifications.Base` | Base specification class with Prototype methods |
| `Dext.Specifications.Types` | Expression tree types |
| `Dext.Specifications.SQL.Generator` | SQL generation from expression trees |

## Complete Example

```pascal
unit MyEntities;

interface

uses
  Dext.Entity.Attributes,
  Dext.Entity.SmartTypes;

type
  [Table('Products')]
  TProduct = class
  private
    FId: IntType;
    FName: StringType;
    FPrice: CurrencyType;
    FStock: IntType;
    FActive: BoolType;
    FCreatedAt: DateTimeType;
  public
    [PK, AutoInc]
    property Id: IntType read FId write FId;
    property Name: StringType read FName write FName;
    property Price: CurrencyType read FPrice write FPrice;
    property Stock: IntType read FStock write FStock;
    property Active: BoolType read FActive write FActive;
    property CreatedAt: DateTimeType read FCreatedAt write FCreatedAt;
  end;

implementation
end.
```

```pascal
uses
  Dext.Entity.Prototype,
  Dext.Entity.SmartTypes;

procedure QueryExamples;
var
  p: TProduct;
  List: IList<TProduct>;
begin
  // Option 1: Direct prototype (cached, fast)
  p := Prototype.Entity<TProduct>;
  
  List := Products
    .Where(p.Active = True)
    .Where(p.Stock < 10)
    .Where(p.Price > 100)
    .ToList;

  // Option 2: Anonymous method (for complex logic)
  List := Products.Where(
    function(prod: TProduct): BoolExpr
    begin
      Result := (prod.CreatedAt > EncodeDate(2024, 1, 1)) 
            and prod.Name.Contains('Premium');
    end
  ).ToList;

  // Option 3: Composition with variables
  var isActive: BoolExpr := p.Active = True;
  var lowStock: BoolExpr := p.Stock < 10;
  var urgent: BoolExpr := isActive and lowStock;
  
  List := Products.Where(urgent).ToList;
end;
```
