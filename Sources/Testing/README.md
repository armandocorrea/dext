# Dext Testing Framework

A comprehensive testing framework for Delphi, designed for modern development. It features a Fluent API for Mocking and Assertions, heavily inspired by .NET ecosystem tools (Moq, FluentAssertions).

## Features

### Dext.Interception
Core interception library supporting both Interfaces and Classes.
- `TProxy.CreateInterface<T>`: Creates dynamic proxies for interfaces (`TVirtualInterface`).
- `TClassProxy`: Creates proxies for class virtual methods (`TVirtualMethodInterceptor`).
> **Note**: Interfaces must have `{$M+}` enabled. Classes use RTTI for virtual methods.

### Dext.Mocks
Fluent mocking framework inspired by Moq.
- `Mock<T>`: Create mocks for **Interfaces** and **Classes**.
- `Setup`: Configure method behavior (Returns, Throws, Callback).
- `When`: Fluent chaining.
- `Arg`: Argument matchers (`Arg.Any<T>`, `Arg.Is<T>`).
- `Received`: Verification (`Times.Once`, `Times.Never`).

**Example (Interface):**
```pascal
var Calc: Mock<ICalculator>;
...
Calc.Setup.Returns(42).When.Add(10, 20);
```

**Example (Class):**
```pascal
var Repo: Mock<TCustomerRepo>;
...
Repo.Setup.Returns(100).When.GetCount;
```

### Dext.Mocks.Auto (Auto-Mocking)
Automatically creates mocks and injects them into your System Under Test (SUT) constructor.
```pascal
var Mocker: TAutoMocker;
...
Service := Mocker.CreateInstance<TMyService>; // Injects Mock<IRepo> automatically
Mocker.GetMock<IRepo>.Setup.Returns(True).When.Save;
```

### Dext.Assertions
Fluent assertions library inspired by FluentAssertions.
- `Should(Value)` syntax.
- Supports all primitive types, Objects, Lists, Dates, and Actions.
- **Snapshot Testing**: `Should(Json).MatchSnapshot('MySnapshot');`

**Example:**
```pascal
Should(User.Name).Be('John');
Should(List).HaveCount(5).Contain(10);
Should(procedure begin RaiseError end).Throw<EException>;
```

### Dext.Testing.Console
Reusable test runner for console applications.
```pascal
TTestRunner.Run('My Test', ProcedureName);
TTestRunner.PrintSummary;
```

## Requirements
- Delphi 10.4 or newer (Recommended: Delphi 11/12).
- FastMM5 (Optional).
