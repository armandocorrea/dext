unit Dext.Data.TypeSystem;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Rtti,
  System.TypInfo,
  System.Generics.Collections,
  Dext.Core.ValueConverters,
  Dext.Specifications.Types,
  Dext.Specifications.Interfaces; // For IPredicate/IExpression

type
  /// <summary>
  ///   Holds the heavy RTTI metadata for a property.
  ///   Class-based to ensure single instance per property per entity type.
  /// </summary>
  TPropertyMeta = class
  private
    FName: string;
    FPropInfo: PPropInfo;
    FPropTypeInfo: PTypeInfo;
    FConverter: IValueConverter;
  public
    constructor Create(const AName: string; APropInfo: PPropInfo; APropTypeInfo: PTypeInfo; AConverter: IValueConverter = nil);
    
    // RTTI & Metadata
    property Name: string read FName;
    property PropInfo: PPropInfo read FPropInfo;
    property PropTypeInfo: PTypeInfo read FPropTypeInfo;
    property Converter: IValueConverter read FConverter write FConverter;
    
    // Runtime Access helpers (using TypeInfo cache)
    function GetValue(Instance: TObject): TValue;
    procedure SetValue(Instance: TObject; const Value: TValue);
  end;

  /// <summary>
  ///   Lightweight record wrapper for TPropertyMeta that provides strongest typing and
  ///   operator overloading for the Query Expressions syntax.
  ///   TProp<Integer> -> allows operators >, <, =, etc. against Integers.
  /// </summary>
  TProp<T> = record
  private
    FMeta: TPropertyMeta;
  public
    // Implicit conversion to "Old" TPropExpression for backward compatibility
    class operator Implicit(const Value: TProp<T>): TPropExpression;
    
    // Implicit from TPropertyMeta (used by the scaffold/init)
    class operator Implicit(const Value: TPropertyMeta): TProp<T>;

    // Operators returning IExpression (compatible with Fluent Query)
    class operator Equal(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
    class operator NotEqual(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
    class operator GreaterThan(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
    class operator GreaterThanOrEqual(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
    class operator LessThan(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
    class operator LessThanOrEqual(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
    
    // Operators for IN clause
    function In_(const Values: TArray<T>): Dext.Specifications.Interfaces.IExpression;
    
    // Access to underlying metadata
    property Meta: TPropertyMeta read FMeta;
  end;

  /// <summary>
  ///   The static registry for an Entity Type.
  ///   This class is meant to be inherited and populated via Scaffolding/Experts.
  ///   e.g. TUserType = class(TEntityType<TUser>)
  /// </summary>
  TEntityType<T: class> = class
  public
    class var EntityTypeInfo: PTypeInfo;
    class constructor Create;
  end;

implementation

{ TPropertyMeta }

constructor TPropertyMeta.Create(const AName: string; APropInfo: PPropInfo;
  APropTypeInfo: PTypeInfo; AConverter: IValueConverter);
begin
  FName := AName;
  FPropInfo := APropInfo;
  FPropTypeInfo := APropTypeInfo;
  FConverter := AConverter;
end;

function TPropertyMeta.GetValue(Instance: TObject): TValue;
begin
  Result := TValue.Empty;
end;

procedure TPropertyMeta.SetValue(Instance: TObject; const Value: TValue);
begin
end;

{ TProp<T> }

class operator TProp<T>.Implicit(const Value: TProp<T>): TPropExpression;
begin
  if Value.FMeta = nil then
    Result := TPropExpression.Create('')
  else
    Result := TPropExpression.Create(Value.FMeta.Name);
end;

class operator TProp<T>.Implicit(const Value: TPropertyMeta): TProp<T>;
begin
  Result.FMeta := Value;
end;

class operator TProp<T>.Equal(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
var
  Expr: Dext.Specifications.Interfaces.IExpression;
begin
  Expr := Dext.Specifications.Types.TBinaryExpression.Create(
    Left.FMeta.Name, 
    Dext.Specifications.Types.TBinaryOperator.boEqual, 
    TValue.From<T>(Right)
  );
  Result := Expr;
end;

class operator TProp<T>.NotEqual(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
var
  Expr: Dext.Specifications.Interfaces.IExpression;
begin
  Expr := Dext.Specifications.Types.TBinaryExpression.Create(
    Left.FMeta.Name, 
    Dext.Specifications.Types.TBinaryOperator.boNotEqual, 
    TValue.From<T>(Right)
  );
  Result := Expr;
end;

class operator TProp<T>.GreaterThan(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
var
  Expr: Dext.Specifications.Interfaces.IExpression;
begin
  Expr := Dext.Specifications.Types.TBinaryExpression.Create(
    Left.FMeta.Name, 
    Dext.Specifications.Types.TBinaryOperator.boGreaterThan, 
    TValue.From<T>(Right)
  );
  Result := Expr;
end;

class operator TProp<T>.GreaterThanOrEqual(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
var
  Expr: Dext.Specifications.Interfaces.IExpression;
begin
  Expr := Dext.Specifications.Types.TBinaryExpression.Create(
    Left.FMeta.Name, 
    Dext.Specifications.Types.TBinaryOperator.boGreaterThanOrEqual, 
    TValue.From<T>(Right)
  );
  Result := Expr;
end;

class operator TProp<T>.LessThan(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
var
  Expr: Dext.Specifications.Interfaces.IExpression;
begin
  Expr := Dext.Specifications.Types.TBinaryExpression.Create(
    Left.FMeta.Name, 
    Dext.Specifications.Types.TBinaryOperator.boLessThan, 
    TValue.From<T>(Right)
  );
  Result := Expr;
end;

class operator TProp<T>.LessThanOrEqual(const Left: TProp<T>; Right: T): Dext.Specifications.Interfaces.IExpression;
var
  Expr: Dext.Specifications.Interfaces.IExpression;
begin
  Expr := Dext.Specifications.Types.TBinaryExpression.Create(
    Left.FMeta.Name, 
    Dext.Specifications.Types.TBinaryOperator.boLessThanOrEqual, 
    TValue.From<T>(Right)
  );
  Result := Expr;
end;

function TProp<T>.In_(const Values: TArray<T>): Dext.Specifications.Interfaces.IExpression;
begin
  Result := nil;
end;

{ TEntityType<T> }

class constructor TEntityType<T>.Create;
begin
  EntityTypeInfo := TypeInfo(T);
end;

end.
