// Dext.Http.Core.pas - Versão Corrigida
unit Dext.Http.Core;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  Dext.DI.Interfaces,
  Dext.Core.HandlerInvoker,
  Dext.Http.Interfaces,
  Dext.Http.Routing;


type
  TMiddlewareRegistration = record
    MiddlewareClass: TClass;
    Parameters: TArray<TValue>;
  end;

  TApplicationBuilder = class(TInterfacedObject, IApplicationBuilder)
  private
    FMiddlewares: TList<TMiddlewareRegistration>;
    FMappedRoutes: TDictionary<string, TRequestDelegate>;
    FRoutePatterns: TDictionary<TRoutePattern, TRequestDelegate>;
    FServiceProvider: IServiceProvider;

    function CreateMiddlewareInstance(AMiddlewareClass: TClass; const AParameters: TArray<TValue>): IMiddleware;
    function CreateMiddlewarePipeline(const ARegistration: TMiddlewareRegistration; ANext: TRequestDelegate): TRequestDelegate;
  public
    constructor Create(AServiceProvider: IServiceProvider);
    destructor Destroy; override;
    function GetServiceProvider: IServiceProvider;

    function UseMiddleware(AMiddleware: TClass): IApplicationBuilder; overload;
    function UseMiddleware(AMiddleware: TClass; const AParam: TValue): IApplicationBuilder; overload; // ✅ NOVO
    function UseMiddleware(AMiddleware: TClass; const AParams: array of TValue): IApplicationBuilder; overload; // ✅ NOVO
    function UseModelBinding: IApplicationBuilder;

    function Map(const APath: string; ADelegate: TRequestDelegate): IApplicationBuilder;
    function MapPost(const Path: string; Handler: TProc<IHttpContext>): IApplicationBuilder; overload;
    function MapGet(const Path: string; Handler: TProc<IHttpContext>): IApplicationBuilder; overload;
    function Build: TRequestDelegate;
  end;

  TMiddleware = class(TInterfacedObject, IMiddleware)
  public
    procedure Invoke(AContext: IHttpContext; ANext: TRequestDelegate); virtual; abstract;
  end;

implementation

uses
  Dext.Core.Controllers, // ✅ Adicionado para TStaticHandler
  Dext.Core.ModelBinding,
  Dext.Http.Indy,
  Dext.Http.Pipeline,
  Dext.Http.RoutingMiddleware;

procedure InjectRouteParams(AContext: IHttpContext;
  const AParams: TDictionary<string, string>);
begin
  // Precisamos estender as implementações concretas para suportar RouteParams
  // Por enquanto, vamos adicionar suporte básico
  // Esta é uma implementação temporária - precisaremos atualizar TIndyHttpRequest
end;

{ TApplicationBuilder }

constructor TApplicationBuilder.Create(AServiceProvider: IServiceProvider);
begin
  inherited Create;
  FServiceProvider := AServiceProvider;
  FMiddlewares := TList<TMiddlewareRegistration>.Create;
  FMappedRoutes := TDictionary<string, TRequestDelegate>.Create;
  FRoutePatterns := TDictionary<TRoutePattern, TRequestDelegate>.Create;
end;

destructor TApplicationBuilder.Destroy;
var
  RoutePattern: TRoutePattern;
begin
  FMiddlewares.Free;
  FMappedRoutes.Free;
  for RoutePattern in FRoutePatterns.Keys do
    RoutePattern.Free;
  FRoutePatterns.Free;
  inherited Destroy;
end;

function TApplicationBuilder.GetServiceProvider: IServiceProvider;
begin
  Result := FServiceProvider;
end;

function TApplicationBuilder.UseMiddleware(AMiddleware: TClass; const AParam: TValue): IApplicationBuilder;
var
  Registration: TMiddlewareRegistration;
begin
  if not AMiddleware.InheritsFrom(TMiddleware) then
    raise EArgumentException.Create('Middleware must inherit from TMiddleware');

  Registration.MiddlewareClass := AMiddleware;
  SetLength(Registration.Parameters, 1);
  Registration.Parameters[0] := AParam;

  FMiddlewares.Add(Registration);

  Writeln('✅ MIDDLEWARE REGISTERED: ', AMiddleware.ClassName);
  if not AParam.IsEmpty then
    Writeln('   With parameter type: ', AParam.TypeInfo.Name);

  Result := Self;
end;

function TApplicationBuilder.UseMiddleware(AMiddleware: TClass; const AParams: array of TValue): IApplicationBuilder;
var
  Registration: TMiddlewareRegistration;
  I: Integer;
begin
  if not AMiddleware.InheritsFrom(TMiddleware) then
    raise EArgumentException.Create('Middleware must inherit from TMiddleware');

  Registration.MiddlewareClass := AMiddleware;
  SetLength(Registration.Parameters, Length(AParams));

  for I := 0 to High(AParams) do
    Registration.Parameters[I] := AParams[I];

  FMiddlewares.Add(Registration);
  Result := Self;
end;

function TApplicationBuilder.UseModelBinding: IApplicationBuilder;
begin
  // Por enquanto apenas retorna self - podemos adicionar configurações futuras
  // como opções de binding, validadores, etc.
  Result := Self;
end;

function TApplicationBuilder.CreateMiddlewareInstance(AMiddlewareClass: TClass;
  const AParameters: TArray<TValue>): IMiddleware;
var
  Instance: TObject;
  Context: TRttiContext;
  InstanceType: TRttiType;
  ConstructorMethod: TRttiMethod;
  Parameters: TArray<TRttiParameter>;
  Arguments: TArray<TValue>;
  I: Integer;
begin
  // Se não há parâmetros, criar instância normalmente
  if Length(AParameters) = 0 then
  begin
    Instance := AMiddlewareClass.Create;
    if not Supports(Instance, IMiddleware, Result) then
    begin
      Instance.Free;
      raise EArgumentException.Create('Middleware class must implement IMiddleware');
    end;
    Exit;
  end;

  // ✅ NOVO: Criar instância com parâmetros via RTTI
  Context := TRttiContext.Create;
  try
    InstanceType := Context.GetType(AMiddlewareClass);

    // Encontrar construtor que aceite os parâmetros
    for ConstructorMethod in InstanceType.GetMethods do
    begin
      if ConstructorMethod.IsConstructor then
      begin
        Parameters := ConstructorMethod.GetParameters;

        if Length(Parameters) = Length(AParameters) then
        begin
          // Verificar compatibilidade de tipos
          var Compatible := True;
          for I := 0 to High(Parameters) do
          begin
            if not AParameters[I].IsObject and (AParameters[I].TypeInfo <> Parameters[I].ParamType.Handle) then
            begin
              Compatible := False;
              Break;
            end;
          end;

          if Compatible then
          begin
            Arguments := AParameters;
            Instance := ConstructorMethod.Invoke(AMiddlewareClass, Arguments).AsObject;

            if Supports(Instance, IMiddleware, Result) then
              Exit
            else
            begin
              Instance.Free;
              raise EArgumentException.Create('Middleware class must implement IMiddleware');
            end;
          end;
        end;
      end;
    end;

    // Se não encontrou construtor compatível, erro
    raise EArgumentException.Create('No compatible constructor found for middleware with given parameters');

  finally
    Context.Free;
  end;
end;

function TApplicationBuilder.UseMiddleware(AMiddleware: TClass): IApplicationBuilder;
var
  Registration: TMiddlewareRegistration; // ✅ USAR O NOVO RECORD
begin
  if not AMiddleware.InheritsFrom(TMiddleware) then
    raise EArgumentException.Create('Middleware must inherit from TMiddleware');

  // ✅ CRIAR REGISTRATION SEM PARÂMETROS
  Registration.MiddlewareClass := AMiddleware;
  SetLength(Registration.Parameters, 0); // Array vazio

  FMiddlewares.Add(Registration);
  Result := Self;
end;

function TApplicationBuilder.Map(const APath: string;
  ADelegate: TRequestDelegate): IApplicationBuilder;
begin
  // ✅ Detecção automática: padrão com parâmetros ou rota fixa?
  if APath.Contains('{') and APath.Contains('}') then
  begin
    // Padrão com parâmetros: /users/{id}, /posts/{year}/{month}
    var RoutePattern := TRoutePattern.Create(APath);
    FRoutePatterns.Add(RoutePattern, ADelegate);

    Writeln(Format('Registered route pattern: %s', [APath]));
    Writeln(Format('  Parameters: %s', [string.Join(', ', RoutePattern.ParameterNames)]));
  end
  else
  begin
    // Rota fixa: /api/users, /hello
    FMappedRoutes.AddOrSetValue(APath, ADelegate);
    Writeln(Format('Registered fixed route: %s', [APath]));
  end;


  Result := Self;
end;

function TApplicationBuilder.MapGet(const Path: string; Handler: TProc<IHttpContext>): IApplicationBuilder;
begin
  WriteLn('📍 REGISTERING GET: ', Path);

  // ✅ USAR INVOKER BÁSICO
  Result := Map(Path,
    procedure(Context: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      Binder := TModelBinder.Create(FServiceProvider);
      Invoker := THandlerInvoker.Create(Context, Binder);
      try
        Invoker.Invoke(Handler);
      finally
        Invoker.Free;
      end;
    end
  );
end;



function TApplicationBuilder.MapPost(const Path: string; Handler: TProc<IHttpContext>): IApplicationBuilder;
begin
  WriteLn('📍 REGISTERING POST: ', Path);

  Result := Map(Path,
    procedure(Context: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      Binder := TModelBinder.Create(FServiceProvider);
      Invoker := THandlerInvoker.Create(Context, Binder);
      try
        Invoker.Invoke(Handler);
      finally
        Invoker.Free;
      end;
    end
  );
end;

function TApplicationBuilder.CreateMiddlewarePipeline(const ARegistration: TMiddlewareRegistration;
  ANext: TRequestDelegate): TRequestDelegate;
begin
  Result :=
    procedure(AContext: IHttpContext)
    var
      MiddlewareInstance: IMiddleware;
    begin
      MiddlewareInstance := CreateMiddlewareInstance(
        ARegistration.MiddlewareClass, ARegistration.Parameters);
      try
        MiddlewareInstance.Invoke(AContext, ANext);
      finally
        // Cleanup se necessário
      end;
    end;
end;

function TApplicationBuilder.Build: TRequestDelegate;
var
  FinalPipeline: TRequestDelegate;
begin
  // Pipeline final - retorna 404
  FinalPipeline :=
    procedure(AContext: IHttpContext)
    begin
      AContext.Response.StatusCode := 404;
      AContext.Response.Write('Not Found');
    end;

  // ✅ CRIAR RouteMatcher (interface - auto-gerenciável)
  var RouteMatcher: IRouteMatcher :=
    TRouteMatcher.Create(FMappedRoutes, FRoutePatterns);

  // ✅ CRIAR RoutingMiddleware com a interface
  var RoutingMiddleware := TRoutingMiddleware.Create(RouteMatcher);

  var RoutingHandler: TRequestDelegate :=
    procedure(Ctx: IHttpContext)
    begin
      RoutingMiddleware.Invoke(Ctx, FinalPipeline);
    end;

  // Construir pipeline: outros middlewares → roteamento → 404
  for var I := FMiddlewares.Count - 1 downto 0 do
  begin
    RoutingHandler := CreateMiddlewarePipeline(FMiddlewares[I], RoutingHandler);
  end;

  Result := RoutingHandler;
end;
end.
