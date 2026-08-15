#!/usr/bin/env python3
"""Parse Claude Code stream-json log tail to show recent progress.

Usage: tail -N /tmp/claude_<job>.log | python3 parse_claude_log.py
Reads stream-json lines from stdin, prints last few assistant actions
(text or tool_use) with input_tokens so you can spot auto-compact drops.
"""
import sys
import json


def main() -> None:
    lines = [l.strip() for l in sys.stdin if l.strip()]
    if not lines:
        print("(no log lines)")
        return
    for line in lines[-8:]:
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            print("RAW:", line[:200])
            continue
        msg = d.get("message", {}) or {}
        role = msg.get("role", "?")
        content = msg.get("content", "")
        usage = msg.get("usage", {}) or {}
        inp = usage.get("input_tokens", 0)
        if isinstance(content, list):
            for c in content:
                t = c.get("type")
                if t == "text":
                    print(f"[{role}] in={inp} {c.get('text','')[:200]}")
                elif t == "tool_use":
                    print(f"[{role}] in={inp} TOOL: {c.get('name')} -> {str(c.get('input',{}))[:100]}")
        elif isinstance(content, str):
            print(f"[{role}] in={inp} {content[:200]}")


if __name__ == "__main__":
    main()
