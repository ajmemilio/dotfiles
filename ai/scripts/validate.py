#!/usr/bin/env python3
"""Check skills have valid, portable frontmatter. Stdlib only.

Usage: validate.py [skills_dir ...]   (default: ai/skills next to this script)
"""
import re
import sys
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
MAX_NAME, MAX_DESC, MAX_LINES = 64, 1024, 500


def frontmatter(text: str) -> dict[str, str] | None:
    m = re.match(r"^---\n(.*?)\n---\n", text, re.S)
    if not m:
        return None
    out: dict[str, str] = {}
    for line in m.group(1).splitlines():
        if ":" in line and not line.startswith((" ", "\t")):
            k, v = line.split(":", 1)
            out[k.strip()] = v.strip().strip('"').strip("'")
    return out


def check(skill_dir: Path) -> list[str]:
    md = skill_dir / "SKILL.md"
    if not md.exists():
        return ["missing SKILL.md"]
    text = md.read_text(encoding="utf-8")
    fm = frontmatter(text)
    if fm is None:
        return ["SKILL.md has no YAML frontmatter (--- ... ---)"]
    errs: list[str] = []
    name, desc = fm.get("name", ""), fm.get("description", "")
    if not name:
        errs.append("frontmatter: missing name")
    elif name != skill_dir.name:
        errs.append(f"frontmatter name '{name}' != folder '{skill_dir.name}'")
    elif not NAME_RE.match(name) or len(name) > MAX_NAME:
        errs.append(f"name '{name}' must be lowercase-hyphenated, <= {MAX_NAME} chars")
    if not desc:
        errs.append("frontmatter: missing description")
    elif len(desc) > MAX_DESC:
        errs.append(f"description is {len(desc)} chars (> {MAX_DESC})")
    if text.count("\n") > MAX_LINES:
        errs.append(f"SKILL.md over {MAX_LINES} lines; move detail into references/")
    for ref in re.findall(r"`((?:scripts|references|assets)/[^`\s]+)`", text):
        if not (skill_dir / ref).exists():
            errs.append(f"referenced file not found: {ref}")
    return errs


def main(argv: list[str]) -> int:
    roots = [Path(a) for a in argv] or [Path(__file__).resolve().parent.parent / "skills"]
    dirs = sorted(d for r in roots for d in r.iterdir() if d.is_dir() and not d.name.startswith("_"))
    failed = 0
    for d in dirs:
        errs = check(d)
        print(f"{'✗' if errs else '✓'} {d.name}")
        for e in errs:
            print(f"    - {e}")
        failed += bool(errs)
    print(f"\n{len(dirs) - failed}/{len(dirs)} skills valid")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
