unit Dext.WebHost;

interface

uses
  System.SysUtils,
  Dext.DI.Interfaces,
  Dext.Http.Interfaces,
  Dext.Http.Core,
  Dext.Http.Indy.Server;

type
  TWebHostBuilder = class(TInterfacedObject, IWebHostBuilder)
  private
    FServices: IServiceCollection;
    FAppConfig: TProc<IApplicationBuilder>;
  public
    constructor Create;

    function ConfigureServices(AConfigurator: TProc<IServiceCollection>): IWebHostBuilder;
    function Configure(AConfigurator: TProc<IApplicationBuilder>): IWebHostBuilder;
    function Build: IWebHost;
  end;

implementation

uses
  Dext.DI.Core;

{ TWebHostBuilder }

constructor TWebHostBuilder.Create;
begin
  inherited Create;
  FServices := TDextServiceCollection.Create;
end;

function TWebHostBuilder.ConfigureServices(AConfigurator: TProc<IServiceCollection>): IWebHostBuilder;
begin
  if Assigned(AConfigurator) then
    AConfigurator(FServices);
  Result := Self;
end;

function TWebHostBuilder.Configure(AConfigurator: TProc<IApplicationBuilder>): IWebHostBuilder;
begin
  FAppConfig := AConfigurator;
  Result := Self;
end;

function TWebHostBuilder.Build: IWebHost;
var
  AppBuilder: IApplicationBuilder;
  Pipeline: TRequestDelegate;
  ServiceProvider: IServiceProvider;
begin
  // ✅ PRIMEIRO construir o ServiceProvider, DEPOIS criar AppBuilder
  ServiceProvider := FServices.BuildServiceProvider;

  AppBuilder := TApplicationBuilder.Create(ServiceProvider); // ✅ CORREÇÃO

  if Assigned(FAppConfig) then
    FAppConfig(AppBuilder);

  Pipeline := AppBuilder.Build;

  Result := TIndyWebServer.Create(8080, Pipeline, ServiceProvider);
end;

end.
