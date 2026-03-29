program Dext.Web.UnitTests;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  Dext.MM,
  System.SysUtils,
  Dext.Testing.Runner,
  Dext.Testing.Attributes,
  Dext.Testing.Fluent,
  Dext.Utils,
  Dext.Web.DataApi.Resolver.Tests in 'Dext.Web.DataApi.Resolver.Tests.pas';

begin
  SetConsoleCharSet();
  try
    WriteLn;
    WriteLn('🧪 Dext Web Unit Tests');
    WriteLn('======================');
    WriteLn;

    var TestResult := TTest
      .Configure
      .Verbose
      .RegisterFixtures([
        TEntityIdResolverTests
      ]).Run;

    TTest.SetExitCode(TestResult);
  except
    on E: Exception do
    begin
      WriteLn('FATAL ERROR: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;

  ConsolePause;
end.
