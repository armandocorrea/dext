unit Dext.Testing.Console;

interface

uses
  System.SysUtils;

type
  TTestRunner = class
  private
    class var FPassed: Integer;
    class var FFailed: Integer;
  public
    class procedure Run(const TestName: string; const Action: TProc);
    class procedure PrintSummary;
    class property Passed: Integer read FPassed;
    class property Failed: Integer read FFailed;
  end;

implementation

{ TTestRunner }

class procedure TTestRunner.Run(const TestName: string; const Action: TProc);
begin
  Write('Running ', TestName, '... ');
  try
    Action;
    Inc(FPassed);
    WriteLn('PASS');
  except
    on E: Exception do
    begin
      Inc(FFailed);
      WriteLn('FAIL');
      WriteLn('  Error: ', E.Message);
    end;
  end;
end;

class procedure TTestRunner.PrintSummary;
begin
  WriteLn;
  WriteLn('=========================================');
  WriteLn(Format('Tests Summary: %d Passed, %d Failed', [FPassed, FFailed]));
  WriteLn('=========================================');
  
  if FFailed > 0 then
    ExitCode := 1
  else
    ExitCode := 0;
end;

end.
