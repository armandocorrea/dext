// Dext.Http.RoutingMiddleware.pas - ATUALIZAR
unit Dext.Http.RoutingMiddleware;

interface

uses
  Dext.Http.Core,
  Dext.Http.Interfaces,
  Dext.Http.Routing;  // ✅ Para IRouteMatcher

type
  TRoutingMiddleware = class(TMiddleware)
  private
    FRouteMatcher: IRouteMatcher;  // ✅ Interface - sem reference circular!
  public
    constructor Create(const ARouteMatcher: IRouteMatcher);
    procedure Invoke(AContext: IHttpContext; ANext: TRequestDelegate); override;
  end;

implementation

uses
  System.Generics.Collections,
  Dext.Http.Indy;

{ TRoutingMiddleware }

constructor TRoutingMiddleware.Create(const ARouteMatcher: IRouteMatcher);
begin
  inherited Create;
  FRouteMatcher := ARouteMatcher;  // ✅ Interface gerencia ciclo de vida
end;

procedure TRoutingMiddleware.Invoke(AContext: IHttpContext; ANext: TRequestDelegate);
var
  Handler: TRequestDelegate;
  RouteParams: TDictionary<string, string>;
  IndyContext: TIndyHttpContext;
begin
  var Path := AContext.Request.Path;

  // ✅ USAR RouteMatcher via interface
  if FRouteMatcher.FindMatchingRoute(Path, Handler, RouteParams) then
  begin
    try
      // ✅ INJETAR parâmetros de rota se encontrados
      if Assigned(RouteParams) and (AContext is TIndyHttpContext) then
      begin
        IndyContext := TIndyHttpContext(AContext);
        IndyContext.SetRouteParams(RouteParams);
      end;

      Handler(AContext);
    finally
      RouteParams.Free;
    end;
  end
  else
  begin
    // Nenhuma rota encontrada - chamar next (404 handler)
    ANext(AContext);
  end;
end;

end.
