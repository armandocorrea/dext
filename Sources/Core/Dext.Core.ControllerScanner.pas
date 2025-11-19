unit Dext.Core.ControllerScanner;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.Rtti,
  System.SysUtils,
  System.TypInfo,
  Dext.Core.Routing,
  Dext.DI.Interfaces,
  Dext.Http.Interfaces;

type
  TControllerMethod = record
    Method: TRttiMethod;
    RouteAttribute: DextRouteAttribute;
    Path: string;
    HttpMethod: string;
  end;

  TControllerInfo = record
    RttiType: TRttiType;
    Methods: TArray<TControllerMethod>;
    ControllerAttribute: DextControllerAttribute;
  end;

  IControllerScanner = interface
    function FindControllers: TArray<TControllerInfo>;
    function RegisterRoutes(AppBuilder: IApplicationBuilder): Integer;
    procedure RegisterControllerManual(AppBuilder: IApplicationBuilder);
  end;

  TControllerScanner = class(TInterfacedObject, IControllerScanner)
  private
    FCtx: TRttiContext;
    FServiceProvider: IServiceProvider;
  public
    constructor Create(AServiceProvider: IServiceProvider);
    function FindControllers: TArray<TControllerInfo>;
    function RegisterRoutes(AppBuilder: IApplicationBuilder): Integer;
    procedure RegisterControllerManual(AppBuilder: IApplicationBuilder);
  end;

implementation

{ TControllerScanner }

constructor TControllerScanner.Create(AServiceProvider: IServiceProvider);
begin
  inherited Create;
  FCtx := TRttiContext.Create;
  FServiceProvider := AServiceProvider;
end;

//function TControllerScanner.FindControllers: TArray<TControllerInfo>;
//var
//  Types: TArray<TRttiType>;
//  RttiType: TRttiType;
//  ControllerInfo: TControllerInfo;
//  Controllers: TList<TControllerInfo>;
//  Method: TRttiMethod;
//  MethodInfo: TControllerMethod;
//  Attr: TCustomAttribute;
//begin
//  Controllers := TList<TControllerInfo>.Create;
//  try
//    Types := FCtx.GetTypes;
//
//    for RttiType in Types do
//    begin
//      // ✅ FILTRAR: Apenas records com métodos estáticos
//      if (RttiType.TypeKind = tkRecord) and RttiType.IsRecord then
//      begin
//        // Verificar se tem métodos com atributos de rota
//        var HasRouteMethods := False;
//        var MethodsList: TList<TControllerMethod> := TList<TControllerMethod>.Create;
//
//        try
//          for Method in RttiType.GetMethods do
//          begin
//            // ✅ APENAS MÉTODOS ESTÁTICOS
//            if not Method.IsStatic then
//              Continue;
//
//            // ✅ PROCURAR ATRIBUTOS [DextGet], [DextPost], etc.
//            for Attr in Method.GetAttributes do
//            begin
//              if Attr is DextRouteAttribute then
//              begin
//                MethodInfo.Method := Method;
//                MethodInfo.RouteAttribute := DextRouteAttribute(Attr);
//                MethodInfo.Path := MethodInfo.RouteAttribute.Path;
//                MethodInfo.HttpMethod := MethodInfo.RouteAttribute.Method;
//
//                MethodsList.Add(MethodInfo);
//                HasRouteMethods := True;
//                Break; // Um método pode ter apenas um atributo de rota
//              end;
//            end;
//          end;
//
//          // ✅ SE TEM MÉTODOS DE ROTA, ADICIONAR COMO CONTROLLER
//          if HasRouteMethods then
//          begin
//            ControllerInfo.RttiType := RttiType;
//            ControllerInfo.Methods := MethodsList.ToArray;
//
//            // ✅ VERIFICAR ATRIBUTO [DextController] PARA PREFIXO
//            ControllerInfo.ControllerAttribute := nil;
//            for Attr in RttiType.GetAttributes do
//            begin
//              if Attr is DextControllerAttribute then
//              begin
//                ControllerInfo.ControllerAttribute := DextControllerAttribute(Attr);
//                Break;
//              end;
//            end;
//
//            Controllers.Add(ControllerInfo);
//          end;
//
//        finally
//          MethodsList.Free;
//        end;
//      end;
//    end;
//
//    Result := Controllers.ToArray;
//
//  finally
//    Controllers.Free;
//  end;
//end;

function TControllerScanner.FindControllers: TArray<TControllerInfo>;
var
  Types: TArray<TRttiType>;
  RttiType: TRttiType;
  ControllerInfo: TControllerInfo;
  Controllers: TList<TControllerInfo>;
  Method: TRttiMethod;
  MethodInfo: TControllerMethod;
  Attr: TCustomAttribute;
begin
  Controllers := TList<TControllerInfo>.Create;
  try
    Types := FCtx.GetTypes;

    WriteLn('🔍 Scanning ', Length(Types), ' types...');

    for RttiType in Types do
    begin
      // ✅ DEBUG: Log cada tipo
      WriteLn('  📝 Type: ', RttiType.Name, ' | Kind: ',
        GetEnumName(TypeInfo(TTypeKind), Integer(RttiType.TypeKind)));

      // ✅ FILTRAR: Apenas records
      if (RttiType.TypeKind = tkRecord) then
      begin
        WriteLn('    ✅ Is record: ', RttiType.Name);

        // Verificar se tem métodos com atributos de rota
        var HasRouteMethods := False;
        var MethodsList: TList<TControllerMethod> := TList<TControllerMethod>.Create;

        try
          var Methods := RttiType.GetMethods;
          WriteLn('    🔍 Checking ', Length(Methods), ' methods...');

          for Method in Methods do
          begin
            WriteLn('      🎯 Method: ', Method.Name, ' | Static: ', Method.IsStatic);

            // ✅ APENAS MÉTODOS ESTÁTICOS
            if not Method.IsStatic then
            begin
              WriteLn('        ❌ Skipping - not static');
              Continue;
            end;

            var Attributes := Method.GetAttributes;
            WriteLn('        📋 Attributes: ', Length(Attributes));

            // ✅ PROCURAR ATRIBUTOS [DextGet], [DextPost], etc.
            for Attr in Attributes do
            begin
              WriteLn('        🏷️  Attribute: ', Attr.ClassName);

              if Attr is DextRouteAttribute then
              begin
                WriteLn('        ✅ FOUND ROUTE ATTRIBUTE!');

                MethodInfo.Method := Method;
                MethodInfo.RouteAttribute := DextRouteAttribute(Attr);
                MethodInfo.Path := MethodInfo.RouteAttribute.Path;
                MethodInfo.HttpMethod := MethodInfo.RouteAttribute.Method;

                MethodsList.Add(MethodInfo);
                HasRouteMethods := True;
                Break;
              end;
            end;
          end;

          // ✅ SE TEM MÉTODOS DE ROTA, ADICIONAR COMO CONTROLLER
          if HasRouteMethods then
          begin
            WriteLn('    🎉 ADDING CONTROLLER: ', RttiType.Name);
            ControllerInfo.RttiType := RttiType;
            ControllerInfo.Methods := MethodsList.ToArray;

            // ✅ VERIFICAR ATRIBUTO [DextController] PARA PREFIXO
            ControllerInfo.ControllerAttribute := nil;
            var TypeAttributes := RttiType.GetAttributes;
            for Attr in TypeAttributes do
            begin
              if Attr is DextControllerAttribute then
              begin
                ControllerInfo.ControllerAttribute := DextControllerAttribute(Attr);
                WriteLn('    🎯 Controller prefix: ', ControllerInfo.ControllerAttribute.Prefix);
                Break;
              end;
            end;

            Controllers.Add(ControllerInfo);
          end
          else
          begin
            WriteLn('    ❌ No route methods found in ', RttiType.Name);
          end;

        finally
          MethodsList.Free;
        end;
      end;
    end;

    Result := Controllers.ToArray;
    WriteLn('🎯 Total controllers found: ', Length(Result));

  finally
    Controllers.Free;
  end;
end;

function TControllerScanner.RegisterRoutes(AppBuilder: IApplicationBuilder): Integer;
var
  Controllers: TArray<TControllerInfo>;
  Controller: TControllerInfo;
  ControllerMethod: TControllerMethod;
  FullPath: string;
begin
  Result := 0;
  Controllers := FindControllers;

  WriteLn('🔍 Found ', Length(Controllers), ' controllers:');

  for Controller in Controllers do
  begin
    // ✅ CALCULAR PREFIXO DO CONTROLLER
    var Prefix := '';
    if Assigned(Controller.ControllerAttribute) then
      Prefix := Controller.ControllerAttribute.Prefix;

    WriteLn('  📦 ', Controller.RttiType.Name, ' (Prefix: "', Prefix, '")');

    for ControllerMethod in Controller.Methods do
    begin
      // ✅ CONSTRUIR PATH COMPLETO: Prefix + MethodPath
      FullPath := Prefix + ControllerMethod.Path;

      WriteLn('    ', ControllerMethod.HttpMethod, ' ', FullPath, ' -> ', ControllerMethod.Method.Name);

      // ✅ REGISTRAR ROTA NO APPLICATION BUILDER
      if ControllerMethod.HttpMethod = 'GET' then
          AppBuilder.MapGet(FullPath,
            procedure(Context: IHttpContext)
            begin
              // TODO: Implementar invocação automática com binding
              Context.Response.Json(Format('{"message": "Auto-route: %s"}', [FullPath]));
            end)
      else
      if ControllerMethod.HttpMethod = 'POST' then
          AppBuilder.MapPost(FullPath,
            procedure(Context: IHttpContext)
            begin
              Context.Response.Json(Format('{"message": "Auto-route: %s"}', [FullPath]));
            end)

        // Adicionar outros métodos: PUT, DELETE, PATCH, etc.
      else
        AppBuilder.Map(FullPath,
          procedure(Context: IHttpContext)
          begin
            Context.Response.Json(Format('{"message": "Auto-route: %s (%s)"}',
              [FullPath, ControllerMethod.HttpMethod]));
          end);
      Inc(Result);
    end;
  end;

  WriteLn('✅ Registered ', Result, ' auto-routes');
end;

// No TControllerScanner, adicionar método para registro manual
procedure TControllerScanner.RegisterControllerManual(AppBuilder: IApplicationBuilder);
begin
  WriteLn('🔧 Registering TTaskHandlers manually...');

  // Registrar manualmente os métodos do TTaskHandlers
  var Routes: TArray<TArray<string>> := [
    ['GET', '/api/tasks', 'GetTasks'],
    ['GET', '/api/tasks/{id}', 'GetTask'],
    ['POST', '/api/tasks', 'CreateTask'],
    ['PUT', '/api/tasks/{id}', 'UpdateTask'],
    ['DELETE', '/api/tasks/{id}', 'DeleteTask'],
    ['GET', '/api/tasks/search', 'SearchTasks'],
    ['GET', '/api/tasks/status/{status}', 'GetTasksByStatus'],
    ['GET', '/api/tasks/priority/{priority}', 'GetTasksByPriority'],
    ['GET', '/api/tasks/overdue', 'GetOverdueTasks'],
    ['POST', '/api/tasks/bulk/status', 'BulkUpdateStatus'],
    ['POST', '/api/tasks/bulk/delete', 'BulkDeleteTasks'],
    ['PATCH', '/api/tasks/{id}/status', 'UpdateTaskStatus'],
    ['POST', '/api/tasks/{id}/complete', 'CompleteTask'],
    ['POST', '/api/tasks/{id}/start', 'StartTask'],
    ['POST', '/api/tasks/{id}/cancel', 'CancelTask'],
    ['GET', '/api/tasks/stats', 'GetTasksStats'],
    ['GET', '/api/tasks/stats/status', 'GetStatusCounts']
  ];

  for var Route in Routes do
  begin
    var HttpMethod := Route[0];
    var Path := Route[1];
    var MethodName := Route[2];

    WriteLn('  ', HttpMethod, ' ', Path, ' -> ', MethodName);

    if HttpMethod = 'GET' then
      AppBuilder.MapGet(Path,
        procedure(Context: IHttpContext)
        begin
          Context.Response.Json(Format('{"message": "Manual auto-route: %s -> %s"}', [Path, MethodName]));
        end)
    else if HttpMethod = 'POST' then
      AppBuilder.MapPost(Path,
        procedure(Context: IHttpContext)
        begin
          Context.Response.Json(Format('{"message": "Manual auto-route: %s -> %s"}', [Path, MethodName]));
        end)
    else if HttpMethod = 'PUT' then
      AppBuilder.Map(Path,
        procedure(Context: IHttpContext)
        begin
          Context.Response.Json(Format('{"message": "Manual auto-route: %s -> %s"}', [Path, MethodName]));
        end)
    else if HttpMethod = 'DELETE' then
      AppBuilder.Map(Path,
        procedure(Context: IHttpContext)
        begin
          Context.Response.Json(Format('{"message": "Manual auto-route: %s -> %s"}', [Path, MethodName]));
        end)
    else if HttpMethod = 'PATCH' then
      AppBuilder.Map(Path,
        procedure(Context: IHttpContext)
        begin
          Context.Response.Json(Format('{"message": "Manual auto-route: %s -> %s"}', [Path, MethodName]));
        end);
  end;
end;


end.
