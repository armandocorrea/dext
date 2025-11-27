program ControllerExample;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  System.Rtti,
  DextFramework, // ✅ The only core unit needed!
  Dext.Http.Cors,
  Dext.Http.StaticFiles,
  Dext.Auth.Middleware,
  ControllerExample.Controller in 'ControllerExample.Controller.pas',
  ControllerExample.Services in 'ControllerExample.Services.pas';

begin
  try
    WriteLn('🚀 Starting Dext Controller Example...');
    var App: IWebApplication := TDextApplication.Create;

    // 1. Register Configuration (IOptions)
    App.Services.Configure<TMySettings>(
      App.Configuration.GetSection('AppSettings')
    );

    // 2. Register Services
    App.Services
      .AddSingleton<IGreetingService, TGreetingService>
      .AddControllers;
    
    // 3. Register Health Checks
    App.Services.AddHealthChecks
      .AddCheck<TDatabaseHealthCheck>
      .Build;

    // 4. Register Background Services
    App.Services.AddBackgroundServices
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
