// Dext.Http.Injection.pas
unit Dext.Http.Injection;

interface

uses
  System.Rtti, System.SysUtils, System.TypInfo,
  Dext.Http.Interfaces, Dext.DI.Interfaces;

type
  THandlerInjector = class
  public
    class procedure ExecuteHandler(AHandler: TValue; AContext: IHttpContext; AServiceProvider: IServiceProvider);
  end;

implementation

class procedure THandlerInjector.ExecuteHandler(AHandler: TValue;
  AContext: IHttpContext; AServiceProvider: IServiceProvider);
var
  Context: TRttiContext;
  Method: TRttiMethod;
  Parameters: TArray<TRttiParameter>;
  Arguments: TArray<TValue>;
  I: Integer;
begin
  Context := TRttiContext.Create;
  try
    // Obter método do anonymous method via RTTI
    Method := Context.GetType(AHandler.TypeInfo).GetMethod('Invoke');

    Parameters := Method.GetParameters;
    SetLength(Arguments, Length(Parameters));

    // Primeiro parâmetro é sempre IHttpContext
    Arguments[0] := TValue.From<IHttpContext>(AContext);

    // Resolver demais parâmetros do container DI
    for I := 1 to High(Parameters) do
    begin
      var ParamType := Parameters[I].ParamType;
      if ParamType.TypeKind = tkInterface then
      begin
        var Guid := GetTypeData(ParamType.Handle)^.Guid;
        var Service := AServiceProvider.GetServiceAsInterface(
          TServiceType.FromInterface(Guid));
        Arguments[I] := TValue.From(Service);
      end;
    end;

    // Executar handler
    Method.Invoke(AHandler, Arguments);

  finally
    Context.Free;
  end;
end;

end.
