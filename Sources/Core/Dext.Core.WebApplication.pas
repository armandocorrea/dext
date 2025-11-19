unit Dext.Core.WebApplication;

interface

uses
  Dext.DI.Interfaces,
  Dext.Http.Interfaces;

type
  TDextApplication = class(TInterfacedObject, IWebApplication)
  private
    FServices: IServiceCollection;
    FServiceProvider: IServiceProvider;
    FAppBuilder: IApplicationBuilder;
  public
    constructor Create;
    destructor Destroy; override;

    // IWebApplication
    function GetApplicationBuilder: IApplicationBuilder;
    function GetServices: IServiceCollection;
    function UseMiddleware(Middleware: TClass): IWebApplication;
    function MapControllers: IWebApplication;
    procedure Run(Port: Integer = 8080);
    // Fluent interface helpers
    function Services: IServiceCollection;
  end;

implementation

uses
  Dext.Core.ControllerScanner,
  Dext.DI.Core, // ✅ Para TDextServiceCollection
  Dext.Http.Core,
  Dext.Http.Indy.Server; // ✅ Para TIndyWebServer

{ TDextApplication }

constructor TDextApplication.Create;
begin
  inherited Create;
  FServices := TDextServiceCollection.Create; // ✅ Corrigido
  FServiceProvider := FServices.BuildServiceProvider;
  FAppBuilder := TApplicationBuilder.Create(FServiceProvider);
end;

destructor TDextApplication.Destroy;
begin
  inherited Destroy;
end;

function TDextApplication.GetApplicationBuilder: IApplicationBuilder;
begin
  Result := FAppBuilder;
end;

function TDextApplication.GetServices: IServiceCollection;
begin
  Result := FServices;
end;

//function TDextApplication.MapControllers: IWebApplication;
//var
//  Scanner: IControllerScanner;
//  RouteCount: Integer;
//begin
//  WriteLn('🔍 Scanning for controllers...');
//
//  Scanner := TControllerScanner.Create(FServiceProvider);
//  RouteCount := Scanner.RegisterRoutes(FAppBuilder);
//
//  if RouteCount > 0 then
//    WriteLn('✅ Auto-mapped ', RouteCount, ' routes from controllers')
//  else
//    WriteLn('⚠️  No controllers found with routing attributes');
//
//  Result := Self;
//end;

function TDextApplication.MapControllers: IWebApplication;
var
  Scanner: IControllerScanner;
  RouteCount: Integer;
begin
  WriteLn('🔍 Scanning for controllers...');

  Scanner := TControllerScanner.Create(FServiceProvider);
  RouteCount := Scanner.RegisterRoutes(FAppBuilder);

  if RouteCount = 0 then
  begin
    WriteLn('⚠️  No controllers found with routing attributes - using manual fallback');
    Scanner.RegisterControllerManual(FAppBuilder);
  end
  else
    WriteLn('✅ Auto-mapped ', RouteCount, ' routes from controllers');

  Result := Self;
end;


procedure TDextApplication.Run(Port: Integer);
var
  WebHost: IWebHost; // ✅ Usar IWebHost em vez de IHttpServer
  RequestHandler: TRequestDelegate;
begin
  // Construir pipeline
  RequestHandler := FAppBuilder.Build;

  // ✅ CORRETO: Criar TIndyWebServer que implementa IWebHost
  WebHost := TIndyWebServer.Create(Port, RequestHandler, FServiceProvider);

  WriteLn('🚀 Starting Dext HTTP Server on port ', Port);
  WriteLn('📡 Listening for requests...');

  WebHost.Run; // ✅ Chamar Run do IWebHost
end;

function TDextApplication.Services: IServiceCollection;
begin
  Result := FServices;
end;

function TDextApplication.UseMiddleware(Middleware: TClass): IWebApplication;
begin
  FAppBuilder.UseMiddleware(Middleware);
  Result := Self;
end;

end.
