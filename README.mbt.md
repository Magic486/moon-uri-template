# moon-uri-template

A pure MoonBit implementation of
[RFC 6570](https://www.rfc-editor.org/rfc/rfc6570) Level 4 URI Templates.

`moon-uri-template` parses a URI Template once and expands it repeatedly with
typed scalar, list, or associative values. It is intended as reusable
infrastructure for HTTP clients, OpenAPI tooling, SDK generators, hypermedia
APIs, and cross-target MoonBit applications.

The module currently uses the provisional namespace
`yelfs/moon-uri-template`. The namespace and repository URL will be confirmed
before the first mooncakes.io release.

## Features

- RFC 6570 Levels 1–4
- All standard operators: simple, `+`, `#`, `.`, `/`, `;`, `?`, and `&`
- Prefix and explode modifiers
- Ordered scalar, list, and associative values
- Unicode code-point-aware prefixes
- UTF-8 percent encoding
- Structured errors with source offsets
- Deterministic expansion on Wasm, Wasm-GC, JavaScript, and Native
- JSON variable adapter
- `validate`, `variables`, `inspect`, and `expand` CLI commands
- 153 vendored interoperability cases plus project-specific tests

## Library example

```mbt check
///|
test "expand a repository issues URI" {
  let template = @moon-uri-template.UriTemplate::parse(
    "/repos/{owner}/{repo}/issues{?page,labels*}",
  )
  let variables : Map[String, @moon-uri-template.UriValue] = {
    "owner": Scalar("moonbitlang"),
    "repo": Scalar("core"),
    "page": Scalar("2"),
    "labels": List(["bug", "help wanted"]),
  }
  assert_eq(
    template.expand(variables),
    "/repos/moonbitlang/core/issues?page=2&labels=bug&labels=help%20wanted",
  )
}
```

## Value model

```mbt nocheck
///|
pub(all) enum UriValue {
  Scalar(String)
  List(Array[String])
  Assoc(Array[(String, String)])
}
```

Lists and associative arrays retain input order. A missing map entry represents
an undefined variable. Empty strings remain defined; empty lists and empty
associative arrays are treated as undefined by RFC 6570 expansion.

### Prefix modifier

```mbt check
///|
test "prefix length counts Unicode code points" {
  let template = @moon-uri-template.UriTemplate::parse("{value:2}")
  let variables : Map[String, @moon-uri-template.UriValue] = {
    "value": Scalar("月兔Moon"),
  }
  assert_eq(template.expand(variables), "%E6%9C%88%E5%85%94")
}
```

### Explode modifier

```mbt check
///|
test "explode a list into repeated query parameters" {
  let template = @moon-uri-template.UriTemplate::parse("{?labels*}")
  let variables : Map[String, @moon-uri-template.UriValue] = {
    "labels": List(["bug", "help wanted"]),
  }
  assert_eq(template.expand(variables), "?labels=bug&labels=help%20wanted")
}
```

## JSON variables

`variables_from_json` accepts a JSON object:

- string → `Scalar`
- array of strings → `List`
- object with string values → ordered `Assoc`

Numbers, booleans, null, nested arrays, and non-string associative values are
rejected rather than implicitly stringified.

```json
{
  "owner": "moonbitlang",
  "repo": "core",
  "page": "2",
  "labels": ["bug", "help wanted"]
}
```

## CLI

Run from this repository:

```bash
moon run cmd/uri-template -- validate '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- variables '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- inspect '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- expand \
  '/repos/{owner}/{repo}/issues{?page,labels*}' \
  --variables examples/variables.json
```

The expansion command prints:

```text
/repos/moonbitlang/core/issues?page=2&labels=bug&labels=help%20wanted
```

## Standards conformance

The project vendors the Apache-2.0
[`uri-templates/uritemplate-test`](https://github.com/uri-templates/uritemplate-test)
fixtures at commit `4171dac22aa67fc710b3f6df308a50bd08552986`.

The fixture generator produces 153 MoonBit tests covering:

- RFC specification examples
- extended interoperability cases
- negative and invalid-template cases
- multibyte prefix handling
- reserved and percent-encoded values
- literal encoding

Run:

```bash
powershell -NoProfile -ExecutionPolicy Bypass \
  -File tools/generate_conformance_tests.ps1
moon test --target all
```

All generated and local tests currently pass on Wasm, Wasm-GC, JavaScript, and
Native with the MoonBit 2026-07-03 toolchain.

## Security boundary

URI Template expansion is not input validation or authorization.

- `{+var}` and `{#var}` intentionally allow URI reserved characters.
- Do not use expanded, untrusted URIs for SSRF-sensitive requests without a
  separate scheme, host, port, and destination policy.
- Errors do not include the complete variable map.
- `expand` enforces a default output limit of 1 MiB.
- `expand_with_limit` allows applications to set a tighter limit.

The library does not send HTTP requests, resolve relative references, check
whether resources exist, or reverse-match a URI into variables.

## Development

```bash
moon check --warn-list +73
moon test --target all
moon fmt --check
moon info
```

Project scope and acceptance requirements are defined in
[SPEC.md](SPEC.md). Delivery priorities and milestones are tracked in
[GOALS.md](GOALS.md). Third-party attribution is recorded in
[THIRD_PARTY.md](THIRD_PARTY.md).

## License

Project code is available under the MIT License. Vendored conformance fixtures
retain their upstream Apache-2.0 license.
