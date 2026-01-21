# 11. Desktop UI (Dext.UI)

> Build professional VCL desktop applications with modern patterns and productivity features.

---

## Overview

`Dext.UI` is a framework for building modern desktop applications in Delphi. It brings web-inspired patterns like navigation, middleware pipelines, and declarative binding to the VCL world.

## Key Features

| Feature | Description |
|---------|-------------|
| **Navigator** | Flutter-inspired navigation with middleware support |
| **Magic Binding** | Automatic two-way data binding via attributes |
| **MVVM Patterns** | Clean architecture with ViewModel and Controller patterns |
| **Testability** | Full unit testing support with dependency injection |

---

## Chapters

- [Navigator Framework](navigator.md) - Push/Pop navigation with middlewares
- [Magic Binding](magic-binding.md) - Declarative UI data binding
- [MVVM Patterns](mvvm-patterns.md) - Architecture guide

---

## Quick Example

```pascal
// App Startup - Configure Navigator
procedure TAppStartup.ConfigureServices(Services: IDIContainer);
begin
  // Register Navigator
  Services.AddSingleton<ISimpleNavigator>(
    function: ISimpleNavigator
    begin
      Result := TSimpleNavigator.Create;
      Result
        .UseAdapter(TCustomContainerAdapter.Create(MainForm.ContentPanel))
        .UseMiddleware(TLoggingMiddleware.Create(Logger));
    end);
end;

// Usage - Navigate to views
procedure TMainForm.ShowCustomerList;
begin
  Navigator.Push(TCustomerListFrame);
end;

procedure TMainForm.ShowCustomerEdit(Customer: TCustomer);
begin
  Navigator.Push(TCustomerEditFrame, TValue.From(Customer));
end;
```

---

## Example Project

| Example | Description |
|---------|-------------|
| [Desktop.MVVM.CustomerCRUD](../../../Examples/Desktop.MVVM.CustomerCRUD/) | Complete CRUD with Navigator, DI, and unit tests |

---

*See the [Desktop UI Roadmap](../../Roadmap/desktop-ui-roadmap.md) for upcoming features.*
