# moon-uri-template design

## Overview

The implementation separates URI Template processing into five stages:

```text
template source
  → parser
  → immutable template parts
  → typed variable lookup
  → operator-driven expansion
  → UTF-8 percent-encoded URI reference
```

The root package owns every public concrete type. Parser, encoder, and
expansion helpers are private implementation details even though they are
split into focused files in the same MoonBit package.

## Public model

`UriTemplate` is an immutable parsed template. It stores:

- the original source;
- literal and expression parts;
- variable names in first-appearance order;
- the minimum RFC 6570 feature level.

`UriValue` deliberately has only three variants:

- `Scalar(String)`;
- `List(Array[String])`;
- `Assoc(Array[(String, String)])`.

The model does not guess how numbers, booleans, or null should be serialized.
Adapters must make those conversions explicit. Ordered arrays are used for
composite values so output is reproducible across targets.

## Parser

The parser scans UTF-16 offsets because MoonBit `String` indexing uses UTF-16
code units. RFC syntax characters are ASCII, so expression boundaries cannot
split a surrogate pair.

The parser validates:

- balanced braces;
- literal percent triplets and forbidden ASCII control characters;
- standard and reserved operators;
- variable names and percent triplets;
- comma-separated variable lists;
- prefix and explode modifiers;
- prefix range `1..9999`.

Errors retain the original UTF-16 source offset. This convention matches
MoonBit string indexing and is documented as part of the public error model.

## Expansion

Each operator supplies a compact rule set:

- first prefix;
- separator;
- whether output is named;
- whether reserved characters pass through;
- suffix for an empty named value.

Scalar, list, and associative expansion use this rule set rather than eight
independent implementations. This keeps Level 4 combinations reviewable.

Undefined variables are omitted. Empty strings remain defined. Empty lists
and associative arrays are treated as undefined, as required by RFC 6570.

## Encoding

Expansion encodes variable values as UTF-8 and then emits uppercase `%HH`
triplets for disallowed octets.

Simple, label, path, path-parameter, and query operators allow only
unreserved URI characters. Reserved and fragment operators also allow
reserved characters and valid existing percent triplets.

Prefix modifiers count Unicode code points. A valid percent triplet is
treated as one character so a prefix never splits it. Non-BMP characters
advance by two MoonBit UTF-16 code units but count as one RFC character.

## Resource limits

`UriTemplate::expand` applies a default 1 MiB output limit.
`UriTemplate::expand_with_limit` lets applications choose a smaller bound.
The output is ASCII after expansion, so the final `String::length` is also the
encoded URI character count.

`UriTemplate::parse` applies defaults of 1 MiB of template text, 4,096
expressions, and 256 variables per expression. `parse_with_limits` exposes all
three bounds explicitly per call. Neither parsing nor expansion relies on
global mutable configuration.

## JSON adapter

The adapter accepts only a top-level JSON object:

- JSON string → scalar;
- array containing only strings → list;
- object containing only string values → associative value.

No implicit conversion is performed for numbers, booleans, or null. This
prevents differences in numeric formatting and application-specific null
semantics from entering the standards core.

## CLI

The CLI is a thin consumer of the public package. It does not duplicate
parsing or expansion rules.

- `validate` reports validity, level, and variable count;
- `variables` reports variables in first-appearance order;
- `inspect` reports source, level, and variables;
- `expand` loads typed variables from JSON and prints the URI.

Invalid invocation exits with code 2. Parse, JSON, file, and expansion errors
exit with code 1.

## Testing strategy

Testing has four layers:

1. black-box public API and README examples;
2. focused white-box edge cases;
3. generated interoperability tests from `uri-templates/uritemplate-test`;
4. cross-backend execution on Wasm, Wasm-GC, JavaScript, and Native.

The vendored fixture commit is fixed in `THIRD_PARTY.md`. A deterministic
PowerShell generator produces MoonBit tests, and CI rejects generated diffs.

Uncovered branches are limited to CLI process paths and defensive aborts whose
preconditions are enforced by construction.
