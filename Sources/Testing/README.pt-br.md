# Dext Testing Framework

Um framework de testes abrangente para Delphi, projetado para desenvolvimento moderno. Possui APIs fluentes para Mocking e Asserções, fortemente inspirado em ferramentas do ecossistema .NET (Moq, FluentAssertions).

## Funcionalidades

### Dext.Interception
Biblioteca core de interceptação suportando Interfaces e Classes.
- `TProxy.CreateInterface<T>`: Cria proxies dinâmicos para interfaces (`TVirtualInterface`).
- `TClassProxy`: Cria proxies para métodos virtuais de classes (`TVirtualMethodInterceptor`).
> **Nota**: Interfaces devem ter `{$M+}` habilitado. Classes usam RTTI para métodos virtuais.

### Dext.Mocks
Framework de mocking fluente inspirado no Moq.
- `Mock<T>`: Cria mocks para **Interfaces** e **Classes**.
- `Setup`: Configura comportamento (Returns, Throws, Callback).
- `When`: Encadeamento fluente.
- `Arg`: Argument matchers (`Arg.Any<T>`, `Arg.Is<T>`).
- `Received`: Verificação (`Times.Once`, `Times.Never`).

**Exemplo (Interface):**
```pascal
var Calc: Mock<ICalculator>;
...
Calc.Setup.Returns(42).When.Add(10, 20);
```

**Exemplo (Classe):**
```pascal
var Repo: Mock<TCustomerRepo>;
...
Repo.Setup.Returns(100).When.GetCount;
```

### Dext.Mocks.Auto (Auto-Mocking)
Automaticamente cria mocks e os injeta no construtor do Sistema Sob Teste (SUT).
```pascal
var Mocker: TAutoMocker;
...
Service := Mocker.CreateInstance<TMyService>; // Injeta Mock<IRepo> automaticamente
Mocker.GetMock<IRepo>.Setup.Returns(True).When.Save;
```

### Dext.Assertions
Biblioteca de asserções fluentes inspirada no FluentAssertions.
- Sintaxe `Should(Value)`.
- Suporta todos os tipos primitivos, Objetos, Listas, Datas e Actions.
- **Snapshot Testing**: `Should(Json).MatchSnapshot('MySnapshot');`

**Exemplo:**
```pascal
Should(User.Name).Be('John');
Should(List).HaveCount(5).Contain(10);
Should(procedure begin RaiseError end).Throw<EException>;
```

### Dext.Testing.Console
Executor de testes reutilizável para aplicações console.
```pascal
TTestRunner.Run('Meu Teste', ProcedureName);
TTestRunner.PrintSummary;
```

## Requisitos
- Delphi 10.4 ou mais recente (Recomendado: Delphi 11/12).
- FastMM5 (Opcional).
