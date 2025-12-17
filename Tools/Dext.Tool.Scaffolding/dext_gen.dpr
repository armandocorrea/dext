program dext_gen;

{$APPTYPE CONSOLE}

// {$R *.res}

uses
  System.SysUtils,
  Dext.Tool.Scaffolding.CLI in 'Dext.Tool.Scaffolding.CLI.pas';

begin
  try
    var App := TDextScaffoldCLI.Create;
    try
      if not App.Run then
      begin
        // If Run returns false (no command or bad command), we might exit with error code or just 0
        // Usually CLI tools show help and exit with 0 or 1.
        // Run already handles Help.
        // If we want to force help on no args:
        if ParamCount = 0 then
          App.ShowHelp;
      end;
    finally
      App.Free;
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
