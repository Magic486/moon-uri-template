# Differential testing

The curated differential suite runs the same Level 1–4 templates and values
through:

- this MoonBit implementation;
- Python `uritemplate` 4.2.0;
- Python `std-uritemplate` 2.0.11.

The 16 cases cover every operator, scalar/list/associative values, Prefix,
Explode, Unicode, preserved percent triplets, undefined variables, and empty
scalars. Fifteen cases require byte-for-byte agreement.

One Prefix boundary is intentionally tracked as a known difference. For
`{+value:1}` with `%20tail`, this library emits `%20`, while both reference
libraries emit `%25`. RFC 6570 Sections 2.4.1 and 3.2.1 require Prefix counting
not to split a pct-encoded triplet representing one Unicode code point, so the
MoonBit result treats `%20` as the first character. The differential runner
pins all three observed outputs and fails if that behavior changes, making the
disagreement explicit rather than silently weakening conformance.

```bash
python -m pip install --require-hashes \
  -r tools/differential/requirements.txt
python tools/differential/compare.py
```

Dependencies are version- and hash-pinned. They are validation tools only and
are not linked into or distributed with the MoonBit package.
