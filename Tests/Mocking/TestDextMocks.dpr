{***************************************************************************}
{                                                                           }
{           Dext Framework - Mock Framework Test                            }
{                                                                           }
{***************************************************************************}
program TestDextMocks;

{$APPTYPE CONSOLE}

uses
  Dext.MM,
  System.SysUtils,
  System.Rtti,
  Dext.Interception,
  Dext.Interception.Proxy,
  Dext.Mocks,
  Dext.Mocks.Interceptor,
  Dext.Mocks.Matching;

type
  // IMPORTANT: {$M+} is required for TVirtualInterface to work!
  // Without it, the interface has no RTTI and mocking will fail.
  {$M+}
  ICalculator = interface
    ['{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}']
    function Add(A, B: Integer): Integer;
    function Subtract(A, B: Integer): Integer;
    function Multiply(A, B: Integer): Integer;
    function GetName: string;
    procedure SetValue(Value: Integer);
  end;

  IGreeter = interface
    ['{B2C3D4E5-F6A7-8901-BCDE-F12345678901}']
    function Greet(const Name: string): string;
    function GreetWithTitle(const Title, Name: string): string;
  end;
  {$M-}

procedure TestBasicMocking;
var
  Calculator: Mock<ICalculator>;
begin
  WriteLn('=== Test 1: Basic Mocking ===');
  
  Calculator := Mock<ICalculator>.Create;
  
  // Setup: Add should return 42 for any arguments (fluent syntax)
  Calculator.Setup.Returns(42).When.Add(0, 0);
  
  // Act
  var Result := Calculator.Instance.Add(10, 20);
  
  // Assert
  if Result = 42 then
    WriteLn('  PASS: Add returned 42')
  else
    WriteLn('  FAIL: Add returned ', Result, ' (expected 42)');
end;

procedure TestArgumentMatchers;
var
  Calculator: Mock<ICalculator>;
begin
  WriteLn('');
  WriteLn('=== Test 2: Argument Matchers ===');
  
  Calculator := Mock<ICalculator>.Create;
  
// Setup with Arg.Any
  Calculator.Setup.Returns(100).When.Add(Arg.Any<Integer>, Arg.Any<Integer>);
  
  // Act - different arguments
  var R1 := Calculator.Instance.Add(1, 2);
  var R2 := Calculator.Instance.Add(50, 100);
  
  // Assert
  if (R1 = 100) and (R2 = 100) then
    WriteLn('  PASS: Arg.Any matched all calls')
  else
    WriteLn('  FAIL: Expected 100, got ', R1, ' and ', R2);
end;

procedure TestStringMatching;
var
  Greeter: Mock<IGreeter>;
begin
  WriteLn('');
  WriteLn('=== Test 3: String Matching ===');
  
  Greeter := Mock<IGreeter>.Create;
  
  // Setup with string matcher
  Greeter.Setup.Returns('Hello, World!').When.Greet(Arg.Any<string>);
  
  // Act
  var Result := Greeter.Instance.Greet('John');
  
  // Assert
  if Result = 'Hello, World!' then
    WriteLn('  PASS: Greet returned expected string')
  else
    WriteLn('  FAIL: Greet returned "', Result, '"');
end;

procedure TestVerification;
var
  Calculator: Mock<ICalculator>;
begin
  WriteLn('');
  WriteLn('=== Test 4: Verification ===');
  
  Calculator := Mock<ICalculator>.Create;
  Calculator.Setup.Returns(0).When.Add(Arg.Any<Integer>, Arg.Any<Integer>);
  
  // Call Add 3 times
  Calculator.Instance.Add(1, 2);
  Calculator.Instance.Add(3, 4);
  Calculator.Instance.Add(5, 6);
  
  // Verify: should have been called at least once
  try
    Calculator.Received(Times.AtLeast(1)).Add(Arg.Any<Integer>, Arg.Any<Integer>);
    WriteLn('  PASS: Verification passed for AtLeast(1)');
  except
    on E: EMockException do
      WriteLn('  FAIL: Verification failed - ', E.Message);
  end;

  // Verify exact count
  try
    Calculator.Received(Times.Exactly(3)).Add(Arg.Any<Integer>, Arg.Any<Integer>);
    WriteLn('  PASS: Verification passed for Exactly(3)');
  except
    on E: EMockException do
      WriteLn('  FAIL: Verification failed - ', E.Message);
  end;
end;

procedure TestStrictBehavior;
var
  Calculator: Mock<ICalculator>;
begin
  WriteLn('');
  WriteLn('=== Test 5: Strict Behavior ===');
  
  Calculator := Mock<ICalculator>.Create(TMockBehavior.Strict);
  
  // Don't setup anything - strict should throw
  try
    Calculator.Instance.Add(1, 2);
    WriteLn('  FAIL: Strict mode should have thrown exception');
  except
    on E: EMockException do
      WriteLn('  PASS: Strict mode threw exception: ', E.Message);
  end;
end;

procedure TestThrowsSetup;
var
  Calculator: Mock<ICalculator>;
begin
  WriteLn('');
  WriteLn('=== Test 6: Throws Setup ===');
  
  Calculator := Mock<ICalculator>.Create;
  
  // Setup to throw exception
  Calculator.Setup.Throws(EInvalidOp, 'Cannot divide by zero').When.Add(0, 0);
  
  try
    Calculator.Instance.Add(0, 0);
    WriteLn('  FAIL: Should have thrown EInvalidOp');
  except
    on E: EInvalidOp do
      WriteLn('  PASS: Threw expected exception: ', E.Message);
    on E: Exception do
      WriteLn('  FAIL: Wrong exception type: ', E.ClassName, ' - ', E.Message);
  end;
end;

procedure TestMultipleReturns;
var
  Calculator: Mock<ICalculator>;
begin
  WriteLn('');
  WriteLn('=== Test 7: Multiple Returns (Sequence) ===');
  
  Calculator := Mock<ICalculator>.Create;
  
  // Setup to return values in sequence
  Calculator.Setup.ReturnsInSequence([1, 2, 3]).When.Add(Arg.Any<Integer>, Arg.Any<Integer>);
  
  var R1 := Calculator.Instance.Add(0, 0);
  var R2 := Calculator.Instance.Add(0, 0);
  var R3 := Calculator.Instance.Add(0, 0);
  var R4 := Calculator.Instance.Add(0, 0); // Should return last value again
  
  if (R1 = 1) and (R2 = 2) and (R3 = 3) and (R4 = 3) then
    WriteLn('  PASS: Sequence returns worked correctly')
  else
    WriteLn('  FAIL: Expected 1,2,3,3 but got ', R1, ',', R2, ',', R3, ',', R4);
end;

procedure TestInterceptionDirectly;
begin
  WriteLn('');
  WriteLn('=== Test 8: Direct Interception ===');
  WriteLn('  SKIP: Direct interception test (needs custom interceptor)');
end;

begin
  try
    WriteLn('======================================');
    WriteLn('   Dext Mocks Framework Test Suite   ');
    WriteLn('======================================');
    WriteLn;
    
    TestBasicMocking;
    TestArgumentMatchers;
    TestStringMatching;
    TestVerification;
    TestStrictBehavior;
    TestThrowsSetup;
    TestMultipleReturns;
    TestInterceptionDirectly;
    
    WriteLn;
    WriteLn('======================================');
    WriteLn('   All tests completed!              ');
    WriteLn('======================================');
    
  except
    on E: Exception do
    begin
      WriteLn('FATAL ERROR: ', E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
  
  WriteLn;
  WriteLn('Press Enter to exit...');
  ReadLn;
end.
