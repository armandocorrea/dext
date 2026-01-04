# 📊 Comparison: Dext Testing Framework vs Alternatives

This document outlines how the **Dext Testing Framework** compares to established testing ecosystems in both .NET (its primary inspiration) and the Delphi world.

## 🏆 Feature Matrix

| Feature | 🚀 Dext Testing | 🌐 Moq + FluentAssertions (.NET) | ⚙️ Spring4D Mocking (Delphi) | 🛠️ Delphi-Mocks (Delphi) |
| :--- | :--- | :--- | :--- | :--- |
| **Assertion Style** | **Fluent** <br> `Should(X).Be(Y)` | **Fluent** <br> `X.Should().Be(Y)` | **Classic** <br> `Assert.AreEqual(Y, X)` | **Classic** <br> `CheckEquals(Y, X)` |
| **Mocking Syntax** | **Fluent Chain** <br> `Setup.Returns(V).When.Method` | **Expression Trees** <br> `Setup(x => x.Method).Returns(V)` | **Fluent** <br> `Setup.Returns(V).When.Method` | **Arrangement** <br> `Setup.Expect.Once.When.Method` |
| **Class Mocking** | ✅ **Supported** <br> (Virtual Methods) | ✅ **Supported** <br> (Virtual Methods) | ✅ **Supported** <br> (Virtual Methods) | ⚠️ **Limited / Complex** |
| **Auto-Mocking** | ✅ **Built-in** <br> `TAutoMocker` | ⚠️ External Libs <br> (Moq.AutoMocker) | ✅ **Container Integration** | ❌ **Manual Injection** |
| **Snapshot Testing** | ✅ **Built-in** <br> `MatchSnapshot` | ⚠️ External Libs <br> (Verify / Snapshooter) | ❌ No | ❌ No |
| **Dependencies** | ⚡ **Zero / Native** | .NET Runtime | 📦 **High** <br> (Spring Core) | 📦 **Low** |

---

## 🔍 Detailed Analysis

### 1. vs Moq & FluentAssertions (.NET)
*Direct Inspiration*

Dext mimics the **Developer Experience (DX)** of the .NET ecosystem, bridging the gap for developers moving between languages.
*   **Assertions**: Dext brings the `Should` paradigm to Delphi. While .NET uses extension methods (`Value.Should()`), Dext uses a helper `Should(Value)` due to Delphi language design, but the chainable API (`.Be()`, `.BeGreaterThan()`, `.MatchSnapshot()`) is identical in spirit.
*   **Mocking**: Moq relies heavily on C# Expression Trees (lambdas) for type-safe setup. Since Delphi lacks expression trees, Dext uses a **Proxy-Recording** approach (`Setup...When.MethodCall`), which provides comparable type safety and refactoring support without string-based magic.

### 2. vs MSTest / NUnit (.NET)
*The Modern vs Classic Debate*

*   **Readability**: MSTest uses `Assert.AreEqual(Expected, Actual)`, which often leads to confusion about argument order ("Wait, is expected first or second?"). Dext's `Should(Actual).Be(Expected)` reads like a sentence, eliminating this confusion.
*   **Detail**: Default assert failures are cryptic ("Expected 5, but was 3"). Dext provides rich error context automatically ("Expected Value to be 5, but found 3").

### 3. vs Spring4D Testing (Delphi)
*Heavyweight vs Lightweight*

Spring4D is a fantastic, comprehensive framework (DI, Collections, Crypto, etc.).
*   **Architecture**: To use Spring4D Mocks, you buy into the entire Spring ecosystem. Dext is designed as a **focused, lightweight** library that can be dropped into any project without adopting a massive framework.
*   **Syntax**: Spring4D allows mocking classes and interfaces effectively. Dext matches this capability but adds **Auto-Mocking** specifically tuned for Unit Tests (creating SUTs easily) and **Snapshot Testing** which Spring lacks natively.

### 4. vs Delphi-Mocks (Delphi)
*Evaluation vs Usage*

Delphi-Mocks is a veteran library.
*   **Mocking Classes**: Dext makes class mocking seamless (`Mock<TClass>.Create`), whereas older libraries often focus strictly on Interfaces or require complex overrides.
*   **Ergonomics**: Dext prioritizes a clean, "Noise-Free" API. Using `Dext.Impl.Method` is rare; usually, `Setup.Returns` is all you need. Delphi-Mocks can be more verbose in setting up expectations (`Expect.Once.PerInstance...`).

---

## 💡 Why Dext?

**Productivity First.**
Dext combines the best features of specific, separate tools (Mocking, Assertions, Snapshots, Auto-Mocking) into a single, cohesive, zero-dependency unit. It doesn't just "allow" you to test; it makes testing **fast** and **expressive**.
