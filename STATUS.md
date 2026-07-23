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
- [x] Structured syntax, value, and output-limit errors
- [x] Deterministic parsed templates that can be expanded repeatedly
- [x] JSON variable adapter
- [x] `validate`, `variables`, `inspect`, and `expand` CLI
- [x] Default 1 MiB expanded-output limit

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
178 tests passed on each of wasm, wasm-gc, js, and native.
13 uncovered lines: 10 CLI process paths and 3 defensive/unreachable branches.
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

## Remaining P1 engineering work

- [ ] Configurable parser limits for template length and expression count
- [ ] Property-based parser/expander invariants
- [ ] Performance benchmark and published baseline
- [ ] Real integration example with an HTTP/OpenAPI-style request builder
- [ ] Machine-readable conformance summary

These P1 items improve award competitiveness but do not change RFC 6570 core
compatibility.
