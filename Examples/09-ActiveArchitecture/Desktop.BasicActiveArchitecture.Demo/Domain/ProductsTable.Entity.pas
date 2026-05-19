unit ProductsTable.Entity;

interface

uses
  Dext.Entity,
  Dext.Entity.Mapping,
  Dext.Core.SmartTypes,
  Dext.Types.Nullable,
  Dext.Types.Lazy,
  Dext.Specifications.Types,
  System.SysUtils,
  System.Classes;

type
  [Table('ProductsTable')]
  TProductsTable = class
  private
    FProductId: IntType;
    FProductName: StringType;
    FSupplierId: IntType;
    FCategoryId: IntType;
    FQuantityPerUnit: StringType;
    FUnitPrice: CurrencyType;
    FUnitsInStock: StringType;
    FUnitsOnOrder: StringType;
    FReorderLevel: StringType;
    FDiscontinued: BoolType;
  public
    [PK, AutoInc, Column('ProductID')]
    property ProductId: IntType read FProductId write FProductId;
    [Required, MaxLength(40)]
    property ProductName: StringType read FProductName write FProductName;
    [Column('SupplierID')]
    property SupplierId: IntType read FSupplierId write FSupplierId;
    [Column('CategoryID')]
    property CategoryId: IntType read FCategoryId write FCategoryId;
    [MaxLength(20)]
    property QuantityPerUnit: StringType read FQuantityPerUnit write FQuantityPerUnit;
    property UnitPrice: CurrencyType read FUnitPrice write FUnitPrice;
    property UnitsInStock: StringType read FUnitsInStock write FUnitsInStock;
    property UnitsOnOrder: StringType read FUnitsOnOrder write FUnitsOnOrder;
    property ReorderLevel: StringType read FReorderLevel write FReorderLevel;
    [Required]
    property Discontinued: BoolType read FDiscontinued write FDiscontinued;
  end;

implementation

end.
