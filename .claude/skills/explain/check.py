#!/usr/bin/env python3
"""Lint an explain note: python3 check.py <note.md>. Exit 1 lists every failure."""
import re
import sys
import xml.etree.ElementTree as ET

REQUIRED = ["The problem", "The principle", "The machine", "Check yourself", "Sources"]
# Implementation receipts: repo file links, line anchors, path:line refs.
CODE_REF = re.compile(r"github\.com/\S+/(blob|tree|commit|pull)/|#L\d+|\b[\w/-]+\.\w{1,5}:\d+\b")
# Phone width in Obsidian mobile fits about this many monospace columns.
MAX_CODE_COLS = 60


def check(text):
    errors = []
    headings = re.findall(r"^##+ (.+)$", text, re.M)
    for name in REQUIRED:
        if not any(h.startswith(name) for h in headings):
            errors.append(f"missing section: {name}")

    svgs = re.findall(r"<svg\b.*?</svg>", text, re.S)
    if not svgs:
        errors.append("no SVG plate")
    for i, svg in enumerate(svgs, 1):
        # A blank line ends the markdown HTML block, so Obsidian prints the rest as text.
        if re.search(r"\n\s*\n", svg):
            errors.append(f"plate {i}: blank line inside <svg>")
        try:
            root = ET.fromstring(svg)
        except ET.ParseError as e:
            errors.append(f"plate {i}: invalid XML ({e})")
            continue
        if "viewBox" not in root.attrib:
            errors.append(f"plate {i}: no viewBox")
        if root.attrib.get("width", "100%") != "100%":
            errors.append(f"plate {i}: fixed width breaks phone layout")

    in_code, lang = False, ""
    for n, line in enumerate(text.splitlines(), 1):
        if line.startswith("```"):
            in_code, lang = not in_code, line[3:].strip()
            continue
        if in_code and lang != "mermaid" and len(line) > MAX_CODE_COLS:
            errors.append(f"line {n}: code line over {MAX_CODE_COLS} columns")
        if m := CODE_REF.search(line):
            errors.append(f"line {n}: implementation reference: {m.group(0)}")

    sources = re.search(r"^## Sources\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    if sources:
        items = re.findall(r"^- .+$", sources.group(1), re.M)
        if len(items) < 3:
            errors.append("Sources: fewer than 3 entries")
        for item in items:
            if not re.search(r"\]\(https?://[^)]+\)\S*\s+\S", item):
                errors.append(f"Sources: entry without link or annotation: {item[:60]}")
    return errors


if __name__ == "__main__":
    errors = check(open(sys.argv[1]).read())
    print("\n".join(errors) or "ok")
    sys.exit(1 if errors else 0)
