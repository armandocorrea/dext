unit Dext.Http.Middleware.Logging;

interface

uses
  System.SysUtils,
  Dext.Http.Core,
  Dext.Http.Interfaces;

type
  TRequestLoggingMiddleware = class(TMiddleware)
  public
    procedure Invoke(AContext: IHttpContext; ANext: TRequestDelegate); override;
  end;

implementation

{ TRequestLoggingMiddleware }

procedure TRequestLoggingMiddleware.Invoke(AContext: IHttpContext; ANext: TRequestDelegate);
var
  Method, Path: string;
begin
  Method := AContext.Request.Method;
  Path := AContext.Request.Path;
  
  WriteLn(Format('📝 [REQ] %s %s', [Method, Path]));
  
  try
    ANext(AContext);
  finally
    WriteLn(Format('✅ [RES] %s %s -> %d', 
      [Method, Path, AContext.Response.StatusCode]));
  end;
end;

end.
