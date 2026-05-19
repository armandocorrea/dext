# S29 - SIMD and Fast Integer-to-String Conversion

## Status
- **Date**: 2026-05-19
- **Author**: Antigravity & Cezar Romero
- **Status**: Proposed
- **Issue Reference**: Issue #124

---

## 1. Context & Rationale

High-performance web frameworks spend a non-trivial percentage of CPU cycles executing primitive serialization tasks. Inside the **Dext Framework**, converting binary integers (32-bit and 64-bit) into decimal strings (ASCII/UTF-8) is a silent but widespread performance bottleneck. This operation occurs continuously during:
1. **JSON Serialization (`Dext.Json`)**: Exporting tabular DB results where almost every record has an `ID: Int64`, foreign keys, numeric metrics, or dates/times formatted as integers.
2. **Database as API**: High-throughput REST API endpoints converting database datasets directly to JSON streams.
3. **Mapeamento de Tipos (`Dext.Core.ValueConverters.pas`)**: Converting integer parameters into textual form for queries or log formatting.
4. **Telemetry and Logging (`Dext.Logging` / `Dext.Telemetry`)**: Writing high-frequency timestamps, connection IDs, and response sizes into textual sinks.

### The Problem with standard Delphi `IntToStr`
Currently, Dext's `TIntegerToStringConverter.Convert` delegates to the standard Delphi RTL `System.SysUtils.IntToStr`.
While optimized by the compiler using magic numbers to avoid division where possible, standard `IntToStr`:
1. **Requires Heap Allocations**: Returns a standard managed Delphi `string`, forcing memory allocation and reference counting overhead on the heap. This introduces locking contention in multi-threaded web servers.
2. **Processes One Digit at a Time**: Relies on a sequential loop, which creates long dependency chains in the CPU pipeline, blocking Out-of-Order Execution (OoOE).
3. **Suffers from Division Latency**: In places where direct modular division is still computed, division instructions (`div`) cost **20 to 80 clock cycles**, whereas multiplications and additions cost only **1 to 3 clock cycles**.

### The Daniel Lemire Inspiration
In May 2026, **Daniel Lemire & Jaël Champagne Gareau** published *"Converting an Integer to a Decimal String in Under Two Nanoseconds"*, detailing a state-of-the-art **AVX-512 IFMA** (Integer Fused Multiply-Add) algorithm (`simditoa`) that converts integers to decimal strings in parallel without lookup tables or division. 

While AVX-512 yields astonishing sub-2ns speeds, integrating it directly as a baseline requirement in Dext is unfeasible due to:
* **Portability**: Standard cloud microservices (AWS EC2, Azure VMs) often disable AVX-512, and ARM platforms (macOS Apple Silicon, Linux64 ARM) lack x86 SIMD extensions.
* **Delphi Assembly Mnemonics**: Delphi's inline assembler has partial support for modern AVX-512 opcodes, requiring raw hex opcode injection which reduces code maintainability.

We can capture **80-90% of the maximum performance gains** on all platforms by introducing a **Zero-Allocation, Division-Free, Base-100 Lookup Table Scalar `itoa`** writing directly to `TByteSpan`, with dynamic SIMD vector fallbacks for batch operations.

---

## 2. Goals

- **Zero Heap Allocations**: Write decimal numbers directly into target buffers (`TByteSpan` / stream memory) without allocating managed intermediate strings.
- **Lighter CPU Footprint**: Eliminate slow CPU division instructions entirely by utilizing fixed-point multiplicative inverses (reciprocal multiplication).
- **Fast Base-100 Processing**: Write **two digits per iteration** using an ASCII lookup table to double write throughput.
- **Portability**: Provide a highly optimized, pure Pascal implementation that works out-of-the-box on Windows, Linux, macOS, and mobile architectures (Intel and ARM).
- **Dynamic SIMD Extensions**: Extend `TDextSimd` (`Dext.Collections.Simd.pas`) with vectorized versions (SSE4.2 / AVX2 / ARM NEON) to format batches of integers simultaneously when batch processing logs or bulk data.

---

## 3. Comparative Analysis

To deliver a premium API formatting layer, we compared our proposed architecture against leading platforms:

| Strategy | Performance | Heap Allocations | Hardware Portability | Implementation Complexity in Delphi |
| :--- | :--- | :--- | :--- | :--- |
| **Standard RTL (`IntToStr`)** | Slow (~45-60ns) | High (Allocates string) | Universal | Low (Used out-of-the-box) |
| **Lemire `simditoa` (AVX-512)** | Ultra-Fast (<2ns) | Zero (Writes to buffer) | Extremely Restricted (Modern x86-64) | Very High (Requires raw opcodes/external C++ DLL) |
| **Dext Fast Scalar (Proposed)** | Fast (~3.5-5ns) | Zero (Writes to Span) | Universal (Intel & ARM) | Medium (Pure Pascal / Basic Assembly) |
| **Dext Batch SIMD (Proposed)** | Very Fast (~2-3ns/int) | Zero (Writes to buffer) | Great (AVX2 / ARM NEON) | High (Requires dynamic fallback & inline assembler) |

---

## 4. Technical Design

### 4.1. Fast Scalar `itoa` (Base-100 & Fixed-Point Multiplicative Inverse)
Instead of dividing by 10 to extract one digit, the scalar algorithm divides by 100 to extract **two digits at a time**. 

1. **Multiplicative Inverse (Division-Free)**:
   Dividing an integer $x$ by $100$ is mathematically equivalent to multiplying by the reciprocal of 100.
   For a 64-bit unsigned integer, we pre-calculate a multiplier:
   $$C = \lfloor 2^{64} / 100 \rfloor + 1 = \$A7C5AC471B478423$$
   We then compute the division via multiplication and shift:
   $$q = (x \times C) \gg 64$$
   And the remainder:
   $$\text{remainder} = x - (q \times 100)$$

2. **ASCII Word Table**:
   We store all combinations from `00` to `99` as raw 16-bit values (`Word`), where each Word contains the ASCII representation of the two digits (e.g., `DIGITS_100[37]` stores the characters `'3'` and `'7'`).
   This allows writing two characters into the memory buffer with a single 16-bit store instruction, entirely removing byte-by-byte char conversions.

```pascal
const
  DIGITS_100: array[0..99] of Word = (
    $3030, $3130, $3230, $3330, $3430, ... // '00', '10', '20'...
  );
```

### 4.2. API Convergence with `TByteSpan` & `Dext.Json`
We will expose the zero-allocation conversion directly via `TByteSpan`:

```pascal
// Added to TByteSpan record in Dext.Core.Span.pas
function TryWriteInt64(Value: Int64; out BytesWritten: Integer): Boolean;
function TryWriteUInt64(Value: UInt64; out BytesWritten: Integer): Boolean;
```

This allows the JSON writer and converters to format values in-place without intermediary allocations:

```pascal
// TIntegerToStringConverter.Convert in Dext.Core.ValueConverters.pas
function TIntegerToStringConverter.Convert(const AValue: TValue; ATargetType: PTypeInfo): TValue;
var
  Buffer: array[0..19] of Byte;
  Span: TByteSpan;
  BytesWritten: Integer;
begin
  Span := TByteSpan.Create(@Buffer[0], 20);
  if TryWriteInt64ToSpan(AValue.AsInt64, Span, BytesWritten) then
    Result := TEncoding.UTF8.GetString(Buffer, 0, BytesWritten)
  else
    Result := IntToStr(AValue.AsInt64); // Fallback
end;
```

### 4.3. Dynamic Batch SIMD Integration
For high-density collections (like serializing large lists of objects or telemetry frames containing thousands of integer timestamps), `TDextSimd` will expose batch formatters:

```pascal
// Dext.Collections.Simd.pas
class procedure FormatInt64Batch(Source: PInt64; Count: Integer; Dest: PByte; out BytesWritten: Integer); static;
```

Under the hood:
* **AVX2 Fallback**: Uses 256-bit registers to process 4 integers simultaneously.
* **NEON Fallback**: Uses 128-bit registers to process 2 integers simultaneously on Apple Silicon and Linux ARM.
* **Pascal Fallback**: Automatically cascades to the fast scalar `FastItoa` algorithm on legacy or VM targets.

---

## 5. Technical Validation

### 5.1. Performance Benchmarks
We will introduce a benchmarking suite in `c:\dev\Dext\DextRepository\Benchmarks\Core\Dext.Benchmark.Itoa.pas` that measures:
* Execution time (latency per call) of `TryWriteInt64` vs `System.SysUtils.IntToStr`.
* Total memory allocation and garbage collection churn.
* Throughput of a realistic JSON exporter converting 500,000 entity records with dynamic IDs.

### 5.2. Robust Edge-Case Unit Testing
A complete unit test suite `Dext.Core.FastItoa.Tests.pas` will validate:
- **Limits**: Min/Max ranges of standard integer types (`Int64.MinValue`, `Int64.MaxValue`, `Int32.MinValue`, `Int32.MaxValue`).
- **Symmetric values**: Positive values, negative values, and exact zero (`0`).
- **Buffer Safety**: Validating that writing to a buffer that is too small returns `False` immediately and does not corrupt adjacent memory (buffer overflow protection).

---

## 6. Files Impacted

- **Sources**:
  - `Sources\Core\Base\Dext.Core.Span.pas` (Adding zero-allocation `TByteSpan` writers)
  - `Sources\Core\Base\Dext.Core.ValueConverters.pas` (Integrating fast itoa in string conversions)
  - `Sources\Core\Dext.Collections.Simd.pas` (SIMD dynamic batch formatting hooks)
  - `Sources\Core\Base\Dext.Core.FastItoa.pas` (New unit implementing division-free scalar itoa)
- **Benchmarks**:
  - `Benchmarks\Core\Dext.Benchmark.Itoa.pas` (New performance test cases)
- **Tests**:
  - `Tests\Core\Dext.Core.FastItoa.Tests.pas` (New unit tests for numerical boundary correctness)

---

## 7. Acceptance Criteria

- [ ] New `Dext.Core.FastItoa.pas` implements the division-free Base-100 `itoa` correctly.
- [ ] `TByteSpan.TryWriteInt64` and `TByteSpan.TryWriteUInt64` format numerical inputs with zero allocations.
- [ ] Boundaries `Int64.MinValue`, `Int64.MaxValue`, `0`, `-1`, `1` are correctly handled and validated by tests.
- [ ] Buffer overflow protection prevents write operations when `TByteSpan.Length` is insufficient.
- [ ] Benchmarks prove a performance gain of at least **3x** in execution time compared to `SysUtils.IntToStr`.
- [ ] All Dext unit tests run and pass without memory leaks or regression on target platform runners.
