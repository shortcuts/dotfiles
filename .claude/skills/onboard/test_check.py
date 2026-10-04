#!/usr/bin/env python3
"""python3 test_check.py: runs check() on a note built against this dotfiles repo."""
import copy
import subprocess
from pathlib import Path

from check import check, prose, spelled

REPO = subprocess.run(["git", "rev-parse", "--show-toplevel"], cwd=Path(__file__).parent,
                      capture_output=True, text=True, check=True).stdout.strip()
SHA = subprocess.run(["git", "-C", REPO, "rev-parse", "HEAD"],
                     capture_output=True, text=True, check=True).stdout.strip()

VALID = {
    "schema": 2, "slug": "config", "title": "Dotfiles", "generated": "2026-09-29",
    "repo": {"name": "config", "path": REPO, "sha": SHA, "web": "https://github.com/o/r"},
    "scope": {"kind": "repo", "query": ""},
    "words": [{"term": "whitelist", "def": "Ignore all, then un-ignore named paths."}],
    "root": {
        "id": "", "name": "config", "kind": "repo", "path": "",
        "summary": "Shell, editor, and agent config for two Macs.",
        "role": ["One clone sets up both machines."],
        "problem": "Two Macs drift apart.",
        "principles": [{"claim": "One repo is the source.", "why": "Two Macs drift apart.",
                        "cost": "A symlink step.", "example": [["a", "b"], ["c", "d"]]}],
        "stack": [{"name": "fish", "url": "https://fishshell.com", "role": "Shell."}],
        "flow": {"nodes": [{"id": "a", "name": "fish", "end": "in"},
                           {"id": "b", "name": "Git: index", "store": True, "end": "out"}],
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
has(broken(lambda n: n.update(schema=1)), "schema")
# The root draws one shape per service, store, and outside system: no cap.
assert broken(lambda n: n["root"]["flow"]["nodes"].extend(
    {"id": f"x{i}", "name": "x"} for i in range(9))) == []
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
has(broken(lambda n: n["root"]["principles"][0]["example"].extend([["e", "f"], ["g", "h"]])),
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
has(broken(lambda n: n["root"]["principles"][0].update(**{"except": "Except: x"})), "prefix")
has(broken(lambda n: n["root"]["principles"][0].pop("why")), "needs claim, why")
# A term the repo never spells is a coined synonym: the reader cannot grep for it.
has(broken(lambda n: n["words"].append({"term": "config funnel", "def": "x"})), "config funnel")
assert check(VALID | {"words": [{"term": "Whitelist", "def": "x"}]}) == []
assert spelled(REPO, SHA, "fish function"), "fish/functions/ counts as fish function"
assert check(VALID | {"words": [{"term": "Lua", "def": "x", "from": "design doc"}]}) == []
# A defined term the prose never uses means the prose renamed it.
has(broken(lambda n: n["words"].append({"term": "mise", "def": "x"})), "'mise' is defined")
link = lambda n: n["root"]["children"][1]["links"][0]
has(broken(lambda n: link(n).update(to="nope")), "unknown node")
has(broken(lambda n: link(n).update(to=".gitignore")), "itself")
has(broken(lambda n: link(n).update(to="")), "ancestor")
has(broken(lambda n: link(n).update(label="talks to")), "link label")
has(broken(lambda n: n["root"].pop("flow")), "root: no flow")
# The root flow reads in to out: a source with no way in, a destination with no way out.
has(broken(lambda n: n["root"]["flow"]["nodes"][0].pop("end")), "source")
has(broken(lambda n: n["root"]["flow"]["nodes"][1].pop("end")), "destination")
has(broken(lambda n: n["root"]["flow"]["nodes"][0].update(end="middle")), "end")
has(broken(lambda n: n["root"]["flow"]["edges"].append(
    {"from": "b", "to": "a", "label": "call: loop"})), "no incoming")
has(broken(lambda n: n["root"]["flow"]["edges"].append(
    {"from": "a", "to": "a", "label": "call: loop"})), "no incoming")
steps = [{"text": "fish stages a file.", "at": ["a", "b"]}]
assert check(VALID | {"scope": {"kind": "feature", "query": "x"}}
             | {"root": VALID["root"] | {"kind": "feature", "path": None, "stack": None,
                                         "lifecycle": steps}}) == []
has(broken(lambda n: n["root"].update(lifecycle=["A bare string."])), "text and at")
has(broken(lambda n: n["root"].update(lifecycle=[{"text": "x", "at": ["a"]}] * 7)), "at most 6 steps")
has(broken(lambda n: n["root"].update(lifecycle=[{"text": "x", "at": ["zz"]}])), "unknown shape")
md = prose(VALID)
assert "- a: b" in md, md
assert "## nvim/lua" in md and "Lua modules." in md and "Two Macs drift apart." in md, md
# --prose runs before the note is complete, so a half-written external must not crash it.
half = copy.deepcopy(VALID)
half["root"]["children"][0]["external"] = [{"name": "OpenAI API"}]
assert "- OpenAI API: TODO" in prose(half)

SERVICE = {
    "id": "viewer", "name": "viewer", "kind": "service", "path": ".claude/.onboard",
    "summary": "The onboard viewer.", "role": ["Draws the notes."],
    "flow": {"nodes": [{"id": "i", "name": "note", "end": "in"},
                       {"id": "o", "name": "page", "end": "out"}],
             "edges": [{"from": "i", "to": "o", "label": "call: render"}]},
    "children": [{"id": ".claude/skills/onboard", "name": "onboard", "kind": "package",
                  "path": ".claude/skills/onboard", "summary": "The skill.",
                  "role": ["Writes notes."]}],
}


def with_service(mutate=None):
    note = copy.deepcopy(VALID)
    note["root"]["children"].append(copy.deepcopy(SERVICE))
    flow = note["root"]["flow"]
    flow["nodes"].append({"id": "v", "name": "viewer", "node": "viewer"})
    flow["edges"] += [{"from": "a", "to": "v", "label": "call: stage"},
                      {"from": "v", "to": "b", "label": "call: stage"}]
    if mutate:
        mutate(note)
    return check(note)


svc = lambda n: n["root"]["children"][2]
shape = lambda n: n["root"]["flow"]["nodes"][2]
assert with_service() == [], with_service()
has(with_service(lambda n: svc(n)["children"].append(
    {"id": "nvim2", "name": "nvim", "kind": "dir", "path": "nvim", "summary": "x",
     "role": ["x"]})), "under service")
assert with_service(lambda n: svc(n).update(children=[
    {"id": "pkgs", "name": "packages", "kind": "group", "path": None, "summary": "x",
     "role": ["x"], "children": SERVICE["children"]}])) == []
has(with_service(lambda n: svc(n).pop("flow")), "needs a flow")
has(with_service(lambda n: svc(n)["flow"]["nodes"][1].pop("end")), "destination")
assert with_service(lambda n: svc(n).update(
    lifecycle=[{"text": "The note renders.", "at": ["i", "o"]}])) == []
has(with_service(lambda n: svc(n).update(lifecycle=[{"text": "x", "at": ["a"]}])),
    "unknown shape")
has(with_service(lambda n: svc(n).update(lifecycle=[{"text": "x", "at": ["i"]}] * 7)),
    "at most 6 steps")
has(broken(lambda n: n["root"]["children"][0].update(
    lifecycle=[{"text": "x", "at": ["a"]}])), "root or a service")
has(with_service(lambda n: n["root"]["flow"].update(
    nodes=n["root"]["flow"]["nodes"][:2], edges=n["root"]["flow"]["edges"][:1])),
    "one root flow shape")
has(with_service(lambda n: n["root"]["flow"]["nodes"].append(
    {"id": "v2", "name": "viewer", "node": "viewer"})), "one root flow shape")
assert with_service(lambda n: n["root"]["flow"]["nodes"].append(
    {"id": "z", "name": "Algolia", "node": None})) == []
has(with_service(lambda n: shape(n).update(node="nope")), "not a node of the tree")
has(with_service(lambda n: n["root"]["flow"]["nodes"].append(
    {"id": "z", "name": "x", "node": ""})), "not a node of the tree")
has(with_service(lambda n: n["root"]["flow"]["nodes"].append(
    {"id": "z", "name": "x", "node": "nvim/lua"})), "points at package")
ext = lambda **e: lambda n: n["root"]["flow"]["nodes"].append(
    {"id": "z", "name": "metis", "external": e})
assert with_service(ext(repo="metis", url="https://github.com/o/metis")) == []
assert with_service(ext(repo="metis", url="#note=metis--index-builder")) == []
has(with_service(ext(repo="metis", url="ftp://x")), "external")
has(with_service(ext(url="https://github.com/o/metis")), "external")
has(with_service(lambda n: shape(n).update(
    external={"repo": "metis", "url": "https://github.com/o/metis"})), "external and node")
# Built at runtime: spelled() greps HEAD, so a committed literal would pass.
ghost = "Kafka: " + "xq" * 3 + " ledger"
db_edge = lambda n: n["root"]["flow"]["edges"][0].update(label="writes DB: staged files")
ghost_store = lambda n: n["root"]["flow"]["nodes"][1].update(name=ghost)
has(broken(lambda n: (db_edge(n), ghost_store(n))), "appears nowhere")
assert broken(lambda n: (db_edge(n), ghost_store(n),
                         n["root"]["flow"]["nodes"][1].update(**{"from": "billing"}))) == []
assert broken(db_edge) == []
assert broken(ghost_store) == []
svc_note = copy.deepcopy(VALID)
svc_note["root"]["children"].append(SERVICE | {"lifecycle": [{"text": "The note renders.",
                                                              "at": ["i"]}]})
assert "The note renders." in prose(svc_note)
print("ok")
