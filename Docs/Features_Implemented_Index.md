# Dext Framework: Implemented Features Index

This index provides a comprehensive and exhaustive technical map of the Dext Framework. It serves as a guide for developers to understand the architectural breadth and depth of the ecosystem.

---

## 🏗️ 1. Dext Core — Foundation & Primitives (`Sources\Core`)

### 1.1 Dependency Injection (`Dext.Core.DI`)
- **TServiceCollection** — In-process service registration.
- **TServiceProvider** — High-speed service resolution.
- **Lifetimes**: `Singleton`, `Transient`, and `Scoped` (Request-based).
- **Factory Registration** — Dynamic service instantiation using custom functions.
- **Interface/Implementation Mapping** — Decouple definitions from concrete logic.

### 1.2 High-Performance Reflection (`Dext.Core.Reflection`)
- **TTypeCache** — Ultra-fast metadata storage bypassing standard RTTI overhead.
- **Fast Callers** — Execute methods and access properties using specialized pointers.
- **Attribute Discovery** — Scan and cache attributes at startup for zero-cost runtime access.

### 1.3 Zero-Allocation Memory (`Dext.Core.Memory`)
- **TSpan<T>** — Stack-allocated memory slices for high-speed string and buffer manipulation.
- **TVector<T>** — Efficient, growable stack-allocated vectors.
- **ILifetime<T>** — ARC wrapper for manual object lifecycle management.

### 1.4 Smart Properties (`Dext.Core.Props`)
- **Prop<T>** — Dual-mode value wrappers (Value Mode / Expression Mode).
- **Operator Overloading** — Fluent syntax for generating Expression Trees (`Prop > Value`).
- **AST Generation** — Compiles Delphi code into a reusable Abstract Syntax Tree at runtime.

### 1.5 Threading & Async (`Dext.Threading.*`)
- **TAsyncTask** — Fluent Async/Await implementation.
- **ICancellationToken** — Cooperative cancellation for thread safety.
- **Work-Stealing Scheduler** — Efficient task distribution across CPU cores.

### 1.6 Event Bus & Messaging (`Dext.Events`)
- **In-Process Pub/Sub** — MediatR-inspired messaging system.
- **IEventPublisher / IEventHandler<T>** — Decouple event producers from consumers.
- **Scoped Handlers** — Events inherit the DI scope of the originating request.

### 1.7 Observability & Telemetry (`Dext.Core.Diagnostics`)
- **TDiagnosticSource** — Instrumentation engine for SQL and HTTP tracking.
- **Activity Correlation** — Trace requests across subsystem boundaries (CorrelationId).

---

## 📦 2. Dext Collections Library (`Sources\Core`)

### 2.1 Performance Collections
- **Binary Code Folding** (`TRawList`) — Reduces binary bloat and compile times by up to 60%.
- **SIMD Acceleration** — AVX2/SSE2 optimized loops for list scanning.
- **Frozen Collections** — Lock-free, immutable collections for extreme read performance.
- **TChannel<T>** — Go-inspired async communication with backpressure support.

---

## 🗄️ 3. Dext ORM — Database Engine (`Sources\ORM`)

### 3.1 DbContext & Entities
- **Unit of Work** — Manage transactions and entity tracking in a single session.
- **Fluent Mapping** — Configure database schemas without polluting entities with attributes.
- **Soft Delete** — Transparent handling of `DeletedAt` fields.
- **Audit Logging** — Automatic tracking of `CreatedAt` and `UpdatedAt`.

### 3.2 Query Engine
- **Type-Safe Queries** — Query using Delphi expressions: `Where(U.Age > 18)`.
- **Eager Loading** — Join-based or Batch-based loading of child entities.
- **Specifications Pattern** — Encapsulate reusable query logic in classes.

---

## 🌐 4. Dext Web — Web Pipeline (`Sources\Web`)

### 4.1 Routing & Controllers
- **Attribute Routing** — `[DextController('/api/users')]`.
- **Zero-Alloc Middleware** — Composable request pipeline with zero-copy processing.
- **Model Binding** — Auto-populate objects from Body, Query, or Header.

### 4.2 DataApi (Zero-Code REST)
- **Automatic Endpoints** — Expose ORM entities via REST with a single attribute.
- **Direct-to-JSON Streaming** — Near-zero memory footprint for large GET requests.
- **Queryable APIs** — Built-in filtering (`?_gt`, `_cont`), sorting, and pagination.

---

## 🧪 5. Dext Testing & Quality (`Sources\Testing`)

### 5.1 Test Runner & Dashboard
- **CLI Runner** — High-performance command-line executor (`dext test`) with support for category and priority filtering.
- **Live Dashboard** — Built-in visual host for real-time test monitoring with failure history and stack trace analysis.
- **Fluent Runner API** (`Dext.Testing.Fluent`) — Programmatic configuration: `TTest.Configure.Verbose.RegisterFixtures([...]).Run`.

### 5.2 Attribute-Based Runner (`Dext.Testing.Attributes`)
Write tests without base class inheritance using RTTI metadata.
- **Core Attributes** — `[Fixture]`, `[Test]`, `[Fact]`, `[TestClass]`.
- **Lifecycle Management** — `[Setup]`, `[TearDown]`, `[BeforeAll]`, `[AfterAll]`, `[AssemblyInitialize]`, `[AssemblyCleanup]`.
- **Data-Driven Testing** —
  - `[TestCase(A, B, Expected)]` — Inline parameterized tests.
  - `[TestCaseSource('MethodName')]` — Dynamic data providers via methods.
  - `[Values(V1, V2)]`, `[Range(Start, Stop, Step)]`, `[Random(Min, Max, Count)]` — Automatic case generation.
  - `[Combinatorial]` — Execute all possible parameter combinations.
- **Execution Filters & Control** —
  - `[Ignore('Reason')]`, `[Skip('Reason')]` — Skip tests.
  - `[Explicit]` — Tests run only when explicitly selected.
  - `[Category('Tag')]`, `[Trait('Name', 'Value')]` — Categorization and filtering.
  - `[Timeout(ms)]`, `[MaxTime(ms)]`, `[Repeat(n)]`, `[Priority(n)]` — Execution and performance control.
  - `[Platform('Windows, Linux')]` — OS-specific restrictions.

### 5.3 Fluent Assertions (`Dext.Assertions`)
Fluent API based on the `Should(Value)` pattern.
- **Typed Assertions** — Specific methods for `ShouldString`, `ShouldInteger`, `ShouldDouble` (approximation), `ShouldBoolean`, `ShouldDateTime`, `ShouldGuid`, `ShouldUUID`, `ShouldObject`.
- **List/Collection Assertions** — `Should(List).HaveCount(5).Contain(X).OnlyContain(Predicate).AllSatisfy(Predicate)`.
- **Structural Comparison** — `BeEquivalentTo` for deep object and collection comparison (order-independent).
- **Soft Asserts** — `Assert.Multiple(procedure ... end)` to collect multiple failures in a block before failing the test.
- **Action Assertions** — `Should(Proc).Throw<EException>().WithMessageContaining('...')`.

### 5.4 Snapshot Testing
- **`MatchSnapshot('name')`** — Verify complex objects and JSON payloads via disk-based baseline comparison.
- **Structural JSON Compare** — Smart comparison that ignores formatting and property order in JSON.
- **Update Mode** — `SNAPSHOT_UPDATE=1` environment variable for automatic baseline updates.

### 5.5 Mocking & Interception (`Dext.Mocks`, `Dext.Interception`)
- **Dynamic Proxies** — `TProxy` (Interfaces) and `TClassProxy` (Classes with virtual methods) via `TVirtualInterface` and `TVirtualMethodInterceptor`.
- **Fluent Mocking** — `Mock<T>.Setup.Returns(Val).When.Method(Args)`.
- **Argument Matchers** — `Arg.Any<T>`, `Arg.Is<T>`, `Arg.IsNotNull<T>`.
- **Verification** — `Received(Times.Once)`, `Received(Times.AtLeast(n))`.
- **Auto-Mocking** — `TAutoMocker` for automated mock injection into the DI container during unit tests.

### 5.6 Reporting & CI/CD (`Dext.Testing.Report`)
- **Multi-Format Export** — JUnit XML, xUnit XML, TRX (Azure DevOps), HTML (Dark Theme), JSON.
- **SonarQube Integration** — Generate code coverage and failure reports compatible with Quality Gates.
- **TestInsight Integration** — Native support for direct visualization in the Delphi IDE.
- **Test Context Injection** — `ITestContext` injectable via parameter for `WriteLine`, `AttachFile` (screenshots), and execution metadata.

---

## 🧪 6. Quality & Testing (Scale and Rigor)

Dext is continuously validated by a massive testing infrastructure to ensure integrity across its subsystems:

- **Engineering Statistics** — The project exceeds **200,000 lines of pure Pascal code** (excluding templates and documentation), reflecting a massive investment in stability and high-level abstractions.
- **Massive Coverage** — Hundreds of test suites with thousands of individual assertions validating everything from the Core (Memory, Collections) to complex Web and ORM integrations.
- **Multi-DB Matrix (ORM)** — The persistence engine is exhaustively tested across a real matrix of 5 databases: PostgreSQL, SQL Server, MySQL, SQLite, and Firebird.
- **Stress & Concurrency Testing** — Validation of concurrent collections, channels, and async tasks under high load to ensure no Race Conditions.
- **Anti-Leak Policies** — Rigorous memory monitoring in every suite; test failures are triggered if object leaks are detected.
- **Field Evidence** — Framework validated in real-world projects deployed on **AWS and Azure**, with fiscal management systems processing peaks of **~800,000 daily requests**.
- **CI/CD Quality Gates** — Native integration with Azure DevOps and GitHub Actions, enforcing coverage thresholds and snapshot approval.

---

*Dext Framework — Exhaustive Technical Map & Features Index. (Revision: April 23, 2026).*
