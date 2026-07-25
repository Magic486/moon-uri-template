# Changelog

## 0.1.1 — 2026-07-25

- Add moon.mod.json for mooncakes.io doc generation compatibility.
- Update repository links and installation instructions.

## 0.1.0 — 2026-07-25

- Implement RFC 6570 Level 1–4 parsing and expansion.
- Add scalar, ordered list, and ordered associative variable values.
- Add prefix, explode, Unicode, and percent-encoding support.
- Add structured errors and bounded expansion.
- Add explicit template-length, expression-count, and per-expression variable
  parsing limits.
- Add a strict JSON variable adapter.
- Add `validate`, `variables`, `inspect`, and `expand` CLI commands.
- Vendor the Apache-2.0 interoperability fixtures at commit
  `4171dac22aa67fc710b3f6df308a50bd08552986`.
- Generate and pass 153 upstream conformance cases.
- Validate the full suite on Wasm, Wasm-GC, JavaScript, and Native.
- Add CI, design documentation, implementation status, and tested examples.
- Add generated invariant tests, an HTTP/SDK integration example, a
  machine-readable conformance summary, native release benchmarks, and
  differential validation against two mature RFC 6570 implementations.
