#!/usr/bin/env python3
"""Inject a bundle JSON into a demo.html template and write the result.

Usage:
    python3 scripts/render_html.py <bundle.json> [--template path/to/demo.html] [-o out.html]

Defaults:
    --template  examples/demo.html  (relative to this skill root)
    -o          stdout

The template must contain exactly one block matching
    <script type="application/json" id="er-bundle-json">...</script>
The content between the tags is replaced with the bundle JSON.
"""
import argparse
import json
import re
import sys
from pathlib import Path

SCRIPT_BLOCK = re.compile(
    r'(<script\s+type="application/json"\s+id="er-bundle-json">)(.*?)(</script>)',
    re.DOTALL,
)


def render(bundle_path: Path, template_path: Path) -> str:
    bundle = json.loads(bundle_path.read_text())
    template = template_path.read_text()
    if not SCRIPT_BLOCK.search(template):
        raise SystemExit(
            f"ERROR: template {template_path} has no "
            "<script type=\"application/json\" id=\"er-bundle-json\"> block"
        )
    # ensure_ascii=False keeps Chinese readable; escape `<` to avoid
    # accidentally closing the script tag if a value contains `</script>`.
    payload = json.dumps(bundle, ensure_ascii=False, indent=2).replace("<", "\\u003c")
    return SCRIPT_BLOCK.sub(
        lambda m: f"{m.group(1)}\n{payload}\n{m.group(3)}",
        template,
        count=1,
    )


def main(argv: list[str]) -> int:
    skill_root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("bundle", type=Path, help="path to .erd.json")
    parser.add_argument("--template", type=Path, default=skill_root / "examples" / "demo.html")
    parser.add_argument("-o", "--output", type=Path, help="output HTML path (default: stdout)")
    args = parser.parse_args(argv[1:])

    html = render(args.bundle, args.template)
    if args.output:
        args.output.write_text(html)
        print(f"wrote {args.output}", file=sys.stderr)
    else:
        sys.stdout.write(html)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
