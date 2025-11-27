program TestConfig;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Configuration.Interfaces in '..\Sources\Core\Dext.Configuration.Interfaces.pas',
  Dext.Configuration.Core in '..\Sources\Core\Dext.Configuration.Core.pas',
  Dext.Configuration.Json in '..\Sources\Core\Dext.Configuration.Json.pas';

begin
  try
    WriteLn('Compiling...');
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
