unit Dext.Specifications.Interfaces;

interface

uses
  System.Rtti,
  System.Generics.Collections;

type
  TMatchMode = (mmExact, mmStart, mmEnd, mmAnywhere);

  /// <summary>
  ///   Represents an expression in a query (e.g., "Age > 18").
  /// </summary>
  IExpression = interface
    ['{10000000-0000-0000-0000-000000000001}']
    function ToString: string; // For debugging/logging
  end;

  /// <summary>
  ///   Represents an order by clause.
  /// </summary>
  IOrderBy = interface
    ['{10000000-0000-0000-0000-000000000002}']
    function GetPropertyName: string;
    function GetAscending: Boolean;
  end;

  /// <summary>
  ///   Base interface for specifications.
  ///   Encapsulates query logic for an entity type T.
  /// </summary>
  ISpecification<T> = interface
    ['{10000000-0000-0000-0000-000000000003}']
    function GetExpression: IExpression;
    function GetIncludes: TArray<string>;
    function GetOrderBy: TArray<IOrderBy>;
    function GetSkip: Integer;
    function GetTake: Integer;
    function IsPagingEnabled: Boolean;
    function GetSelectedColumns: TArray<string>;
    function IsTrackingEnabled: Boolean;
    
    // Fluent methods
    procedure Take(const ACount: Integer);
    procedure Skip(const ACount: Integer);
    
    procedure EnableTracking(const AValue: Boolean);
    procedure AsNoTracking;
  end;

  /// <summary>
  ///   Visitor interface for traversing the expression tree.
  ///   This is used by the ORM/Repository to translate expressions to SQL.
  /// </summary>
  IExpressionVisitor = interface
    ['{10000000-0000-0000-0000-000000000004}']
    procedure Visit(const AExpression: IExpression);
  end;

implementation

end.
