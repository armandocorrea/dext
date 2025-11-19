// Examples/MinimalAPI/MinimalAPIExample.pas
program MinimalAPIExample;

{$APPTYPE CONSOLE}

{$R *.res}

//// Como ficará o uso na prática
//var
//  Services: IServiceCollection;
//  Provider: IServiceProvider;
//  MyService: IMyService;
//begin
//  Services := TDextDIFactory.CreateServiceCollection;
//
//  // Usando os helpers genéricos
//  TServiceCollectionExtensions.AddSingleton<IMyService, TMyService>(Services);
//  TServiceCollectionExtensions.AddTransient<IOtherService, TOtherService>(Services);
//
//  Provider := Services.BuildServiceProvider;
//
//  // Obtendo serviços
//  MyService := TServiceProviderExtensions.GetService<IMyService>(Provider);
//
//  // Ou sem generics
//  MyService := Provider.GetService(IMyService) as IMyService;
//end;


uses
  Dext.WebHost,
  Dext.DI.Interfaces,
  Dext.Http.Interfaces;

var
  Builder: IWebHostBuilder;
  Host: IWebHost;

begin
  Builder := TDextWebHost.CreateDefaultBuilder;

  Builder.ConfigureServices(
    procedure(Services: IServiceCollection)
    begin
      Services.AddSingleton<ISomeService, TSomeService>;
    end);

  Builder.Configure(
    procedure(App: IApplicationBuilder)
    begin
      App.Map('/hello',
        procedure(Context: IHttpContext)
        begin
          Context.Response.Write('Hello from Dext!');
        end);

      App.Map('/time',
        procedure(Context: IHttpContext)
        begin
          Context.Response.Write(Format('Server time: %s', [DateTimeToStr(Now)]));
        end);

      App.Map('/json',
        procedure(Context: IHttpContext)
        begin
          Context.Response.Json('{"message": "Hello JSON!", "timestamp": "' +
            DateTimeToStr(Now) + '"}');
        end);
    end);

  Host := Builder.Build;
  Host.Run;
end.