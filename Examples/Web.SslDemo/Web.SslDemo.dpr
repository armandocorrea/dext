program Web.SslDemo;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  System.SysUtils,
  Dext,
  Dext.Web,
  Dext.Web.Interfaces;

begin
  try
    Writeln('Dext SSL/HTTPS Demo');
    Writeln('-------------------');
    Writeln('This example demonstrates how to configure SSL using OpenSSL or TaurusTLS.');
    Writeln('Check appsettings.json for configuration options.');
    Writeln('');

    var App: IWebApplication := TDextApplication.Create;

    App.Builder
      .MapGet('/', procedure(Context: IHttpContext)
      begin
        Context.Response.SetStatusCode(200);
        Context.Response.SetContentType('text/html');
        Context.Response.Write('<h1>Dext SSL Demo</h1>' +
          '<p>If you see this, the server is running over a secure connection!</p>' +
          '<p>Check the browser address bar for the lock icon.</p>');
      end);

    App.Run;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
