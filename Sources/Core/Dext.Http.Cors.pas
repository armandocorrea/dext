unit Dext.Http.Cors;

interface

uses
  System.SysUtils,
  System.Rtti,
  Dext.Http.Core,
  Dext.Http.Interfaces;

type
  TCorsOptions = record
  public
    AllowedOrigins: TArray<string>;
    AllowedMethods: TArray<string>;
    AllowedHeaders: TArray<string>;
    ExposedHeaders: TArray<string>;
    AllowCredentials: Boolean;
    MaxAge: Integer;

    class function Create: TCorsOptions; static;
  end;

  TStringArrayHelper = record helper for TArray<string>
  public
    function Contains(const AValue: string): Boolean;
    function IsEmpty: Boolean;
  end;

  TCorsMiddleware = class(TMiddleware)
  private
    FOptions: TCorsOptions;
    procedure AddCorsHeaders(AContext: IHttpContext);
    function IsOriginAllowed(const AOrigin: string): Boolean;
  public
    constructor Create; overload;
    constructor Create(const AOptions: TCorsOptions); overload;
    procedure Invoke(AContext: IHttpContext; ANext: TRequestDelegate); override;
  end;

  TCorsBuilder = class
  private
    FOptions: TCorsOptions;
  public
    function WithOrigins(const AOrigins: array of string): TCorsBuilder;
    function AllowAnyOrigin: TCorsBuilder;
    function WithMethods(const AMethods: array of string): TCorsBuilder;
    function AllowAnyMethod: TCorsBuilder;
    function WithHeaders(const AHeaders: array of string): TCorsBuilder;
    function AllowAnyHeader: TCorsBuilder;
    function WithExposedHeaders(const AHeaders: array of string): TCorsBuilder;
    function AllowCredentials: TCorsBuilder;
    function WithMaxAge(ASeconds: Integer): TCorsBuilder;

    function Build: TCorsOptions;
  end;

  TApplicationBuilderCorsExtensions = class
  public
    class function UseCors(const ABuilder: IApplicationBuilder): IApplicationBuilder; overload; static;
    class function UseCors(const ABuilder: IApplicationBuilder; const AOptions: TCorsOptions): IApplicationBuilder; overload; static;
    class function UseCors(const ABuilder: IApplicationBuilder; AConfigurator: TProc<TCorsBuilder>): IApplicationBuilder; overload; static;
  end;

  TCorsOptionsHelper = record helper for TCorsOptions
  public
    class operator Implicit(const AValue: TCorsOptions): TValue;
  end;

implementation


{ TStringArrayHelper }

function TStringArrayHelper.Contains(const AValue: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to High(Self) do
  begin
    if Self[I] = AValue then
      Exit(True);
  end;
  Result := False;
end;

function TStringArrayHelper.IsEmpty: Boolean;
begin
  Result := Length(Self) = 0;
end;

{ TCorsOptions }

class function TCorsOptions.Create: TCorsOptions;
begin
  Result.AllowedOrigins := [];
  Result.AllowedMethods := ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'];
  Result.AllowedHeaders := ['Content-Type', 'Authorization'];
  Result.ExposedHeaders := [];
  Result.AllowCredentials := False;
  Result.MaxAge := 0;
end;

{ TCorsMiddleware }

constructor TCorsMiddleware.Create;
begin
  inherited Create;
  FOptions := TCorsOptions.Create;
end;

// ✅ NOVO: Construtor com parâmetros
constructor TCorsMiddleware.Create(const AOptions: TCorsOptions);
begin
  inherited Create;
  FOptions := AOptions;
end;

procedure TCorsMiddleware.Invoke(AContext: IHttpContext; ANext: TRequestDelegate);
var
  Headers: TArray<string>;
  I: Integer;
begin
  Writeln('🚀 CORS MIDDLEWARE STARTED');
  Writeln('📨 Request: ', AContext.Request.Method, ' ', AContext.Request.Path);

  // Debug: ver todos os headers da request
  Writeln('📋 Request Headers:');
  Headers := AContext.Request.Headers.Keys.ToArray;
  for I := 0 to High(Headers) do
  begin
    Writeln('   ', Headers[I], ': ', AContext.Request.Headers[Headers[I]]);
  end;

  // ✅ ADICIONAR HEADERS CORS
  AddCorsHeaders(AContext);

  // Debug: ver headers que foram adicionados
  Writeln('✅ CORS Headers added (checking response)...');

  // Se for preflight OPTIONS
  if AContext.Request.Method = 'OPTIONS' then
  begin
    Writeln('🛬 CORS: Handling OPTIONS preflight');
    AContext.Response.StatusCode := 204; // No Content
    AContext.Response.SetContentType('text/plain');
    Writeln('🛑 CORS: Stopping pipeline for OPTIONS');
    Exit;
  end;

  Writeln('➡️ CORS: Continuing to next middleware');
  ANext(AContext);
  Writeln('🏁 CORS MIDDLEWARE FINISHED');
end;

procedure TCorsMiddleware.AddCorsHeaders(AContext: IHttpContext);
var
  Origin: string;
  RequestOrigin: string;
begin
  Writeln('🎯 AddCorsHeaders called');

  // ✅ Obter Origin do request
  if AContext.Request.Headers.TryGetValue('origin', RequestOrigin) then
  begin
    Origin := RequestOrigin;
    Writeln('📍 Origin found: ', Origin);
  end
  else
  begin
    Origin := '';
    Writeln('📍 No Origin header');
  end;

  // Verificar se origin é permitida
  if IsOriginAllowed(Origin) then
  begin
    Writeln('✅ Origin allowed, adding CORS headers');

    // ✅ ADICIONAR HEADERS CORS
    AContext.Response.AddHeader('Access-Control-Allow-Origin', Origin);
    Writeln('   Added: Access-Control-Allow-Origin: ', Origin);

    if FOptions.AllowCredentials then
    begin
      AContext.Response.AddHeader('Access-Control-Allow-Credentials', 'true');
      Writeln('   Added: Access-Control-Allow-Credentials: true');
    end;

    if Length(FOptions.ExposedHeaders) > 0 then
    begin
      AContext.Response.AddHeader('Access-Control-Expose-Headers',
        string.Join(', ', FOptions.ExposedHeaders));
      Writeln('   Added: Access-Control-Expose-Headers: ',
        string.Join(', ', FOptions.ExposedHeaders));
    end;
  end
  else if FOptions.AllowedOrigins.Contains('*') then
  begin
    Writeln('✅ Wildcard enabled, adding CORS headers');
    AContext.Response.AddHeader('Access-Control-Allow-Origin', '*');
    Writeln('   Added: Access-Control-Allow-Origin: *');
  end
  else
  begin
    Writeln('❌ Origin not allowed: ', Origin);
  end;

  // Headers para preflight requests
  if AContext.Request.Method = 'OPTIONS' then
  begin
    Writeln('🛬 Adding preflight headers');

    if Length(FOptions.AllowedMethods) > 0 then
    begin
      AContext.Response.AddHeader('Access-Control-Allow-Methods',
        string.Join(', ', FOptions.AllowedMethods));
      Writeln('   Added: Access-Control-Allow-Methods: ',
        string.Join(', ', FOptions.AllowedMethods));
    end;

    if Length(FOptions.AllowedHeaders) > 0 then
    begin
      AContext.Response.AddHeader('Access-Control-Allow-Headers',
        string.Join(', ', FOptions.AllowedHeaders));
      Writeln('   Added: Access-Control-Allow-Headers: ',
        string.Join(', ', FOptions.AllowedHeaders));
    end;

    if FOptions.MaxAge > 0 then
    begin
      AContext.Response.AddHeader('Access-Control-Max-Age',
        IntToStr(FOptions.MaxAge));
      Writeln('   Added: Access-Control-Max-Age: ', FOptions.MaxAge);
    end;
  end;

  Writeln('🎯 AddCorsHeaders finished');
end;

function TCorsMiddleware.IsOriginAllowed(const AOrigin: string): Boolean;
begin
  if FOptions.AllowedOrigins.Contains('*') then
    Exit(True);

  if AOrigin.IsEmpty then
    Exit(False);

  Result := FOptions.AllowedOrigins.Contains(AOrigin);
end;

{ TCorsBuilder }

function TCorsBuilder.AllowAnyHeader: TCorsBuilder;
begin
  FOptions.AllowedHeaders := ['*'];
  Result := Self;
end;

function TCorsBuilder.AllowAnyMethod: TCorsBuilder;
begin
  FOptions.AllowedMethods := ['*'];
  Result := Self;
end;

function TCorsBuilder.AllowAnyOrigin: TCorsBuilder;
begin
  FOptions.AllowedOrigins := ['*'];
  Result := Self;
end;

function TCorsBuilder.AllowCredentials: TCorsBuilder;
begin
  FOptions.AllowCredentials := True;
  Result := Self;
end;

function TCorsBuilder.Build: TCorsOptions;
begin
  Result := FOptions;
end;

function TCorsBuilder.WithExposedHeaders(const AHeaders: array of string): TCorsBuilder;
var
  I: Integer;
begin
  SetLength(FOptions.ExposedHeaders, Length(AHeaders));
  for I := 0 to High(AHeaders) do
    FOptions.ExposedHeaders[I] := AHeaders[I];
  Result := Self;
end;

function TCorsBuilder.WithHeaders(const AHeaders: array of string): TCorsBuilder;
var
  I: Integer;
begin
  SetLength(FOptions.AllowedHeaders, Length(AHeaders));
  for I := 0 to High(AHeaders) do
    FOptions.AllowedHeaders[I] := AHeaders[I];
  Result := Self;
end;

function TCorsBuilder.WithMaxAge(ASeconds: Integer): TCorsBuilder;
begin
  FOptions.MaxAge := ASeconds;
  Result := Self;
end;

function TCorsBuilder.WithMethods(const AMethods: array of string): TCorsBuilder;
var
  I: Integer;
begin
  SetLength(FOptions.AllowedMethods, Length(AMethods));
  for I := 0 to High(AMethods) do
    FOptions.AllowedMethods[I] := AMethods[I];
  Result := Self;
end;

function TCorsBuilder.WithOrigins(const AOrigins: array of string): TCorsBuilder;
var
  I: Integer;
begin
  SetLength(FOptions.AllowedOrigins, Length(AOrigins));
  for I := 0 to High(AOrigins) do
    FOptions.AllowedOrigins[I] := AOrigins[I];
  Result := Self;
end;

{ TApplicationBuilderCorsExtensions }

class function TApplicationBuilderCorsExtensions.UseCors(
  const ABuilder: IApplicationBuilder): IApplicationBuilder;
begin
  Result := ABuilder.UseMiddleware(TCorsMiddleware, TCorsOptions.Create);
end;

class function TApplicationBuilderCorsExtensions.UseCors(
  const ABuilder: IApplicationBuilder; const AOptions: TCorsOptions): IApplicationBuilder;
begin
  Result := ABuilder.UseMiddleware(TCorsMiddleware, AOptions);
end;

class function TApplicationBuilderCorsExtensions.UseCors(
  const ABuilder: IApplicationBuilder; AConfigurator: TProc<TCorsBuilder>): IApplicationBuilder;
var
  Builder: TCorsBuilder;
  Options: TCorsOptions;
begin
  Builder := TCorsBuilder.Create;
  try
    if Assigned(AConfigurator) then
      AConfigurator(Builder);
    Options := Builder.Build;
  finally
    Builder.Free;
  end;

  Result := ABuilder.UseMiddleware(TCorsMiddleware, Options);
end;

{ TCorsOptionsHelper }

class operator TCorsOptionsHelper.Implicit(const AValue: TCorsOptions): TValue;
begin
  Result := TValue.From<TCorsOptions>(AValue);
end;

end.
