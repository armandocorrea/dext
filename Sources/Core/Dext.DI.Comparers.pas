// Adicione esta unit
unit Dext.DI.Comparers;

interface

uses
  System.Generics.Defaults,
  System.Hash,
  System.SysUtils,
  Dext.DI.Interfaces;

type
  TServiceTypeComparer = class(TInterfacedObject, IEqualityComparer<TServiceType>)
  public
    function Equals(const Left, Right: TServiceType): Boolean; reintroduce;
    function GetHashCode(const Value: TServiceType): Integer; reintroduce;
  end;

implementation

{ TServiceTypeComparer }

function TServiceTypeComparer.Equals(const Left, Right: TServiceType): Boolean;
begin
  Result := Left = Right;
end;

function TServiceTypeComparer.GetHashCode(const Value: TServiceType): Integer;
var
  GuidStr: string;
  ClassPtr: Pointer;
begin
  if Value.IsInterface then
  begin
    // Para interfaces, usar hash do GUID como string
    GuidStr := GUIDToString(Value.AsInterface);
    Result := THashBobJenkins.GetHashValue(GuidStr);
  end
  else
  begin
    // Para classes, usar hash do ponteiro da classe
    ClassPtr := Pointer(Value.AsClass);
    Result := THashBobJenkins.GetHashValue(ClassPtr, SizeOf(Pointer));
  end;
end;

end.
