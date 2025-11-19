unit Dext.Core.HandlerInvoker;

interface

uses
  System.SysUtils,
  System.Rtti,
  System.TypInfo,
  Dext.Http.Interfaces,
  Dext.Core.Controllers,
  Dext.Core.ModelBinding;

type
  { Invoker básico - FASE 1.1 }
  // Definição de tipos de handlers genéricos
  THandlerProc<T> = reference to procedure(Arg1: T);
  THandlerProc<T1, T2> = reference to procedure(Arg1: T1; Arg2: T2);
  THandlerProc<T1, T2, T3> = reference to procedure(Arg1: T1; Arg2: T2; Arg3: T3);

  THandlerInvoker = class
  private
    FModelBinder: IModelBinder;
    FContext: IHttpContext;
  public
    constructor Create(AContext: IHttpContext; AModelBinder: IModelBinder);

    // Invocação estática (legado/simples)
    function Invoke(AHandler: TStaticHandler): Boolean; overload;

    // Invocação genérica com 1 argumento
    function Invoke<T>(AHandler: THandlerProc<T>): Boolean; overload;

    // Invocação genérica com 2 argumentos
    function Invoke<T1, T2>(AHandler: THandlerProc<T1, T2>): Boolean; overload;
    
    // Invocação genérica com 3 argumentos
    function Invoke<T1, T2, T3>(AHandler: THandlerProc<T1, T2, T3>): Boolean; overload;
  end;

implementation

{ THandlerInvoker }

{ THandlerInvoker }

constructor THandlerInvoker.Create(AContext: IHttpContext; AModelBinder: IModelBinder);
begin
  inherited Create;
  FContext := AContext;
  FModelBinder := AModelBinder;
end;

function THandlerInvoker.Invoke(AHandler: TStaticHandler): Boolean;
begin
  try
    AHandler(FContext);
    Result := True;
  except
    on E: Exception do
    begin
      // Log error here if needed
      if FContext.Response <> nil then
      begin
        FContext.Response.StatusCode := 500;
        FContext.Response.Json(Format('{"error": "Handler execution failed", "details": "%s"}', [E.Message]));
      end;
      Result := False;
    end;
  end;
end;

function THandlerInvoker.Invoke<T>(AHandler: THandlerProc<T>): Boolean;
var
  Arg1: T;
begin
  try
    // Resolver argumento usando ModelBinder
    // O ModelBinder precisa ser capaz de resolver baseado no tipo T e no contexto
    // Como não temos atributos no parametro do delegate (limitação do Delphi),
    // assumimos que o ModelBinder vai inferir a fonte (Body para records complexos, Query/Route para simples, Services para interfaces)
    // OU precisamos de uma estratégia de "Binding Context" mais elaborada.
    
    // Por enquanto, vamos usar uma estratégia simplificada de inferência:
    // Se T é record -> Tenta BindBody
    // Se falhar ou não for record -> Tenta BindServices se for interface
    
    // Melhor abordagem: Usar o TModelBinderHelper que pode ter lógicas de "Smart Bind"
    // Mas como o ModelBinder já tem métodos genéricos (que vamos implementar/usar), vamos tentar usá-los.
    
    // HACK: Como não podemos decorar os argumentos do método anônimo com atributos [FromBody],
    // a estratégia de binding tem que ser baseada no TIPO.
    
    // 1. Verificar se é IHttpContext
    if TypeInfo(T) = TypeInfo(IHttpContext) then
      Arg1 := TValue.From<IHttpContext>(FContext).AsType<T>
    // 2. Records -> Body
    else if PTypeInfo(TypeInfo(T)).Kind = tkRecord then
      Arg1 := TModelBinderHelper.BindBody<T>(FModelBinder, FContext)
    // 3. Interfaces -> Services
    else if PTypeInfo(TypeInfo(T)).Kind = tkInterface then
      Arg1 := FModelBinder.BindServices(TypeInfo(T), FContext).AsType<T>
    // 4. Fallback -> Query
    else
      Arg1 := TModelBinderHelper.BindQuery<T>(FModelBinder, FContext);

    AHandler(Arg1);
    Result := True;
  except
    on E: Exception do
    begin
      if FContext.Response <> nil then
      begin
        FContext.Response.StatusCode := 500;
        FContext.Response.Json(Format('{"error": "Handler invocation failed", "details": "%s"}', [E.Message]));
      end;
      Result := False;
    end;
  end;
end;

function THandlerInvoker.Invoke<T1, T2>(AHandler: THandlerProc<T1, T2>): Boolean;
var
  Arg1: T1;
  Arg2: T2;
begin
  try
    // Argumento 1
    if TypeInfo(T1) = TypeInfo(IHttpContext) then
      Arg1 := TValue.From<IHttpContext>(FContext).AsType<T1>
    else if PTypeInfo(TypeInfo(T1)).Kind = tkRecord then
      Arg1 := TModelBinderHelper.BindBody<T1>(FModelBinder, FContext)
    else if PTypeInfo(TypeInfo(T1)).Kind = tkInterface then
      Arg1 := FModelBinder.BindServices(TypeInfo(T1), FContext).AsType<T1>
    else
      Arg1 := TModelBinderHelper.BindQuery<T1>(FModelBinder, FContext);

    // Argumento 2
    if TypeInfo(T2) = TypeInfo(IHttpContext) then
      Arg2 := TValue.From<IHttpContext>(FContext).AsType<T2>
    else if PTypeInfo(TypeInfo(T2)).Kind = tkRecord then
      Arg2 := TModelBinderHelper.BindBody<T2>(FModelBinder, FContext)
    else if PTypeInfo(TypeInfo(T2)).Kind = tkInterface then
      Arg2 := FModelBinder.BindServices(TypeInfo(T2), FContext).AsType<T2>
    else
      Arg2 := TModelBinderHelper.BindQuery<T2>(FModelBinder, FContext);

    AHandler(Arg1, Arg2);
    Result := True;
  except
    on E: Exception do
    begin
      if FContext.Response <> nil then
      begin
        FContext.Response.StatusCode := 500;
        FContext.Response.Json(Format('{"error": "Handler invocation failed", "details": "%s"}', [E.Message]));
      end;
      Result := False;
    end;
  end;
end;

function THandlerInvoker.Invoke<T1, T2, T3>(AHandler: THandlerProc<T1, T2, T3>): Boolean;
var
  Arg1: T1;
  Arg2: T2;
  Arg3: T3;
begin
  try
    // Argumento 1
    if TypeInfo(T1) = TypeInfo(IHttpContext) then
      Arg1 := TValue.From<IHttpContext>(FContext).AsType<T1>
    else if PTypeInfo(TypeInfo(T1)).Kind = tkRecord then
      Arg1 := TModelBinderHelper.BindBody<T1>(FModelBinder, FContext)
    else if PTypeInfo(TypeInfo(T1)).Kind = tkInterface then
      Arg1 := FModelBinder.BindServices(TypeInfo(T1), FContext).AsType<T1>
    else
      Arg1 := TModelBinderHelper.BindQuery<T1>(FModelBinder, FContext);

    // Argumento 2
    if TypeInfo(T2) = TypeInfo(IHttpContext) then
      Arg2 := TValue.From<IHttpContext>(FContext).AsType<T2>
    else if PTypeInfo(TypeInfo(T2)).Kind = tkRecord then
      Arg2 := TModelBinderHelper.BindBody<T2>(FModelBinder, FContext)
    else if PTypeInfo(TypeInfo(T2)).Kind = tkInterface then
      Arg2 := FModelBinder.BindServices(TypeInfo(T2), FContext).AsType<T2>
    else
      Arg2 := TModelBinderHelper.BindQuery<T2>(FModelBinder, FContext);

    // Argumento 3
    if TypeInfo(T3) = TypeInfo(IHttpContext) then
      Arg3 := TValue.From<IHttpContext>(FContext).AsType<T3>
    else if PTypeInfo(TypeInfo(T3)).Kind = tkRecord then
      Arg3 := TModelBinderHelper.BindBody<T3>(FModelBinder, FContext)
    else if PTypeInfo(TypeInfo(T3)).Kind = tkInterface then
      Arg3 := FModelBinder.BindServices(TypeInfo(T3), FContext).AsType<T3>
    else
      Arg3 := TModelBinderHelper.BindQuery<T3>(FModelBinder, FContext);

    AHandler(Arg1, Arg2, Arg3);
    Result := True;
  except
    on E: Exception do
    begin
      if FContext.Response <> nil then
      begin
        FContext.Response.StatusCode := 500;
        FContext.Response.Json(Format('{"error": "Handler invocation failed", "details": "%s"}', [E.Message]));
      end;
      Result := False;
    end;
  end;
end;

end.
