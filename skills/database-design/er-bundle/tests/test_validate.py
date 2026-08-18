"""Tests for scripts/validate.py.

Run: python3 -m unittest discover -s skills/er-bundle/tests
"""
import copy
import json
import subprocess
import sys
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = SKILL_ROOT / "scripts"
EXAMPLES = SKILL_ROOT / "examples"

sys.path.insert(0, str(SCRIPTS))
import validate  # noqa: E402

from jsonschema import Draft202012Validator  # noqa: E402

SCHEMA = json.loads((SKILL_ROOT / "references" / "schema.json").read_text())
VALIDATOR = Draft202012Validator(SCHEMA)


def schema_errors(bundle: dict) -> list[str]:
    return [
        f"{'.'.join(str(p) for p in e.absolute_path) or '(root)'}: {e.message}"
        for e in VALIDATOR.iter_errors(bundle)
    ]


def good_bundle() -> dict:
    return copy.deepcopy(json.loads((EXAMPLES / "minimal.erd.json").read_text()))


class TestSchemaIsItselfValid(unittest.TestCase):
    def test_schema_meta(self):
        Draft202012Validator.check_schema(SCHEMA)


class TestGoodExamples(unittest.TestCase):
    def test_minimal_passes_schema(self):
        bundle = good_bundle()
        self.assertEqual(schema_errors(bundle), [])

    def test_minimal_passes_cross_check(self):
        self.assertEqual(validate.cross_check(good_bundle()), [])

    def test_ecommerce_passes_schema(self):
        bundle = json.loads((EXAMPLES / "ecommerce.erd.json").read_text())
        self.assertEqual(schema_errors(bundle), [])

    def test_ecommerce_passes_cross_check(self):
        bundle = json.loads((EXAMPLES / "ecommerce.erd.json").read_text())
        self.assertEqual(validate.cross_check(bundle), [])

    def test_team_passes_schema(self):
        bundle = json.loads((EXAMPLES / "team.erd.json").read_text())
        self.assertEqual(schema_errors(bundle), [])

    def test_team_passes_cross_check(self):
        bundle = json.loads((EXAMPLES / "team.erd.json").read_text())
        self.assertEqual(validate.cross_check(bundle), [])

    def test_team_uses_optional_cardinality(self):
        """The team example is our canonical 0:1 / 0:N showcase — guard against
        someone silently downgrading it to plain 1:N."""
        bundle = json.loads((EXAMPLES / "team.erd.json").read_text())
        cards = {c.get("cardinality") for d in bundle["diagrams"] for c in d["connections"]}
        self.assertIn("0:N", cards)
        self.assertIn("0:1", cards)


class TestSchemaRejects(unittest.TestCase):
    """Cases the JSON Schema itself must catch."""

    def test_missing_required_meta(self):
        b = good_bundle()
        del b["meta"]
        self.assertTrue(schema_errors(b), "expected at least one error when meta missing")

    def test_meta_without_title(self):
        b = good_bundle()
        b["meta"] = {"version": "1.0"}
        errs = schema_errors(b)
        self.assertTrue(any("title" in e for e in errs), errs)

    def test_unknown_top_level_property(self):
        b = good_bundle()
        b["bogusKey"] = 1
        self.assertTrue(schema_errors(b))

    def test_col_invalid_tag(self):
        b = good_bundle()
        b["tables"]["accounts"]["cols"][0]["tag"] = "WAT"
        self.assertTrue(schema_errors(b))

    def test_col_invalid_onDelete(self):
        b = good_bundle()
        b["tables"]["sessions"]["cols"][1]["onDelete"] = "BOOM"
        self.assertTrue(schema_errors(b))

    def test_connection_invalid_cardinality(self):
        b = good_bundle()
        b["diagrams"][0]["connections"][0]["cardinality"] = "many-to-some"
        self.assertTrue(schema_errors(b))

    def test_connection_accepts_optional_cardinality(self):
        """0:1 and 0:N were added in v0.4 — guard the enum."""
        for value in ("0:1", "0:N"):
            with self.subTest(value=value):
                b = good_bundle()
                b["diagrams"][0]["connections"][0]["cardinality"] = value
                self.assertEqual(schema_errors(b), [])

    def test_table_constraint_missing_cols(self):
        b = good_bundle()
        b["tables"]["accounts"]["tableConstraints"] = [{"type": "PK"}]
        self.assertTrue(schema_errors(b))

    def test_diagram_id_bad_pattern(self):
        b = good_bundle()
        b["diagrams"][0]["id"] = "Has-Caps"
        self.assertTrue(schema_errors(b))

    def test_canvas_below_minimum(self):
        b = good_bundle()
        b["diagrams"][0]["canvas"]["w"] = 10
        self.assertTrue(schema_errors(b))


class TestCrossCheck(unittest.TestCase):
    """Cases JSON Schema can't express; cross_check must catch."""

    def test_table_layer_unknown(self):
        b = good_bundle()
        b["tables"]["accounts"]["layer"] = "ghost_layer"
        errs = validate.cross_check(b)
        self.assertTrue(any("layer" in e and "ghost_layer" in e for e in errs), errs)

    def test_fk_ref_to_unknown_table(self):
        b = good_bundle()
        b["tables"]["sessions"]["cols"][1]["ref"] = "nope"
        errs = validate.cross_check(b)
        self.assertTrue(any("nope" in e for e in errs), errs)

    def test_positions_has_unknown_table(self):
        b = good_bundle()
        b["diagrams"][0]["positions"]["ghosts"] = {"cx": 50, "cy": 50}
        errs = validate.cross_check(b)
        self.assertTrue(any("ghosts" in e and "unknown" in e for e in errs), errs)

    def test_connection_endpoint_not_in_positions(self):
        b = good_bundle()
        b["diagrams"][0]["connections"].append(
            {"from": "accounts", "to": "missing_table", "label": "x"}
        )
        errs = validate.cross_check(b)
        self.assertTrue(any("missing_table" in e for e in errs), errs)

    def test_fk_ref_with_column_form(self):
        """`ref: 'table.col'` should resolve table by splitting on '.'."""
        b = good_bundle()
        b["tables"]["sessions"]["cols"][1]["ref"] = "accounts.id"
        self.assertEqual(validate.cross_check(b), [])


class TestCLI(unittest.TestCase):
    def test_cli_ok_exit_zero(self):
        r = subprocess.run(
            [sys.executable, str(SCRIPTS / "validate.py"),
             str(EXAMPLES / "minimal.erd.json"),
             str(EXAMPLES / "ecommerce.erd.json")],
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(r.returncode, 0, r.stdout + r.stderr)
        self.assertIn("OK", r.stdout)

    def test_cli_bad_exit_nonzero(self):
        bad = SKILL_ROOT / "tests" / "_tmp_bad.json"
        b = good_bundle()
        b["tables"]["accounts"]["layer"] = "nope"
        bad.write_text(json.dumps(b))
        try:
            r = subprocess.run(
                [sys.executable, str(SCRIPTS / "validate.py"), str(bad)],
                capture_output=True, text=True, check=False,
            )
            self.assertEqual(r.returncode, 1, r.stdout)
            self.assertIn("FAIL", r.stdout)
        finally:
            bad.unlink(missing_ok=True)


if __name__ == "__main__":
    unittest.main()
