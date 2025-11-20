program Dext.MinimalAPITest;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.DI.Interfaces,
  Dext.DI.Extensions,
  Dext.Http.Interfaces,
  Dext.WebHost,
  Dext.Core.ApplicationBuilder.Extensions,
  Dext.Core.HandlerInvoker;

{$R *.res}

type
  // ✅ Service Interface
  IUserService = interface
    ['{8F3A2B1C-4D5E-6F7A-8B9C-0D1E2F3A4B5C}']
    function GetUserName(UserId: Integer): string;
    function DeleteUser(UserId: Integer): Boolean;
  end;

  // ✅ Service Implementation
  TUserService = class(TInterfacedObject, IUserService)
  public
    function GetUserName(UserId: Integer): string;
    function DeleteUser(UserId: Integer): Boolean;
  end;

  // ✅ Request/Response Records
  TCreateUserRequest = record
    Name: string;
    Email: string;
    Age: Integer;
  end;

  TUpdateUserRequest = record
    Name: string;
    Email: string;
  end;

  TUserResponse = record
    Id: Integer;
    Name: string;
    Email: string;
    Message: string;
  end;

{ TUserService }

function TUserService.GetUserName(UserId: Integer): string;
begin
  Result := Format('User_%d', [UserId]);
end;

function TUserService.DeleteUser(UserId: Integer): Boolean;
begin
  WriteLn(Format('  🗑️  Deleting user %d from database...', [UserId]));
  Result := True;
end;

begin
  try
    WriteLn('🚀 Dext Minimal API - Complete Feature Demo');
    WriteLn('============================================');
    WriteLn;

    var Host := TDextWebHost.CreateDefaultBuilder
      .ConfigureServices(procedure(Services: IServiceCollection)
      begin
        WriteLn('📦 Registering services...');
        TServiceCollectionExtensions.AddSingleton<IUserService, TUserService>(Services);
        WriteLn('  ✅ IUserService registered');
        WriteLn;
      end)
      .Configure(procedure(App: IApplicationBuilder)
      begin
        WriteLn('🔧 Configuring routes with Generic Extensions...');
        WriteLn;

        // ========================================
        // 1️⃣ GET with Route Parameter (Integer)
        // ========================================
        WriteLn('1️⃣  GET /api/users/{id} - Route param binding (Integer)');
        TApplicationBuilderExtensions.MapGet<Integer, IHttpContext>(
          App,
          '/api/users/{id}',
          procedure(UserId: Integer; Ctx: IHttpContext)
          begin
            WriteLn(Format('  → GET User: %d', [UserId]));
            Ctx.Response.Json(Format('{"userId":%d,"message":"User retrieved"}', [UserId]));
          end
        );

        // ========================================
        // 2️⃣ GET with Route Parameter + Service Injection
        // ========================================
        WriteLn('2️⃣  GET /api/users/{id}/name - Route param + Service injection');
        TApplicationBuilderExtensions.MapGet<Integer, IUserService, IHttpContext>(
          App,
          '/api/users/{id}/name',
          procedure(UserId: Integer; UserService: IUserService; Ctx: IHttpContext)
          begin
            var UserName := UserService.GetUserName(UserId);
            WriteLn(Format('  → User %d name: %s', [UserId, UserName]));
            Ctx.Response.Json(Format('{"userId":%d,"name":"%s"}', [UserId, UserName]));
          end
        );

        // ========================================
        // 3️⃣ POST with Body Binding (Record)
        // ========================================
        WriteLn('3️⃣  POST /api/users - Body binding (Record)');
        TApplicationBuilderExtensions.MapPost<TCreateUserRequest, IHttpContext>(
          App,
          '/api/users',
          procedure(Request: TCreateUserRequest; Ctx: IHttpContext)
          begin
            WriteLn(Format('  → Creating user: %s <%s>, Age: %d', 
              [Request.Name, Request.Email, Request.Age]));
            Ctx.Response.StatusCode := 201;
            Ctx.Response.Json(Format('{"name":"%s","email":"%s","age":%d,"message":"User created"}', 
              [Request.Name, Request.Email, Request.Age]));
          end
        );

        // ========================================
        // 4️⃣ PUT with Route Parameter + Body
        // ========================================
        WriteLn('4️⃣  PUT /api/users/{id} - Route param + Body binding');
        TApplicationBuilderExtensions.MapPut<Integer, TUpdateUserRequest, IHttpContext>(
          App,
          '/api/users/{id}',
          procedure(UserId: Integer; Request: TUpdateUserRequest; Ctx: IHttpContext)
          begin
            WriteLn(Format('  → Updating user %d: %s <%s>', 
              [UserId, Request.Name, Request.Email]));
            Ctx.Response.Json(Format('{"userId":%d,"name":"%s","email":"%s","message":"User updated"}', 
              [UserId, Request.Name, Request.Email]));
          end
        );

        // ========================================
        // 5️⃣ DELETE with Route Parameter + Service
        // ========================================
        WriteLn('5️⃣  DELETE /api/users/{id} - Route param + Service injection');
        TApplicationBuilderExtensions.MapDelete<Integer, IUserService, IHttpContext>(
          App,
          '/api/users/{id}',
          procedure(UserId: Integer; UserService: IUserService; Ctx: IHttpContext)
          begin
            WriteLn(Format('  → DELETE User: %d', [UserId]));
            var Success := UserService.DeleteUser(UserId);
            Ctx.Response.Json(Format('{"userId":%d,"deleted":%s}', 
              [UserId, BoolToStr(Success, True).ToLower]));
          end
        );

        // ========================================
        // 6️⃣ GET with String Route Parameter
        // ========================================
        WriteLn('6️⃣  GET /api/posts/{slug} - Route param binding (String)');
        TApplicationBuilderExtensions.MapGet<string, IHttpContext>(
          App,
          '/api/posts/{slug}',
          procedure(Slug: string; Ctx: IHttpContext)
          begin
            WriteLn(Format('  → GET Post: %s', [Slug]));
            Ctx.Response.Json(Format('{"slug":"%s","title":"Post about %s"}', [Slug, Slug]));
          end
        );

        // ========================================
        // 7️⃣ GET with Context (traditional)
        // ========================================
        WriteLn('7️⃣  GET /api/health - IHttpContext (traditional)');
        TApplicationBuilderExtensions.MapGet<IHttpContext>(
          App,
          '/api/health',
          procedure(Ctx: IHttpContext)
          begin
            WriteLn('  → Health check');
            Ctx.Response.Json('{"status":"healthy","timestamp":"' + 
              DateTimeToStr(Now) + '"}');
          end
        );

        WriteLn;
        WriteLn('✅ All routes configured successfully!');
        WriteLn;
      end)
      .Build;

    WriteLn('═══════════════════════════════════════════');
    WriteLn('🌐 Server running on http://localhost:8080');
    WriteLn('═══════════════════════════════════════════');
    WriteLn;
    WriteLn('📝 Test Commands:');
    WriteLn;
    WriteLn('# 1. GET with route param (Integer)');
    WriteLn('curl http://localhost:8080/api/users/123');
    WriteLn;
    WriteLn('# 2. GET with route param + service');
    WriteLn('curl http://localhost:8080/api/users/456/name');
    WriteLn;
    WriteLn('# 3. POST with body');
    WriteLn('curl -X POST http://localhost:8080/api/users ^');
    WriteLn('  -H "Content-Type: application/json" ^');
    WriteLn('  -d "{\"name\":\"John Doe\",\"email\":\"john@example.com\",\"age\":30}"');
    WriteLn;
    WriteLn('# 4. PUT with route param + body');
    WriteLn('curl -X PUT http://localhost:8080/api/users/789 ^');
    WriteLn('  -H "Content-Type: application/json" ^');
    WriteLn('  -d "{\"name\":\"Jane Smith\",\"email\":\"jane@example.com\"}"');
    WriteLn;
    WriteLn('# 5. DELETE with route param + service');
    WriteLn('curl -X DELETE http://localhost:8080/api/users/999');
    WriteLn;
    WriteLn('# 6. GET with string route param');
    WriteLn('curl http://localhost:8080/api/posts/hello-world');
    WriteLn;
    WriteLn('# 7. Health check');
    WriteLn('curl http://localhost:8080/api/health');
    WriteLn;
    WriteLn('═══════════════════════════════════════════');
    WriteLn('Press Enter to stop the server...');
    WriteLn;

    Host.Run;
    Readln;
    Host.Stop;

    WriteLn;
    WriteLn('✅ Server stopped successfully');

  except
    on E: Exception do
    begin
      WriteLn('❌ Error: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
