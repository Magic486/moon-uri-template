# moon-uri-template

A pure MoonBit implementation of
[RFC 6570](https://www.rfc-editor.org/rfc/rfc6570) Level 4 URI Templates.

The library supports every RFC 6570 operator, prefix and explode modifiers,
ordered scalar/list/associative values, Unicode-aware prefixes, UTF-8 percent
encoding, structured errors, JSON variables, and a CLI.

The module currently uses the provisional namespace
`Magic486/moon-uri-template`.

## Installation

Before the first mooncakes.io release, clone the repository and run
`moon update`. The final `moon add` command will be documented after the
package namespace is confirmed.

## Example

```mbt
let template = @moon-uri-template.UriTemplate::parse(
  "/repos/{owner}/{repo}/issues{?page,labels*}",
)
let variables : Map[String, @moon-uri-template.UriValue] = {
  "owner": Scalar("moonbitlang"),
  "repo": Scalar("core"),
  "page": Scalar("2"),
  "labels": List(["bug", "help wanted"]),
}
let uri = template.expand(variables)
```

Result:

```text
/repos/moonbitlang/core/issues?page=2&labels=bug&labels=help%20wanted
```

## CLI

```bash
moon run cmd/uri-template -- validate '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- variables '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- inspect '/repos/{owner}/{repo}{?page}'
moon run cmd/uri-template -- expand \
  '/repos/{owner}/{repo}/issues{?page,labels*}' \
  --variables examples/variables.json
```

## Verification

The project vendors the Apache-2.0
[`uri-templates/uritemplate-test`](https://github.com/uri-templates/uritemplate-test)
fixtures at commit `4171dac22aa67fc710b3f6df308a50bd08552986`.
The generated suite contributes 153 interoperability cases.
A deterministic [machine-readable summary](conformance-summary.json) records
the fixture and expected-rejection counts.

```bash
moon check --warn-list +73
moon test --target all
moon fmt --check
moon info
```

The complete public guide with tested examples is
[README.mbt.md](README.mbt.md). See [SPEC.md](docs/SPEC.md) for normative scope,
[GOALS.md](docs/GOALS.md) for milestones, and [THIRD_PARTY.md](docs/THIRD_PARTY.md) for
attribution. Reproducible performance cases and the first local baseline are
documented in [BENCHMARKS.md](docs/BENCHMARKS.md).
The [differential suite](docs/DIFFERENTIAL_TESTING.md) compares representative
expansions byte-for-byte with two independently maintained implementations.
The current one-page contest application is available at
[output/pdf/moon-uri-template-project-proposal.pdf](output/pdf/moon-uri-template-project-proposal.pdf).
Release and GitHub/Gitlink synchronization steps are documented in
[RELEASING.md](docs/RELEASING.md).

## Resource limits

`UriTemplate::parse` uses documented defaults: a 1 MiB template, 4,096
expressions, and 256 variables per expression. Applications accepting
untrusted templates can call `UriTemplate::parse_with_limits` to set smaller
per-call bounds. `UriTemplate::expand` limits output to 1 MiB;
`expand_with_limit` accepts an explicit smaller or larger bound. No global
mutable configuration is used.

The executable [HTTP client example](examples/http-client/main.mbt) shows how
an SDK request model maps typed fields to an RFC 6570 endpoint:

```bash
moon run examples/http-client
```

## Security

URI Template expansion is not input validation. In particular, `{+var}` and
`{#var}` permit URI reserved characters. Apply a separate destination policy
before using expanded, untrusted values for SSRF-sensitive network requests.
Structured errors do not echo the complete variable map.

## License

Project code is MIT licensed. Vendored conformance fixtures retain Apache-2.0.
