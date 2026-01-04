# 🧪 Dext Testing Framework

The **Dext Testing Framework** is a native Delphi testing library designed for modern patterns like TDD (Test Driven Development) and BDD (Behavior Driven Development). It provides a fluent, expressive API for **Mocking** and **Assertions**, eliminating the need for external dependencies like DUnitX extensions or third-party mocking libraries.

## 📦 Features

### 1. Fluent Assertions
Inspired by .NET's *FluentAssertions*, write readable and expressive tests:

```pascal
// String
Should('Hello World').StartWith('Hello').And.EndWith('World');

// Numbers
Should(Order.Total).BeGreaterThan(0);

// Collections
ShouldList<string>.Create(Items).HaveCount(3).Contain('Dext');

// Exceptions
Should(procedure begin raise EInvalidOp.Create('Error'); end)
  .Throw<EInvalidOp>;
```

### 2. Expressive Mocking
A powerful mocking engine using `TVirtualInterface` to create dynamic proxies for interfaces.

```pascal
var
  EmailEngine: Mock<IEmailEngine>;
begin
  EmailEngine := Mock<IEmailEngine>.Create;
  
  // Setup behavior
  EmailEngine.Setup.Returns(True).When.Send('john@doe.com', Arg.Any<string>);
  
  // Use the proxy
  MyService.Process(EmailEngine.Instance);
  
  // Verify calls
  EmailEngine.Received(Times.Once).Send('john@doe.com', Arg.Any<string>);
end;
```

## 🚀 Getting Started

### Installation
The testing framework is part of the core Dext distribution.
1. Ensure `Dext.Testing.dpk` is compiled.
2. Add `Dext.Mocks`, `Dext.Assertions`, and `Dext.Interception` to your unit uses clause.

> ⚠️ **Important:** Interfaces to be mocked MUST have the `{$M+}` directive (RTTI generation) enabled.

### Writing your first test

```pascal
program MyTests;

{$APPTYPE CONSOLE}

uses
  System.SysUtils,
  Dext.Assertions,
  Dext.Mocks;

type
  {$M+} // Enable RTTI for mocking
  ICalculator = interface
    ['{GUID}']
    function Add(A, B: Integer): Integer;
  end;
  {$M-}

procedure TestCalculator;
var
  MockCalc: Mock<ICalculator>;
begin
  // Arrange
  MockCalc := Mock<ICalculator>.Create;
  MockCalc.Setup.Returns(10).When.Add(5, 5);

  // Act
  var Result := MockCalc.Instance.Add(5, 5);

  // Assert
  Should(Result).Be(10);
  MockCalc.Received.Add(5, 5);
end;

begin
  try
    TestCalculator;
    WriteLn('All tests passed!');
  except
    on E: Exception do WriteLn('Test Failed: ', E.Message);
  end;
end.
```

## 🔍 Assertions API

The `Dext.Assertions` unit provides a global `Should()` helper for most types.

### Strings
```pascal
Should(Name).Be('John');
Should(Name).NotBe('Doe');
Should(Name).StartWith('Jo');
Should(Name).EndWith('hn');
Should(Name).Contain('oh');
Should(Name).BeEmpty;
Should(Name).NotBeEmpty;
Should(Name).BeEquivalentTo('JOHN'); // Case insensitive
```

### Numbers (Integer, Double, Int64)
```pascal
Should(Age).Be(18);
Should(Age).BeGreaterThan(10);
Should(Age).BeLessThan(100);
Should(Age).BeInRange(18, 99);
Should(Age).BePositive;
Should(Age).BeNegative;
Should(Age).BeZero;
```

### Booleans
```pascal
Should(IsActive).BeTrue;
Should(IsActive).BeFalse;
```

### Date & Time
Use `ShouldDate()` for clarity and to avoid ambiguity with numbers.
```pascal
ShouldDate(Now).BeCloseTo(Now, 1000); // within 1000ms
ShouldDate(DueDate).BeAfter(SomeDate);
ShouldDate(DueDate).BeBefore(SomeDate);
ShouldDate(EventDate).BeSameDateAs(Now); // Ignores time
```

### Objects
```pascal
Should(User).BeNil;
Should(User).NotBeNil;
Should(User).BeOfType<TAdmin>;

// Deep Comparison (using JSON serialization)
Should(Dto1).BeEquivalentTo(Dto2);
```

### Actions (Exceptions)
```pascal
Should(procedure begin ... end).Throw<EInvalidOp>;
Should(procedure begin ... end).NotThrow;
```

### Lists & Collections
For collections, use `ShouldList<T>.Create(...)` or `Should<T>(Array)` (global syntax currently limited).

```pascal
var List: TList<Integer>;
...
ShouldList<Integer>.Create(List).HaveCount(5)
  .Contain(10)
  .NotContain(99);
```

## 🎭 Mocking API

The `Dext.Mocks` unit allows defining behavior and verifying interactions.

### Setup Returns
```pascal
// Return specific value
Repo.Setup.Returns(User).When.GetById(1);

// Basic Return
Calculator.Setup.Returns(42).When.Add(Arg.Any<Integer>, Arg.Any<Integer>);

// Sequence of Returns (1st call -> 10, 2nd call -> 20)
Calculator.Setup.ReturnsInSequence([10, 20]).When.Add(1, 1);

// Callback (Side effects or Argument Capture)
Calculator.Setup.Callback(procedure(Args: TArray<TValue>)
  begin
    Log('Called with ' + Args[0].ToString);
  end).When.DoSomething(Arg.IsAny);

// Return based on arguments (stubbing)
Repo.Setup.Returns(nil).When.GetById(Arg.Is<Integer>(function(Id: Integer): Boolean
  begin
    Result := Id < 0;
  end));
```

### Overloaded Returns
Simplified syntax for common types:
```pascal
Mock.Setup.Returns(10).When.GetInt;      // Integer
Mock.Setup.Returns('Data').When.GetString; // String
Mock.Setup.Returns(True).When.GetBool;   // Boolean
```

### Argument Matchers
- `Arg.Any<T>`: Matches any value of type T.
- `Arg.Is<T>(Predicate)`: Matches if predicate returns true.
- `Arg.Matches<T>(Value)`: Matches if equal to Value.

### Verification
```pascal
// Ensure method was called exactly once
Mock.Received(Times.Once).Save(Arg.Any<TUser>);

// Ensure method was never called
Mock.Received(Times.Never).Delete(Arg.Any<Integer>);

// Ensure method was called at least N times
Mock.Received(Times.AtLeast(2)).Log(Arg.Any<string>);
```

### Strict Mocks
By default, mocks are **Loose** (methods return default values if not setup). You can create **Strict** mocks that raise exceptions for unconfigured calls.

```pascal
var M := Mock<IFaa>.Create(TMockBehavior.Strict);
```

### Mocking Classes
You can mock `virtual` methods of regular classes similar to interfaces.
```pascal
type
  TCustomerRepo = class
  public
    function Count: Integer; virtual; // Must be virtual
  end;
  
var 
  Repo: Mock<TCustomerRepo>;
begin
  Repo := Mock<TCustomerRepo>.Create;
  Repo.Setup.Returns(10).When.Count;
end;
```

## 🌟 Advanced Features

### Snapshot Testing
Simplify testing of complex objects or large strings by comparing them against a stored "snapshot" file.

```pascal
// First run: Creates 'Snapshots/User_V1.json'
// Next runs: Compares result with file content
Should(UserDTO).MatchSnapshot('User_V1');
```

To update snapshots, set environment variable `SNAPSHOT_UPDATE=1`.

### Auto-Mocking Container
Reduce boilerplate in your tests by automatically creating mocks and injecting them into your System Under Test (SUT) constructor.

```pascal
uses Dext.Mocks.Auto;

var
  Mocker: TAutoMocker;
  Service: TMyService;
begin
  Mocker := TAutoMocker.Create;
  try
    // Automatically creates mocks and injects them (Interfaces and Virtual Classes)
    Service := Mocker.CreateInstance<TMyService>;
    
    // Access the injected mock to setup behavior
    Mocker.GetMock<IRepo>.Setup.Returns(User).When.GetById(1);
    
    Service.DoWork;
  finally
    Mocker.Free;
  end;
end;
```
