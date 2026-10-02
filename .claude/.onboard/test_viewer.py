#!/usr/bin/env python3
"""python3 test_viewer.py: draws a note in headless Chrome and checks the rendered page."""
import json
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

NOTE = {
    "schema": 1, "slug": "t", "title": "T", "generated": "2026-10-02",
    "repo": {"name": "t", "path": "/t", "sha": "0" * 40, "web": None},
    "scope": {"kind": "repo", "query": ""},
    "words": [{"term": "render job", "def": "One report to build."}],
    "root": {
        "id": "", "name": "t", "kind": "repo", "path": "",
        "summary": "Builds one Render Job.", "role": ["Each render job runs alone."],
        "problem": "A render job is slow, and a render job blocks.",
        "children": [],
    },
}


def dom():
    with tempfile.TemporaryDirectory() as d:
        for f in ("index.html", "app.js", "app.css"):
            shutil.copy(HERE / f, d)
        (Path(d) / "notes").mkdir()
        (Path(d) / "notes/manifest.js").write_text('ONBOARD.manifest([{"slug": "t", "title": "T"}]);')
        (Path(d) / "notes/t.js").write_text(f"ONBOARD.register({json.dumps(NOTE)});")
        return subprocess.run([CHROME, "--headless", "--disable-gpu", "--virtual-time-budget=3000",
                               "--dump-dom", f"file://{d}/index.html"],
                              capture_output=True, text=True, timeout=60).stdout


def test_word_marks_jump_to_the_words():
    page = dom()
    assert 'id="word-render-job"' in page, "the words section names each term"
    # One mark per term per block: the panel lead, the role, and the problem.
    assert page.count('class="wref"') == 3, page.count('class="wref"')
    assert "Render Job<sup>" in page, "the mark sits right after the term, in any case"


if __name__ == "__main__":
    if not Path(CHROME).exists():
        raise SystemExit("skip: no Google Chrome")
    test_word_marks_jump_to_the_words()
    print("ok")
