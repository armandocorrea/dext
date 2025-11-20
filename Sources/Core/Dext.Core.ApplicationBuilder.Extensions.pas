unit Dext.Core.ApplicationBuilder.Extensions;

interface

uses
  System.SysUtils,
  Dext.Http.Interfaces,
  Dext.Core.HandlerInvoker,
  Dext.Core.ModelBinding;

type
  TApplicationBuilderExtensions = class
  public
    class function MapPost<T>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T>): IApplicationBuilder; overload;
      
    class function MapPost<T1, T2>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T1, T2>): IApplicationBuilder; overload;

    class function MapPost<T1, T2, T3>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T1, T2, T3>): IApplicationBuilder; overload;

    class function MapGet<T>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T>): IApplicationBuilder; overload;
      
    class function MapGet<T1, T2>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T1, T2>): IApplicationBuilder; overload;

    class function MapGet<T1, T2, T3>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T1, T2, T3>): IApplicationBuilder; overload;

    class function MapPut<T>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T>): IApplicationBuilder; overload;
      
    class function MapPut<T1, T2>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T1, T2>): IApplicationBuilder; overload;

    class function MapPut<T1, T2, T3>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T1, T2, T3>): IApplicationBuilder; overload;

    class function MapDelete<T>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T>): IApplicationBuilder; overload;
      
    class function MapDelete<T1, T2>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T1, T2>): IApplicationBuilder; overload;

    class function MapDelete<T1, T2, T3>(App: IApplicationBuilder; const Path: string; 
      Handler: THandlerProc<T1, T2, T3>): IApplicationBuilder; overload;
  end;

implementation

{ TApplicationBuilderExtensions }

class function TApplicationBuilderExtensions.MapPost<T>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T>): IApplicationBuilder;
begin
  Result := App.MapPost(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      // Criar ModelBinder
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

class function TApplicationBuilderExtensions.MapPost<T1, T2>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T1, T2>): IApplicationBuilder;
begin
  Result := App.MapPost(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T1, T2>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

class function TApplicationBuilderExtensions.MapPost<T1, T2, T3>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T1, T2, T3>): IApplicationBuilder;
begin
  Result := App.MapPost(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T1, T2, T3>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

class function TApplicationBuilderExtensions.MapGet<T>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T>): IApplicationBuilder;
begin
  Result := App.MapGet(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

class function TApplicationBuilderExtensions.MapGet<T1, T2>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T1, T2>): IApplicationBuilder;
begin
  Result := App.MapGet(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T1, T2>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

class function TApplicationBuilderExtensions.MapGet<T1, T2, T3>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T1, T2, T3>): IApplicationBuilder;
begin
  Result := App.MapGet(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T1, T2, T3>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

class function TApplicationBuilderExtensions.MapPut<T>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T>): IApplicationBuilder;
begin
  Result := App.Map(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      if Ctx.Request.Method <> 'PUT' then Exit;
      
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

class function TApplicationBuilderExtensions.MapPut<T1, T2>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T1, T2>): IApplicationBuilder;
begin
  Result := App.Map(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      if Ctx.Request.Method <> 'PUT' then Exit;
      
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T1, T2>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

class function TApplicationBuilderExtensions.MapPut<T1, T2, T3>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T1, T2, T3>): IApplicationBuilder;
begin
  Result := App.Map(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      if Ctx.Request.Method <> 'PUT' then Exit;
      
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T1, T2, T3>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

class function TApplicationBuilderExtensions.MapDelete<T>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T>): IApplicationBuilder;
begin
  Result := App.Map(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      if Ctx.Request.Method <> 'DELETE' then Exit;
      
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

class function TApplicationBuilderExtensions.MapDelete<T1, T2>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T1, T2>): IApplicationBuilder;
begin
  Result := App.Map(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      if Ctx.Request.Method <> 'DELETE' then Exit;
      
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T1, T2>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

class function TApplicationBuilderExtensions.MapDelete<T1, T2, T3>(App: IApplicationBuilder; 
  const Path: string; Handler: THandlerProc<T1, T2, T3>): IApplicationBuilder;
begin
  Result := App.Map(Path, 
    procedure(Ctx: IHttpContext)
    var
      Invoker: THandlerInvoker;
      Binder: IModelBinder;
    begin
      if Ctx.Request.Method <> 'DELETE' then Exit;
      
      Binder := TModelBinder.Create;
      Invoker := THandlerInvoker.Create(Ctx, Binder);
      try
        Invoker.Invoke<T1, T2, T3>(Handler);
      finally
        Invoker.Free;
      end;
    end);
end;

end.
