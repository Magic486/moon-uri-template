# moon-uri-template

A pure MoonBit implementation of
[RFC 6570](https://www.rfc-editor.org/rfc/rfc6570) Level 4 URI Templates.

The library supports every RFC 6570 operator, prefix and explode modifiers,
ordered scalar/list/associative values, Unicode-aware prefixes, UTF-8 percent
encoding, structured errors, JSON variables, and a CLI.

The module currently uses the provisional namespace
`yelfs/moon-uri-template`. It will be confirmed before publication.

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

```bash
moon check --warn-list +73
moon test --target all
moon fmt --check
moon info
```

The complete public guide with tested examples is
[README.mbt.md](README.mbt.md). See [SPEC.md](SPEC.md) for normative scope,
[GOALS.md](GOALS.md) for milestones, and [THIRD_PARTY.md](THIRD_PARTY.md) for
attribution.

## Security

URI Template expansion is not input validation. In particular, `{+var}` and
`{#var}` permit URI reserved characters. Apply a separate destination policy
before using expanded, untrusted values for network requests.

## License

Project code is MIT licensed. Vendored conformance fixtures retain Apache-2.0.
