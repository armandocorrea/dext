unit DextFramework;

interface

uses
  System.SysUtils,
  System.Classes,
  System.TypInfo,
  System.Generics.Collections,
  Dext.Core.WebApplication,
  Dext.Http.Interfaces,
  Dext.DI.Interfaces,
  Dext.Core.Controllers,
  Dext.Configuration.Interfaces,
  Dext.Options,
  Dext.Http.Results,
  Dext.Core.ControllerScanner,
  Dext.HealthChecks,
  Dext.Hosting.BackgroundService,
  Dext.Options.Extensions,
  Dext.Http.Core;

type
  // ===========================================================================
  // 🏷️ Aliases for Common Types (Facade)
  // ===========================================================================
  
  // Core
  IWebApplication = Dext.Http.Interfaces.IWebApplication;
  TDextApplication = Dext.Core.WebApplication.TDextApplication;
  
  // HTTP
  IHttpContext = Dext.Http.Interfaces.IHttpContext;
  IHttpRequest = Dext.Http.Interfaces.IHttpRequest;
  IHttpResponse = Dext.Http.Interfaces.IHttpResponse;
  IMiddleware = Dext.Http.Interfaces.IMiddleware;
  TMiddleware = Dext.Http.Core.TMiddleware;
  TRequestDelegate = Dext.Http.Interfaces.TRequestDelegate;
  
  // DI
  IServiceCollection = Dext.DI.Interfaces.IServiceCollection;
  IServiceProvider = Dext.DI.Interfaces.IServiceProvider;
  TServiceType = Dext.DI.Interfaces.TServiceType;
  
  // Configuration
  IConfiguration = Dext.Configuration.Interfaces.IConfiguration;
  IConfigurationSection = Dext.Configuration.Interfaces.IConfigurationSection;
  // IOptions<T> removed due to Delphi language limitations with generic aliases.
  // Users should include Dext.Options explicitly if they need to reference the type.
  
  // Results
  IResult = Dext.Http.Interfaces.IResult;
  Results = Dext.Http.Results.Results;

  // Middleware
  THealthCheckMiddleware = Dext.HealthChecks.THealthCheckMiddleware;

  // ===========================================================================
  // 🛠️ Fluent Helpers & Wrappers
  // ===========================================================================

  /// <summary>
  ///   Helper for TDextServices to add framework features.
  /// </summary>
  TDextServicesHelper = record helper for TDextServices
  public
    function AddControllers: TDextServices;
    function AddHealthChecks: THealthCheckBuilder;
    function AddBackgroundServices: TBackgroundServiceBuilder;
    
    function Configure<T: class, constructor>(Configuration: IConfiguration): TDextServices; overload;
    function Configure<T: class, constructor>(Section: IConfigurationSection): TDextServices; overload;
  end;

implementation

{ TDextServicesHelper }

function TDextServicesHelper.AddControllers: TDextServices;
var
  Scanner: IControllerScanner;
begin
  Scanner := TControllerScanner.Create(nil);
  Scanner.RegisterServices(Self.Unwrap);
  Result := Self;
end;

function TDextServicesHelper.AddHealthChecks: THealthCheckBuilder;
begin
  Result := THealthCheckBuilder.Create(Self.Unwrap);
end;

function TDextServicesHelper.AddBackgroundServices: TBackgroundServiceBuilder;
begin
  Result := TBackgroundServiceBuilder.Create(Self.Unwrap);
end;

function TDextServicesHelper.Configure<T>(Configuration: IConfiguration): TDextServices;
begin
  TOptionsServiceCollectionExtensions.Configure<T>(Self.Unwrap, Configuration);
  Result := Self;
end;

function TDextServicesHelper.Configure<T>(Section: IConfigurationSection): TDextServices;
begin
  TOptionsServiceCollectionExtensions.Configure<T>(Self.Unwrap, Section);
  Result := Self;
end;

end.
