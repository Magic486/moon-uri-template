# Performance benchmarks

The benchmark suite measures two representative operations independently:

- parsing a Level 4 API endpoint template;
- expanding the already parsed template with scalar and exploded list values.

Run the native release benchmark with:

```bash
moon bench --target native --release
```

## Local baseline

Recorded on 2026-07-23 with:

- Windows AMD64;
- Intel64 Family 6 Model 154;
- MoonBit `moon 0.1.20260703`;
- `moonc v0.10.3+16975d007`;
- native release target.

| Benchmark | Mean | Standard deviation |
|---|---:|---:|
| Parse representative Level 4 template | 1.72 µs | 39.05 ns |
| Expand cached representative template | 3.47 µs | 175.63 ns |

These numbers are a regression baseline for this machine, not a
cross-machine performance guarantee. Benchmark source lives in
`benchmark_test.mbt`; contributors should report toolchain, target, and
hardware when publishing comparisons.
