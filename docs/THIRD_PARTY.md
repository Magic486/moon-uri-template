# Third-party materials

## uri-templates/uritemplate-test

- Project: `uri-templates/uritemplate-test`
- Source: <https://github.com/uri-templates/uritemplate-test>
- Pinned commit: `4171dac22aa67fc710b3f6df308a50bd08552986`
- Commit date: 2026-07-11
- License: Apache License 2.0
- Local path: `testdata/uritemplate-test/`

The vendored JSON files are interoperability tests for RFC 6570
implementations. They are not original work of this project. The upstream
license is retained at `testdata/uritemplate-test/LICENSE`.

`tools/generate_conformance_tests.ps1` converts the JSON fixtures into
MoonBit tests. The generated MoonBit test wrapper is project code; the test
inputs and expected values remain attributable to the upstream project.
