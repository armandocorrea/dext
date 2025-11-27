program ControllerExample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Rtti,
  Dext.Core.WebApplication,
  Dext.DI.Interfaces,
  Dext.DI.Core,
  Dext.DI.Extensions,
  Dext.Http.Interfaces,
  Dext.Http.Cors,
  Dext.Http.StaticFiles,
  Dext.Auth.Middleware,
  Dext.Configuration.Interfaces,
  Dext.Options.Extensions,
  Dext.Core.Extensions,
  Dext.HealthChecks,
  ControllerExample.Controller in 'ControllerExample.Controller.pas',
  ControllerExample.Services in 'ControllerExample.Services.pas';

begin
  try
    WriteLn('🚀 Starting Dext Controller Example...');
    var App: IWebApplication := TDextApplication.Create;

    // 1. Register Configuration (IOptions)
    TOptionsServiceCollectionExtensions.Configure<TMySettings>(
      App.Services, 
      App.Configuration.GetSection('AppSettings')
    );

    // 2. Register Services
    TServiceCollectionExtensions.AddSingleton<IGreetingService, TGreetingService>(App.Services);
    TServiceCollectionExtensions.AddControllers(App.Services);
    
    // 3. Register Health Checks
    TDextServiceCollectionExtensions.AddHealthChecks(App.Services)
      .AddCheck<TDatabaseHealthCheck>
      .Build;

    // 4. Register Background Services
    TDextServiceCollectionExtensions.AddBackgroundServices(App.Services)
      .AddHostedService<TWorkerService>
      .Build;

    // 5. Configure Middleware Pipeline
    var Builder := App.GetApplicationBuilder;

    // CORS
    var corsOptions := TCorsOptions.Create;
    corsOptions.AllowedOrigins := ['http://localhost:5173'];
    corsOptions.AllowCredentials := True;
    TApplicationBuilderCorsExtensions.UseCors(Builder, corsOptions);

    // Static Files
    TApplicationBuilderStaticFilesExtensions.UseStaticFiles(Builder);
    
    // Health Checks
    App.UseMiddleware(THealthCheckMiddleware);

    // JWT Authentication
    var AuthOptions := TJwtAuthenticationOptions.Default('dext-secret-key-must-be-very-long-and-secure-at-least-32-chars');
    AuthOptions.Issuer := 'dext-issuer';
    AuthOptions.Audience := 'dext-audience';
    Builder.UseMiddleware(TJwtAuthenticationMiddleware, TValue.From(AuthOptions));
       
    // 6. Map Controllers
    App.MapControllers;

    // 7. Run Application
    App.Run(8080);
  except
    on E: Exception do
      Writeln('❌ Error: ', E.ClassName, ': ', E.Message);
  end;
end.
