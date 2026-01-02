program Dext.Entity.Tests;

{$APPTYPE CONSOLE}



uses
  Dext.MM,
  System.SysUtils,
  Dext.Utils,
  Dext.Entity.Dialects,
  Dext.Entity.Dialect.PostgreSQL.Test,
  Dext.Entity.Dialect.Firebird.Test,
  Dext.Entity.Dialect.MSSQL.Test,
  Dext.Entity.Dialect.MySQL.Test,
  Dext.Entity.Dialect.Oracle.Test,
  Dext.Entity.Naming.Test,
  Dext.Entity.Pooling.Test,
  Dext.Entity.Mapping.Test;

procedure RunTests;
var
  TestPG: TPostgreSQLDialectTest;
  TestFB: TFirebirdDialectTest;
  TestMS: TSQLServerDialectTest;
  TestMY: TMySQLDialectTest;
  TestOR: TOracleDialectTest;
  TestNS: TNamingStrategyTest;
  TestMap: TMappingTest;
begin
  SetConsoleCharSet(65001);
  WriteLn('🧪 Running Dext Entity Unit Tests...');
  WriteLn('====================================');
  
  // Fluent Mapping
  TestMap := TMappingTest.Create;
  try
    TestMap.Run;
  finally
    TestMap.Free;
  end;
  WriteLn('');

  // Naming Strategy
  TestNS := TNamingStrategyTest.Create;
  try
    TestNS.Run;
  finally
    TestNS.Free;
  end;
  WriteLn('');

  // PostgreSQL
  TestPG := TPostgreSQLDialectTest.Create;
  try
    TestPG.Run;
  finally
    TestPG.Free;
  end;
  WriteLn('');

  // Firebird
  TestFB := TFirebirdDialectTest.Create;
  try
    TestFB.Run;
  finally
    TestFB.Free;
  end;
  WriteLn('');

  // SQL Server
  TestMS := TSQLServerDialectTest.Create;
  try
    TestMS.Run;
  finally
    TestMS.Free;
  end;
  WriteLn('');

  // MySQL
  TestMY := TMySQLDialectTest.Create;
  try
    TestMY.Run;
  finally
    TestMY.Free;
  end;
  WriteLn('');

  // Oracle
  TestOR := TOracleDialectTest.Create;
  try
    TestOR.Run;
  finally
    TestOR.Free;
  end;
  
  WriteLn('');
  WriteLn('✨ All unit tests completed.');
end;

begin
  try
    RunTests;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  ConsolePause;
end.
