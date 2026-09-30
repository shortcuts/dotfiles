#!/usr/bin/env python3
"""python3 test_check.py: runs check() on a note built against this dotfiles repo."""
import copy
import subprocess
from pathlib import Path

from check import check, prose

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=Path(__file__).parent,
                      capture_output=True, text=True, check=True).stdout.strip()
SHA = subprocess.run(["git", "-C", REPO, "rev-parse", "HEAD"],
                     capture_output=True, text=True, check=True).stdout.strip()

VALID = {
    "schema": 1, "slug": "config", "title": "Dotfiles", "generated": "2026-09-29",
    "repo": {"name": "config", "path": REPO, "sha": SHA, "web": "https://github.com/o/r"},
    "scope": {"kind": "repo", "query": ""},
    "words": [{"term": "whitelist", "def": "Ignore all, then un-ignore named paths."}],
    "root": {
        "id": "", "name": "config", "kind": "repo", "path": "",
        "summary": "Shell, editor, and agent config for two Macs.",
        "role": ["One clone sets up both machines."],
        "problem": "Two Macs drift apart.",
        "principles": [{"claim": "One repo is the source.", "cost": "A symlink step.",
                        "mammoth": {"rows": [["a", "b"], ["c", "d"]], "breaks": "x"}}],
        "stack": [{"name": "fish", "url": "https://fishshell.com", "role": "Shell."}],
        "flow": {"nodes": [{"id": "a", "name": "fish"}, {"id": "b", "name": "Git: index", "store": True}],
                 "edges": [{"from": "a", "to": "b", "label": "call: git add"}]},
        "children": [
            {"id": "nvim", "name": "nvim", "kind": "dir", "path": "nvim",
             "summary": "Neovim config.", "role": ["Editor."], "children": [
                 {"id": "nvim/lua", "name": "lua", "kind": "package", "path": "nvim/lua",
                  "summary": "Lua modules.", "role": ["Plugins."],
                  "entry": [{"name": "init", "path": "nvim/init.lua", "lines": [1, 2],
                             "note": "Loads lua."}]}]},
            {"id": ".gitignore", "name": ".gitignore", "kind": "file", "path": ".gitignore",
             "summary": "Whitelist of tracked paths.", "role": ["Ignores all first."],
             "links": [{"to": "nvim/lua", "label": "file: tracked paths"}]},
        ],
    },
}


def broken(mutate):
    note = copy.deepcopy(VALID)
    mutate(note)
    return check(note)


def has(errors, fragment):
    assert any(fragment in e for e in errors), f"expected {fragment!r} in {errors}"


assert check(VALID) == [], check(VALID)
has(broken(lambda n: n["root"]["children"][0].update(path="nvim/nope")), "not tracked")
has(broken(lambda n: n["root"]["children"][0]["children"][0]["entry"][0]
           .update(path="nvim")), "not a tracked file")
has(broken(lambda n: n["root"]["children"][0]["children"][0]
           .update(children=[copy.deepcopy(VALID["root"]["children"][1])])),
    "package has children")
has(broken(lambda n: n["root"].update(summary="x" * 141)), "summary")
has(broken(lambda n: n["root"].pop("principles")), "principles")
has(broken(lambda n: n["root"].pop("stack")), "stack")
has(broken(lambda n: n["root"].update(flow="flowchart LR\n  a -->|call| b")), "flow")
has(broken(lambda n: n["root"]["flow"]["edges"][0].update(label="maybe")), "flow label")
has(broken(lambda n: n["root"]["flow"]["edges"][0].update(to="c")), "unknown shape")
has(broken(lambda n: n["root"]["flow"]["nodes"].extend(
    {"id": f"x{i}", "name": "x"} for i in range(6))), "at most 7")
child_flow = copy.deepcopy(VALID["root"]["flow"])
child_flow["nodes"] += [{"id": f"x{i}", "name": "x"} for i in range(8)]
assert check(copy.deepcopy(VALID) | {"root": VALID["root"] | {"children": [
    VALID["root"]["children"][0] | {"flow": child_flow}, VALID["root"]["children"][1]]}}) == []
child_flow["nodes"] += [{"id": f"y{i}", "name": "y"} for i in range(3)]
has(check(copy.deepcopy(VALID) | {"root": VALID["root"] | {"children": [
    VALID["root"]["children"][0] | {"flow": child_flow}, VALID["root"]["children"][1]]}}), "at most 12")
has(broken(lambda n: n["root"].update(role=["One.", "Two."])), "one paragraph")
has(broken(lambda n: n["root"]["children"][0].update(role=["x" * 161])), "role over")
has(broken(lambda n: n["root"].update(problem="x" * 241)), "problem over")
has(broken(lambda n: n["root"]["principles"][0]["mammoth"]["rows"].extend([["e", "f"], ["g", "h"]])),
    "2 or 3 rows")
has(broken(lambda n: n["root"]["principles"][0].update(claim="The row stores last_job_id.")),
    "identifier")
has(broken(lambda n: n["root"]["principles"][0].update(cost="It reads `jobs`.")), "identifier")
has(broken(lambda n: n["root"]["children"][1].update(id="nvim")), "duplicate id")
has(broken(lambda n: n.update(slug="Bad Slug")), "slug")
has(broken(lambda n: n["scope"].update(kind="function")), "io")
has(broken(lambda n: n["root"].update(problem="TODO")), "unfilled")
has(broken(lambda n: n["root"]["stack"][0].update(url="TODO")), "unfilled")
assert check(VALID | {"_index": {}}) == [], "underscore keys are hints, not errors"
has(broken(lambda n: n["root"]["principles"][0]["mammoth"].update(breaks="Breaks down at: x")),
    "prefix")
link = lambda n: n["root"]["children"][1]["links"][0]
has(broken(lambda n: link(n).update(to="nope")), "unknown node")
has(broken(lambda n: link(n).update(to=".gitignore")), "itself")
has(broken(lambda n: link(n).update(to="")), "ancestor")
has(broken(lambda n: link(n).update(label="talks to")), "link label")
has(broken(lambda n: n["root"].pop("flow")), "root: no flow")
steps = [{"text": "fish stages a file.", "at": ["a", "b"]}]
assert check(VALID | {"scope": {"kind": "feature", "query": "x"}}
             | {"root": VALID["root"] | {"kind": "feature", "path": None, "stack": None,
                                         "lifecycle": steps}}) == []
has(broken(lambda n: n["root"].update(lifecycle=["A bare string."])), "text and at")
has(broken(lambda n: n["root"].update(lifecycle=[{"text": "x", "at": ["a"]}] * 7)), "at most 6 steps")
has(broken(lambda n: n["root"].update(lifecycle=[{"text": "x", "at": ["zz"]}])), "unknown shape")
md = prose(VALID)
assert "## nvim/lua" in md and "Lua modules." in md and "Two Macs drift apart." in md, md
# --prose runs before the note is complete, so a half-written external must not crash it.
half = copy.deepcopy(VALID)
half["root"]["children"][0]["external"] = [{"name": "OpenAI API"}]
assert "- OpenAI API: TODO" in prose(half)
print("ok")
