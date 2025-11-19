// Dext.AppBuilderTest.dpr - Versão Corrigida
program Dext.AppBuilderTest;

uses
  System.Classes,
  System.SysUtils,
  Dext.DI.Interfaces,
  Dext.Http.Interfaces,
  Dext.Http.Core,
  Dext.Http.Middleware;

{$APPTYPE CONSOLE}

{$R *.res}

// Mocks atualizados
type
  TMockHttpContext = class(TInterfacedObject, IHttpContext)
  private
    FRequest: IHttpRequest;
    FResponse: IHttpResponse;
  public
    constructor Create(const AMethod, APath: string);
    function GetRequest: IHttpRequest;
    function GetResponse: IHttpResponse;
    function GetServices: IServiceProvider;
  end;

  TMockHttpRequest = class(TInterfacedObject, IHttpRequest)
  private
    FMethod: string;
    FPath: string;
    FQuery: TStrings;
  public
    constructor Create(const AMethod, APath: string);
    destructor Destroy; override;
    function GetMethod: string;
    function GetPath: string;
    function GetQuery: TStrings;
    function GetBody: TStream;
  end;

  TMockHttpResponse = class(TInterfacedObject, IHttpResponse)
  private
    FStatusCode: Integer;
    FContent: string;
  public
    procedure SetStatusCode(AValue: Integer);
    procedure SetContentType(const AValue: string);
    procedure Write(const AContent: string);
    procedure Json(const AJson: string);
  end;

{ TMockHttpContext }

constructor TMockHttpContext.Create(const AMethod, APath: string);
begin
  inherited Create;
  FRequest := TMockHttpRequest.Create(AMethod, APath);
  FResponse := TMockHttpResponse.Create;
end;

function TMockHttpContext.GetRequest: IHttpRequest;
begin
  Result := FRequest;
end;

function TMockHttpContext.GetResponse: IHttpResponse;
begin
  Result := FResponse;
end;

function TMockHttpContext.GetServices: IServiceProvider;
begin
  Result := nil;
end;

{ TMockHttpRequest }

constructor TMockHttpRequest.Create(const AMethod, APath: string);
begin
  inherited Create;
  FMethod := AMethod;
  FPath := APath;
  FQuery := TStringList.Create;
end;

destructor TMockHttpRequest.Destroy;
begin
  FQuery.Free;
  inherited Destroy;
end;

function TMockHttpRequest.GetMethod: string;
begin
  Result := FMethod;
end;

function TMockHttpRequest.GetPath: string;
begin
  Result := FPath;
end;

function TMockHttpRequest.GetQuery: TStrings;
begin
  Result := FQuery;
end;

function TMockHttpRequest.GetBody: TStream;
begin
  Result := nil;
end;

{ TMockHttpResponse }

procedure TMockHttpResponse.SetStatusCode(AValue: Integer);
begin
  FStatusCode := AValue;
end;

procedure TMockHttpResponse.SetContentType(const AValue: string);
begin
  // Implementação simplificada
end;

procedure TMockHttpResponse.Write(const AContent: string);
begin
  FContent := AContent;
  Writeln('Response: ', AContent);
end;

procedure TMockHttpResponse.Json(const AJson: string);
begin
  SetContentType('application/json');
  Write(AJson);
end;

var
  AppBuilder: IApplicationBuilder;
  Pipeline: TRequestDelegate;
  Context: IHttpContext;
begin
  try
    Writeln('=== Testing ApplicationBuilder ===');

    // Criar application builder
    AppBuilder := TApplicationBuilder.Create;

    // Configurar pipeline
    AppBuilder
      .UseMiddleware(TExceptionHandlingMiddleware)
      .UseMiddleware(TLoggingMiddleware)
      .Map('/hello',
        procedure(Context: IHttpContext)
        begin
          Context.Response.Write('Hello from Dext ApplicationBuilder!');
        end)
      .Map('/time',
        procedure(Context: IHttpContext)
        begin
          Context.Response.Write('Server time: ' + DateTimeToStr(Now));
        end);

    // Construir pipeline
    Pipeline := AppBuilder.Build;

    // Testar requests
    Writeln('');
    Writeln('Testing /hello route:');
    Context := TMockHttpContext.Create('GET', '/hello');
    Pipeline(Context);

    Writeln('');
    Writeln('Testing /time route:');
    Context := TMockHttpContext.Create('GET', '/time');
    Pipeline(Context);

    Writeln('');
    Writeln('Testing unknown route:');
    Context := TMockHttpContext.Create('GET', '/unknown');
    Pipeline(Context);

    Writeln('');
    Writeln('=== All tests completed ===');

  except
    on E: Exception do
      Writeln('ERROR: ', E.ClassName, ': ', E.Message);
  end;

  Writeln('Press Enter to exit...');
  Readln;
end.
