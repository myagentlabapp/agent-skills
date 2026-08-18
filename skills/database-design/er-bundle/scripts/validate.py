#!/usr/bin/env python3
"""Validate an .erd.json bundle against references/schema.json.

Usage: python3 scripts/validate.py <bundle.json> [<bundle2.json> ...]
Exit code 0 if all valid, 1 otherwise.
"""
import json
import sys
from pathlib import Path

try:
    from jsonschema import Draft202012Validator
except ImportError:
    print("ERROR: jsonschema not installed. Run: pip install --user jsonschema", file=sys.stderr)
    sys.exit(2)


def cross_check(bundle: dict) -> list[str]:
    """Catch errors the JSON Schema can't express."""
    errs: list[str] = []
    layers = set(bundle.get("layers", {}).keys())
    tables = bundle.get("tables", {})
    table_names = set(tables.keys())

    for tname, t in tables.items():
        if t.get("layer") not in layers:
            errs.append(f"tables.{tname}.layer = {t.get('layer')!r} not in layers")
        for col in t.get("cols", []):
            if col.get("tag") == "FK":
                ref = col.get("ref", "").split(".")[0]
                if ref and ref not in table_names:
                    errs.append(f"tables.{tname}.cols[{col['name']}].ref → {ref!r} (unknown table)")

    for i, d in enumerate(bundle.get("diagrams", [])):
        pos_keys = set(d.get("positions", {}).keys())
        unknown = pos_keys - table_names
        if unknown:
            errs.append(f"diagrams[{i}={d.get('id')}].positions has unknown tables: {sorted(unknown)}")
        for c in d.get("connections", []):
            for end in ("from", "to"):
                if c.get(end) not in pos_keys:
                    errs.append(
                        f"diagrams[{i}={d.get('id')}].connection {c.get('from')}→{c.get('to')}: "
                        f"{end}={c.get(end)!r} not in this diagram's positions"
                    )
    return errs


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2

    schema_path = Path(__file__).resolve().parent.parent / "references" / "schema.json"
    schema = json.loads(schema_path.read_text())
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema)

    fail = False
    for arg in argv[1:]:
        path = Path(arg)
        try:
            bundle = json.loads(path.read_text())
        except Exception as e:
            print(f"FAIL {path}: cannot parse JSON — {e}")
            fail = True
            continue

        schema_errs = sorted(validator.iter_errors(bundle), key=lambda e: list(e.absolute_path))
        cross_errs = cross_check(bundle)

        if schema_errs or cross_errs:
            print(f"FAIL {path}")
            for e in schema_errs:
                loc = ".".join(str(p) for p in e.absolute_path) or "(root)"
                print(f"  schema  @ {loc}: {e.message}")
            for msg in cross_errs:
                print(f"  cross   {msg}")
            fail = True
        else:
            print(f"OK   {path}")

    return 1 if fail else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
