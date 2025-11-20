program TaskFlowAPI;

uses
  // FastMM5,
  Dext.Core.WebApplication,
  Dext.DI.Extensions,
  Dext.Core.Routing,
  Dext.Core.ModelBinding,
  Dext.Http.Interfaces,
  TaskFlow.Domain,
  TaskFlow.Repository.Interfaces,
  TaskFlow.Repository.Mock,
  TaskFlow.Handlers.Tasks,
  Dext.Core.HandlerInvoker,
  Dext.Core.ApplicationBuilder.Extensions, // ✅ Extensões genéricas
  System.SysUtils;

type
  // ✅ Modelo para teste
  TUser = record
    Name: string;
    Email: string;
  end;

  // ✅ Serviço para teste
  IUserService = interface
    ['{A1B2C3D4-E5F6-7890-1234-567890ABCDEF}']
    function CreateUser(const User: TUser): TUser;
  end;

  TUserService = class(TInterfacedObject, IUserService)
  public
    function CreateUser(const User: TUser): TUser;
  end;

{ TUserService }

function TUserService.CreateUser(const User: TUser): TUser;
begin
  // Simula criação (retorna o mesmo usuário)
  Result := User;
  WriteLn(Format('👤 UserService: Creating user "%s" (%s)', [User.Name, User.Email]));
end;

var
  App: IWebApplication;

begin
  ReportMemoryLeaksOnShutdown := True;

  try
    WriteLn('🚀 Starting TaskFlow API...');
    WriteLn('📦 Dext Framework v0.1.0');
    WriteLn('⏰ ', FormatDateTime('yyyy-mm-dd hh:nn:ss', Now));
    WriteLn('');

    // 1. Criar aplicação Dext
    App := TDextApplication.Create;

    // 2. Configurar DI Container
    TServiceCollectionExtensions.AddSingleton<ITaskRepository, TTaskRepositoryMock>(App.GetServices);
    TServiceCollectionExtensions.AddSingleton<IUserService, TUserService>(App.GetServices); // ✅ Registrar UserService

    // 3. Mapear Handlers
    App.MapControllers;

    WriteLn('✅ Auto-mapped routes registered');
    WriteLn('');

    // 4. ✅ MAPEAMENTO MANUAL SIMPLES - FASE 1.1
    var AppBuilder := App.GetApplicationBuilder;

    // Rota raiz
    AppBuilder.MapGet('/',
      procedure(Context: IHttpContext)
      begin
        Context.Response.StatusCode := 200;
        Context.Response.Json('{"message": "Dext Framework API", "status": "running"}');
      end);

    // Handler SIMPLES - sem DI, sem binding complexo
    AppBuilder.MapGet('/api/tasks',
      procedure(Context: IHttpContext)
      begin
        WriteLn('🎯 HANDLER: Simple GetTasks executing');
        Context.Response.StatusCode := 200;
        Context.Response.Json('{"message": "Tasks endpoint", "count": 5}');
        WriteLn('✅ Handler completed');
      end);

    AppBuilder.MapGet('/api/tasks/1',
      procedure(Context: IHttpContext)
      begin
        WriteLn('🎯 HANDLER: Simple GetTask by ID executing');
        Context.Response.StatusCode := 200;
        Context.Response.Json('{"id": 1, "title": "Sample Task", "status": "pending"}');
        WriteLn('✅ Handler completed');
      end);

    AppBuilder.MapGet('/api/tasks/stats',
      procedure(Context: IHttpContext)
      begin
        WriteLn('🎯 HANDLER: Simple GetStats executing');
        Context.Response.StatusCode := 200;
        Context.Response.Json('{"total": 10, "completed": 3, "pending": 7}');
        WriteLn('✅ Handler completed');
      end);

    // Handler com erro para testar invoker
    AppBuilder.MapGet('/api/tasks/error',
      procedure(Context: IHttpContext)
      begin
        WriteLn('🎯 HANDLER: Simulating error...');
        raise Exception.Create('Simulated error for testing');
      end);

    // ✅ NOVO: Endpoint com Handler Injection (Minimal API Style)
    // Recebe: Body (TUser), Serviço (IUserService), Contexto (IHttpContext)
    TApplicationBuilderExtensions.MapPost<TUser, IUserService, IHttpContext>(AppBuilder, '/api/users',
      procedure(User: TUser; UserService: IUserService; Context: IHttpContext)
      var
        CreatedUser: TUser;
      begin
        WriteLn('🎯 HANDLER: CreateUser executing via Handler Injection');
        
        // Lógica de negócio usando o serviço injetado
        CreatedUser := UserService.CreateUser(User);
        
        // Resposta usando o contexto injetado
        Context.Response.StatusCode := 201;
        Context.Response.Json(Format('{"message": "User created", "name": "%s", "email": "%s"}', 
          [CreatedUser.Name, CreatedUser.Email]));
          
        WriteLn('✅ Handler completed');
      end);

    WriteLn('✅ Manual routes mapped:');
    WriteLn('   GET /');
    WriteLn('   GET /api/tasks');
    WriteLn('   GET /api/tasks/1');
    WriteLn('   GET /api/tasks/stats');
    WriteLn('   GET /api/tasks/error');
    WriteLn('   POST /api/users (New!)'); // ✅ Novo endpoint
    WriteLn('');
    WriteLn('🌐 Server running on: http://localhost:8080');
    WriteLn('');
    WriteLn('🎯 Test with:');
    WriteLn('   curl http://localhost:8080/');
    WriteLn('   curl http://localhost:8080/api/tasks');
    WriteLn('   curl http://localhost:8080/api/tasks/error');
    WriteLn('');
    WriteLn('⏹️  Press Enter to stop');
    WriteLn('');

    // 5. 🚀 INICIAR SERVIDOR!
    App.Run(8080);
    ReadLn;

  except
    on E: Exception do
    begin
      WriteLn('❌ Startup error: ', E.Message);
      WriteLn('💀 Application terminated');
      ReadLn;
    end;
  end;
end.
