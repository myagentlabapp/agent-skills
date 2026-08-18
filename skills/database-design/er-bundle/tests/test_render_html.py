"""Tests for scripts/render_html.py."""
import json
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parent.parent
SCRIPTS = SKILL_ROOT / "scripts"
EXAMPLES = SKILL_ROOT / "examples"

sys.path.insert(0, str(SCRIPTS))
import render_html  # noqa: E402

SCRIPT_RE = re.compile(
    r'<script\s+type="application/json"\s+id="er-bundle-json">(.*?)</script>',
    re.DOTALL,
)


def extract_injected_json(html: str) -> dict:
    m = SCRIPT_RE.search(html)
    assert m, "rendered HTML has no er-bundle-json script block"
    # render_html.py escapes `<` as `<` to keep the inner JSON
    # from prematurely closing the script tag; reverse that for parsing.
    return json.loads(m.group(1).replace("\\u003c", "<"))


class TestRoundTrip(unittest.TestCase):
    def test_minimal_round_trip(self):
        bundle_path = EXAMPLES / "minimal.erd.json"
        html = render_html.render(bundle_path, EXAMPLES / "demo.html")
        got = extract_injected_json(html)
        expected = json.loads(bundle_path.read_text())
        self.assertEqual(got, expected)

    def test_ecommerce_round_trip(self):
        bundle_path = EXAMPLES / "ecommerce.erd.json"
        html = render_html.render(bundle_path, EXAMPLES / "demo.html")
        got = extract_injected_json(html)
        expected = json.loads(bundle_path.read_text())
        self.assertEqual(got, expected)
        # sanity: full ecommerce content actually made it in
        self.assertIn("cart_items", got["tables"])
        self.assertEqual(len(got["diagrams"]), 2)

    def test_team_round_trip(self):
        bundle_path = EXAMPLES / "team.erd.json"
        html = render_html.render(bundle_path, EXAMPLES / "demo.html")
        got = extract_injected_json(html)
        expected = json.loads(bundle_path.read_text())
        self.assertEqual(got, expected)


class TestSecurityEscaping(unittest.TestCase):
    def test_escapes_closing_script_tag_in_value(self):
        """A `</script>` inside a string value must not break out of the block."""
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            bundle = json.loads((EXAMPLES / "minimal.erd.json").read_text())
            bundle["meta"]["notes"] = "evil </script><img src=x onerror=alert(1)>"
            bad_path = tmp / "evil.json"
            bad_path.write_text(json.dumps(bundle))

            html = render_html.render(bad_path, EXAMPLES / "demo.html")

            # the literal `</script>` must NOT appear before the actual closing tag
            # of the bundle block (otherwise we've created an XSS vector)
            m = SCRIPT_RE.search(html)
            inner = m.group(1)
            self.assertNotIn("</script>", inner)
            self.assertNotIn("<img", inner)
            # but the original semantic content is preserved when round-tripped
            got = extract_injected_json(html)
            self.assertEqual(got["meta"]["notes"], bundle["meta"]["notes"])


class TestTemplateValidation(unittest.TestCase):
    def test_template_without_marker_raises(self):
        with tempfile.TemporaryDirectory() as tmp:
            tmp = Path(tmp)
            bad_template = tmp / "no_marker.html"
            bad_template.write_text("<html><body>nothing here</body></html>")
            with self.assertRaises(SystemExit):
                render_html.render(EXAMPLES / "minimal.erd.json", bad_template)


class TestCLI(unittest.TestCase):
    def test_writes_file_with_dash_o(self):
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / "rendered.html"
            r = subprocess.run(
                [sys.executable, str(SCRIPTS / "render_html.py"),
                 str(EXAMPLES / "ecommerce.erd.json"),
                 "-o", str(out)],
                capture_output=True, text=True, check=False,
            )
            self.assertEqual(r.returncode, 0, r.stderr)
            self.assertTrue(out.exists())
            got = extract_injected_json(out.read_text())
            self.assertIn("cart_items", got["tables"])

    def test_stdout_when_no_output_flag(self):
        r = subprocess.run(
            [sys.executable, str(SCRIPTS / "render_html.py"),
             str(EXAMPLES / "minimal.erd.json")],
            capture_output=True, text=True, check=False,
        )
        self.assertEqual(r.returncode, 0, r.stderr)
        self.assertIn('id="er-bundle-json"', r.stdout)


if __name__ == "__main__":
    unittest.main()
