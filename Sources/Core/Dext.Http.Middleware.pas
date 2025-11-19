// Dext.Http.Middleware.pas
unit Dext.Http.Middleware;

interface

uses
  Dext.Http.Core,
  Dext.Http.Interfaces;

type
  // Middleware de logging
  TLoggingMiddleware = class(TMiddleware)
  public
    procedure Invoke(AContext: IHttpContext; ANext: TRequestDelegate); override;
  end;

  // Middleware de tratamento de exceções
  TExceptionHandlingMiddleware = class(TMiddleware)
  public
    procedure Invoke(AContext: IHttpContext; ANext: TRequestDelegate); override;
  end;

implementation

uses
  System.SysUtils;

{ TLoggingMiddleware }

procedure TLoggingMiddleware.Invoke(AContext: IHttpContext; ANext: TRequestDelegate);
begin
  // Log antes do request
  Writeln(Format('[%s] %s %s', [
    DateTimeToStr(Now),
    AContext.Request.Method,
    AContext.Request.Path
  ]));

  try
    // Chamar próximo middleware
    ANext(AContext);
  finally
    // Log após o request
    Writeln('Request completed');
  end;
end;

{ TExceptionHandlingMiddleware }

procedure TExceptionHandlingMiddleware.Invoke(AContext: IHttpContext; ANext: TRequestDelegate);
begin
  try
    ANext(AContext);
  except
    on E: Exception do
    begin
      AContext.Response.StatusCode := 500;
      AContext.Response.Write('Internal Server Error: ' + E.Message);
    end;
  end;
end;

end.
