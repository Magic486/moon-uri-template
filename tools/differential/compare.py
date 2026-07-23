"""Compare MoonBit expansion with two independent RFC 6570 implementations."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
from pathlib import Path

import uritemplate
from stduritemplate import StdUriTemplate


ROOT = Path(__file__).resolve().parents[2]
CASES = ROOT / "testdata" / "differential-cases.json"


def moon_expand(template: str, variables: dict[str, object]) -> str:
    with tempfile.NamedTemporaryFile(
        mode="w",
        suffix=".json",
        encoding="utf-8",
        delete=False,
    ) as stream:
        json.dump(variables, stream, ensure_ascii=False)
        variables_path = Path(stream.name)
    try:
        result = subprocess.run(
            [
                "moon",
                "run",
                "cmd/uri-template",
                "--",
                "expand",
                template,
                "--variables",
                str(variables_path),
            ],
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
        return result.stdout.strip()
    finally:
        variables_path.unlink(missing_ok=True)


def main() -> int:
    cases = json.loads(CASES.read_text(encoding="utf-8"))
    failures: list[str] = []
    documented_differences = 0
    for case in cases:
        template = case["template"]
        variables = case["variables"]
        outputs = {
            "moon-uri-template": moon_expand(template, variables),
            "uritemplate 4.2.0": uritemplate.expand(template, variables),
            "std-uritemplate 2.0.11": StdUriTemplate.expand(
                template,
                variables,
            ),
        }
        expected_outputs = case.get("expected_outputs")
        if expected_outputs is not None:
            documented_differences += 1
            if outputs != expected_outputs:
                failures.append(
                    f"{case['name']} changed: "
                    + ", ".join(
                        f"{name}={value!r}" for name, value in outputs.items()
                    )
                )
        elif len(set(outputs.values())) != 1:
            failures.append(
                f"{case['name']}: "
                + ", ".join(f"{name}={value!r}" for name, value in outputs.items())
            )
    if failures:
        print("Differential mismatches:", file=sys.stderr)
        for failure in failures:
            print(f"- {failure}", file=sys.stderr)
        return 1
    print(
        f"{len(cases) - documented_differences} cases agree across all three "
        f"implementations; {documented_differences} known difference is stable."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
