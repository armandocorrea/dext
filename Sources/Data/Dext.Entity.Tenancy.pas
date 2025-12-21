unit Dext.Entity.Tenancy;

interface

uses
  System.SysUtils,
  Dext.MultiTenancy;

type
  /// <summary>
  ///    Interface to mark entities as tenant-aware.
  ///    The TenantId property will be automatically populated/filtered.
  /// </summary>
  ITenantAware = interface
    ['{F4A7B3C2-5D6E-4F8A-9B0C-1D2E3F4A5B6C}']
    function GetTenantId: string;
    procedure SetTenantId(const AValue: string);
    
    property TenantId: string read GetTenantId write SetTenantId;
  end;

  /// <summary>
  ///   Base class for tenant-aware entities to simplify implementation.
  /// </summary>
  // Changed from TInterfacedObject to TObject to avoid hidden complexity
  TTenantEntity = class(TObject, ITenantAware)
  private
    FTenantId: string;
  protected
    // IInterface implementation
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    function GetTenantId: string;
    procedure SetTenantId(const AValue: string);
    
    property TenantId: string read GetTenantId write SetTenantId;
  end;

implementation

{ TTenantEntity }

function TTenantEntity.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  if GetInterface(IID, Obj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TTenantEntity._AddRef: Integer;
begin
  Result := -1; // No reference counting
end;

function TTenantEntity._Release: Integer;
begin
  Result := -1; // No reference counting
end;

function TTenantEntity.GetTenantId: string;
begin
  Result := FTenantId;
end;

procedure TTenantEntity.SetTenantId(const AValue: string);
begin
  FTenantId := AValue;
end;

end.
