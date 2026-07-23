# Implementation status

Last updated: 2026-07-23

This document maps `SPEC.md` and `GOALS.md` requirements to current repository
evidence. A checked item means local evidence exists; it does not claim that
remote GitHub, Gitlink, or mooncakes.io state has been completed.

## P0 implementation

- [x] RFC 6570 Level 1–4 parser
- [x] Eight standard expression forms
- [x] Prefix and explode modifiers
- [x] Scalar, ordered list, and ordered associative values
- [x] Undefined and empty-value semantics
- [x] Unicode code-point prefixes
- [x] UTF-8 percent encoding
- [x] Structured syntax, value, parse-limit, and output-limit errors
- [x] Deterministic parsed templates that can be expanded repeatedly
- [x] JSON variable adapter
- [x] `validate`, `variables`, `inspect`, and `expand` CLI
- [x] Default parsing limits and 1 MiB expanded-output limit

## Test and quality evidence

- [x] 153 generated upstream interoperability cases
- [x] Focused RFC examples and boundary tests
- [x] Black-box public API tests
- [x] Tested README examples
- [x] Wasm tests
- [x] Wasm-GC tests
- [x] JavaScript tests
- [x] Native tests
- [x] `moon check --warn-list +73`
- [x] `moon fmt --check`
- [x] `moon info`
- [x] `moon build --target all`
- [x] Coverage audit

Most recent local result:

```text
187 tests passed on each of wasm, wasm-gc, JavaScript, and native.
Core library coverage: 349/351 instrumented lines (99.43%).
The remaining 42 uncovered lines are executable entry paths (39 CLI, 3 example)
plus 2 defensive aborts that guard impossible internal states.
```

## Documentation and compliance

- [x] Normative implementation specification
- [x] Goals, priorities, and milestones
- [x] Architecture and design explanation
- [x] Complete GitHub-facing README
- [x] Tested `README.mbt.md`
- [x] MIT project license
- [x] Third-party fixture attribution
- [x] Upstream Apache-2.0 license retained
- [x] Changelog
- [x] GitHub Actions workflow

## Remaining external or release work

- [ ] Confirm the final GitHub/mooncakes namespace instead of provisional
  `yelfs/moon-uri-template`
- [ ] Add the final repository URL to `moon.mod`
- [ ] Push the repository to a public GitHub remote
- [ ] Create or synchronize the required Gitlink repository
- [ ] Observe the GitHub Actions workflow succeeding remotely
- [ ] Publish the package and CLI to mooncakes.io
- [ ] Add final release notes and tag
- [ ] Prepare the one-page project proposal PDF

## P1 engineering work

- [x] Configurable parser limits for template length, expressions, and variables
- [x] Deterministic generated parser/expander invariant tests
- [x] Native release performance benchmark and local baseline
- [x] Real integration example with an HTTP/SDK-style request builder
- [x] Machine-readable conformance summary
- [x] Differential suite against two mature RFC 6570 implementations

These P1 items improve award competitiveness but do not change RFC 6570 core
compatibility.
