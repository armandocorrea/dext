program ModelBindingTest;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Dext.MM,
  System.SysUtils,
  Dext,
  Dext.Web,
  Dext.Utils,
  Dext.DI.Interfaces,
  Dext.Web.Interfaces,
  ModelBinding.Endpoints in 'ModelBinding.Endpoints.pas',
  ModelBinding.Controller in 'ModelBinding.Controller.pas';

type
  TModelBindingTestStartup = class(TInterfacedObject, IStartup)
  public
    procedure ConfigureServices(const Services: TDextServices; const Configuration: IConfiguration);
    procedure Configure(const App: IWebApplication);
  end;

{ TModelBindingTestStartup }

procedure TModelBindingTestStartup.ConfigureServices(const Services: TDextServices; const Configuration: IConfiguration);
begin
  WriteLn('[Services] Registering...');
  Services.AddSingleton<IProductService, TProductService>;
  Services.AddControllers;
  WriteLn('  - IProductService registered');
  WriteLn('  - Controllers registered');
  WriteLn;
end;

procedure TModelBindingTestStartup.Configure(const App: IWebApplication);
var
  Builder: TDextAppBuilder;
begin
  Builder := App.GetBuilder;
  
  Builder.UseExceptionHandler;

  // Map Minimal API endpoints
  TModelBindingEndpoints.Map(Builder);
  
  // Log Controller endpoints  
  WriteLn('=== CONTROLLER ENDPOINTS ===');
  WriteLn('11. GET  /api/controller/header     - Controller header binding');
  WriteLn('12. GET  /api/controller/query      - Controller query binding');
  WriteLn('13. POST /api/controller/body       - Controller body binding');
  WriteLn('14. POST /api/controller/mixed      - Controller header+body binding');
  WriteLn('15. GET  /api/controller/route/{id} - Controller route+query binding');
  
  // Map Controllers
  App.MapControllers;

  WriteLn;
  WriteLn('[Routes] All endpoints configured!');
  WriteLn;
end;

// =============================================================================
// MAIN PROGRAM
// =============================================================================

var
  WebApp: IWebApplication;
begin
  Randomize;
  SetConsoleCharSet;
  
  try
    WriteLn('==========================================================');
    WriteLn('  Dext Model Binding Test Server');
    WriteLn('  Covering All Binding Scenarios: Minimal API + Controllers');
    WriteLn('==========================================================');
    WriteLn;

    WebApp := TDextApplication.Create;
    WebApp.UseStartup(TModelBindingTestStartup.Create);
    WebApp.BuildServices;

    WriteLn('==========================================================');
    WriteLn('  Server running on http://localhost:8080');
    WriteLn('==========================================================');
    WriteLn;
    WriteLn('Run the test script: .\Test.ModelBinding.ps1');
    WriteLn;
    WriteLn('Press Enter to stop the server...');
    
    WebApp.Run(8080);
    
    ConsolePause;

  except
    on E: Exception do
    begin
      WriteLn('Error: ', E.Message);
      WriteLn('Exception Class: ', E.ClassName);
      if E.StackTrace <> '' then
        WriteLn('Stack Trace: ', E.StackTrace);
      ConsolePause;
    end;
  end;
end.
