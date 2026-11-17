#!/usr/bin/env python3
"""Self-check for the atlas checker. Run directly: python3 test_atlas.py"""

import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from atlas import check, merge_marks, slug

assert slug("A-GPS reset") == "a-gps-reset"
assert slug("Why the stale-fix rule applies to every pause") == "why-the-stale-fix-rule-applies-to-every-pause"
assert slug("`code` and (parens)") == "code-and-parens"

with tempfile.TemporaryDirectory() as tmp:
    root = Path(tmp)
    (root / "core/location").mkdir(parents=True)
    (root / "doc.md").write_text("# Title\n\n## Core mechanics\n")
    (root / "shot.png").write_bytes(b"png")
    model = {
        "status": "accepted",
        "bands": [{"id": "b", "title": "B"}],
        "cards": [
            {"id": "ok", "band": "b", "title": "ok", "touches": ["core/location"], "doc": "doc.md#core-mechanics", "image": "shot.png"},
            {"id": "gone", "band": "b", "title": "gone", "touches": ["core/routing"], "doc": "doc.md#missing"},
            {"id": "opt", "band": "b", "title": "opt", "kind": "option", "verdict": "maybe"},
            {"id": "ok", "band": "nope", "title": "dup", "kind": "step", "image": "none.png"},
        ],
        "edges": [{"from": "ok", "to": "ghost"}],
    }
    errors = check(model, root)
    joined = "\n".join(errors)
    for expected in [
        "gone: touches core/routing, which does not exist",
        "gone: heading #missing not in doc.md",
        "opt: verdict maybe is not open, chosen or rejected",
        "ok: duplicate id",
        "ok: unknown band nope",
        "ok: unknown kind step",
        "ok: image none.png does not exist",
        "edge ok->ghost: unknown card ghost",
    ]:
        assert expected in joined, (expected, joined)
    assert len(errors) == 8, errors
    assert check({**model, "status": "built", "cards": [], "edges": []}, root) == ["status built is not proposed, accepted or superseded"]

# The viewer sends marks without agent fields; the agent's status and reply survive a save.
old = [{"id": "m1", "text": "old", "status": "closed", "reply": "done"}, {"id": "m2", "text": "gone"}]
new = merge_marks(old, [{"id": "m1", "text": "edited"}, {"id": "m3", "text": "fresh"}])
assert new == [{"id": "m1", "text": "edited", "status": "closed", "reply": "done"}, {"id": "m3", "text": "fresh", "status": "open"}], new

print("atlas self-check passed")
