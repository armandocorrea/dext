---
description: How to use the Fluent Query API in Dext
---

# Fluent Query API

The Fluent Query API in Dext provides a powerful and expressive way to query entities. It supports filtering, projection, aggregation, joining, and pagination using a method chaining syntax.

## Basic Usage

To start a query, use the `Query` method on an entity set:

```delphi
var
  Users: TFluentQuery<TUser>;
begin
  Users := Context.Entities<TUser>.Query;
  // ... use Users ...
  Users.Free;
end;
```

## Filtering (Where)

You can filter using a predicate (TFunc<T, Boolean>) or an ICriterion.

### Using Predicate
```delphi
Users.Where(function(U: TUser): Boolean
  begin
    Result := U.Age > 18;
  end);
```

### Using Specification (ICriterion)
```delphi
// Assuming UserEntity is a generated helper for TUser properties
Users.Where(UserEntity.Age > 18);
```

## Projections (Select)

You can project to a new type, a single property, or a partial entity.

### Select Single Property
Projects to a list of values of that property type.
```delphi
var
  Names: TFluentQuery<string>;
begin
  Names := Users.Select<string>('Name');
end;
```

### Select Multiple Properties (Partial Load)
Creates new instances of the entity with only specified properties populated.
```delphi
var
  PartialUsers: TFluentQuery<TUser>;
begin
  PartialUsers := Users.Select(['Name', 'City']);
end;
```

### Select with Custom Selector
Projects to any type using a custom function.
```delphi
Users.Select<TUserDTO>(function(U: TUser): TUserDTO
  begin
    Result := TUserDTO.Create(U.Name, U.Age);
  end);
```

## Aggregations

Supported aggregations: `Count`, `Sum`, `Average`, `Min`, `Max`, `Any`.

### Count
```delphi
var Total: Integer := Users.Count;
var Adults: Integer := Users.Count(function(U: TUser): Boolean begin Result := U.Age >= 18; end);
```

### Sum, Average, Min, Max
These can be called with a property name string or a selector function.

```delphi
// Using Property Name
var TotalAge: Double := Users.Sum('Age');
var MaxAge: Double := Users.Max('Age');

// Using Selector
var MinAge: Double := Users.Min(function(U: TUser): Double begin Result := U.Age; end);
```

### Any
Checks if any element exists (optionally matching a predicate).
```delphi
if Users.Any then ...
if Users.Any(function(U: TUser): Boolean begin Result := U.Age > 100; end) then ...
```

## Joining

Join two queries based on key properties.

### Simplified Join (Property Names)
```delphi
var
  Joined: TFluentQuery<string>;
begin
  Joined := Users.Join<TAddress, Integer, string>(
    Addresses,    // Inner Query
    'AddressId',  // Outer Key Property (on User)
    'Id',         // Inner Key Property (on Address)
    function(U: TUser; A: TAddress): string
    begin
      Result := U.Name + ' lives in ' + A.Street;
    end
  );
end;
```

## Pagination

Paginate results efficiently.

```delphi
var
  Page: IPagedResult<TUser>;
begin
  Page := Users.Paginate(1, 10); // Page 1, Size 10
  
  // Access properties:
  // Page.Items (TList<T>)
  // Page.TotalCount
  // Page.PageCount
  // Page.HasNextPage
end;
```

## Execution

The query is lazy. Execution happens when you call:
- `ToList`
- An aggregation method (`Count`, `Sum`, etc.)
- `GetEnumerator` (e.g., in a `for..in` loop)

```delphi
var
  UserList: TList<TUser>;
begin
  UserList := Users.Where(...).ToList;
  try
    // use list
  finally
    UserList.Free;
  end;
end;
```
