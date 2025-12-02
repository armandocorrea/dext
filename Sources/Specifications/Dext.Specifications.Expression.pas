unit Dext.Specifications.Expression;

interface

uses
  System.SysUtils,
  System.Rtti,
  Dext.Specifications.Interfaces,
  Dext.Specifications.Types;

/// <summary>
///   Global helper to create a property expression.
/// </summary>
function Prop(const AName: string): TPropExpression;

implementation

function Prop(const AName: string): TPropExpression;
begin
  Result := TPropExpression.Create(AName);
end;

end.
