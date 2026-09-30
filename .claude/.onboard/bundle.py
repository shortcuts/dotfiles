#!/usr/bin/env python3
"""Build a one-file viewer: python3 bundle.py [<slug> ...].

Writes notes/<slug>.html with the page, the note, and ELK inlined, so the file
opens offline and travels as one attachment. With no slug, it only fetches vendor/, which
the viewer itself also loads from. check.py --install runs it for each note it installs.

It also writes one Obsidian page per note into $ONBOARD_VAULT (default: the Knowledge
folder of the iCloud vault), with a link that opens the note in the viewer.
"""
import os
import hashlib
import json
import re
import sys
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
VAULT = Path(os.environ.get("ONBOARD_VAULT", Path.home() / "Library/Mobile Documents"
                            "/iCloud~md~obsidian/Documents/notes/Knowledge")) / "Onboard"
# Pinned by hash: the page runs this code on every machine that opens a note.
VENDOR = {
    "elk.bundled.js": ("https://cdn.jsdelivr.net/npm/elkjs@0.10.2/lib/elk.bundled.js",
                       "88f7753e5b41af205d56ee4edaf6eea4fceabe0115b76c9495e5a2cee95c31d1"),
}


def vendor():
    out = {}
    for name, (url, sha) in VENDOR.items():
        path = HERE / "vendor" / name
        data = path.read_bytes() if path.exists() else b""
        if hashlib.sha256(data).hexdigest() != sha:
            # curl, because a python.org Python ships without CA certificates.
            data = subprocess.run(["curl", "-fsSL", "--max-time", "120", url],
                                  capture_output=True, check=True).stdout
            if hashlib.sha256(data).hexdigest() != sha:
                sys.exit(f"{name}: the download from {url} does not match its pinned hash")
            path.parent.mkdir(exist_ok=True)
            path.write_bytes(data)
        out[name] = data.decode()
    return out


def script(js):
    # A literal </script in inlined code would end the tag early.
    return "<script>" + re.sub(r"</(script)", r"<\\/\1", js, flags=re.I) + "</script>"


def bundle(slug, libs):
    note_js = (HERE / "notes" / f"{slug}.js").read_text()
    title = read(slug)["title"]
    page = (HERE / "index.html").read_text()
    swaps = {
        "<title>Onboard</title>": f"<title>{title.replace('&', '&amp;').replace('<', '&lt;')}</title>",
        '<link rel="stylesheet" href="app.css">': "<style>" + (HERE / "app.css").read_text() + "</style>",
        '<script src="notes/manifest.js" onerror="void 0"></script>':
            script("ONBOARD.standalone = true;\n" + note_js)
            + "".join(script(js) for js in libs.values()),
        '<script src="app.js"></script>': script((HERE / "app.js").read_text()),
    }
    for old, new in swaps.items():
        assert page.count(old) == 1, f"index.html lost {old}"
        page = page.replace(old, new)
    out = HERE / "notes" / f"{slug}.html"
    out.write_text(page)
    return out


def read(slug):
    js = (HERE / "notes" / f"{slug}.js").read_text()
    return json.loads(js.removeprefix("ONBOARD.register(").rstrip().rstrip(";").removesuffix(")"))


def page(note):
    root, r = note["root"], note["repo"]
    url = f"{(HERE / 'index.html').as_uri()}#note={note['slug']}"
    again = f"/onboard {note['scope']['query']}".strip()
    out = ["---", f"onboard-slug: {note['slug']}", f"repo: {r['name']}", f"sha: {r['sha'][:7]}",
           f"generated: {note['generated']}", f"scope: {note['scope']['kind']}", "tags: [onboard]", "---",
           f"[Open the map]({url})", "", root["summary"], "",
           f"Refresh: in `{r['path']}`, run `{again}`.",
           "", "## The problem", "", root["problem"], "", "## Principles", "",
           *(f"- {p['claim']}" for p in root["principles"]), "", "## Parts", "",
           *(f"- **{c['name']}**: {c['summary']}" for c in root.get("children", [])), "", "## Words", "",
           *(f"- **{w['term']}**: {w['def']}" for w in note["words"])]
    return "\n".join(out) + "\n"


def export(note):
    """Write the note's vault page, and drop an older page of the same note under another title."""
    if not VAULT.parent.is_dir():
        return None
    VAULT.mkdir(exist_ok=True)
    name = re.sub(r'[\\/:*?"<>|#^\[\]]', "-", note["title"]).strip() + ".md"
    for old in VAULT.glob("*.md"):
        if old.name != name and f"onboard-slug: {note['slug']}\n" in old.read_text():
            old.unlink()
    (VAULT / name).write_text(page(note))
    return VAULT / name


if __name__ == "__main__":
    libs = vendor()
    for slug in sys.argv[1:]:
        print(f"bundled {bundle(slug, libs)}")
        if path := export(read(slug)):
            print(f"wrote {path}")
