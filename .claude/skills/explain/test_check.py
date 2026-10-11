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
        "overview": "One clone sets up both Macs. Fish and Git keep them alike.",
        "principles": [{"claim": "One repo is the source.", "why": "Two Macs drift apart.",
                        "cost": "A symlink step.", "example": [["a", "b"], ["c", "d"]]}],
        "stack": [{"name": "fish", "url": "https://fishshell.com", "role": "Shell."}],
        "sources": [{"title": "fish docs", "url": "https://fishshell.com/docs/current/",
                     "why": "The shell's own manual. Read the tutorial first."}],
        "check": [{"q": "Where does a new Mac get its config?", "a": "From one clone."},
                  {"q": "What breaks if the symlink is missing?", "a": "Claude Code finds no skills."},
                  {"q": "Why a whitelist?", "a": "A new file stays private until named."}],
        "flow": {"nodes": [{"id": "a", "name": "fish", "end": "in", "about": "The shell."},
                           {"id": "b", "name": "Git: index", "store": True, "end": "out",
                            "about": "The staged files."}],
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
    {"id": f"x{i}", "name": "x", "about": "x"} for i in range(9))) == []
child_flow = copy.deepcopy(VALID["root"]["flow"])
child_flow["nodes"] += [{"id": f"x{i}", "name": "x"} for i in range(8)]
assert check(copy.deepcopy(VALID) | {"root": VALID["root"] | {"children": [
    VALID["root"]["children"][0] | {"flow": child_flow}, VALID["root"]["children"][1]]}}) == []
child_flow["nodes"] += [{"id": f"y{i}", "name": "y"} for i in range(5)]
has(check(copy.deepcopy(VALID) | {"root": VALID["root"] | {"children": [
    VALID["root"]["children"][0] | {"flow": child_flow}, VALID["root"]["children"][1]]}}), "at most 14")
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
# A two-way edge reads in both directions, so it never makes a source or a destination.
assert broken(lambda n: n["root"]["flow"]["edges"].append(
    {"from": "b", "to": "a", "label": "call: read", "both": True})) == [], "both edge on an end"
has(broken(lambda n: n["root"]["flow"]["edges"].append(
    {"from": "a", "to": "b", "label": "call: x", "both": "yes"})), "both")
has(broken(lambda n: n["root"]["flow"]["edges"].append(
    {"from": "a", "to": "b", "label": "call: x", "back": "yes"})), "back is true or false")
has(broken(lambda n: n["root"]["flow"]["nodes"][0].update(decision="yes")), "decision")
steps = [{"text": "fish stages a file.", "at": ["a", "b"], "detail": "Git records it."}]
assert check(VALID | {"scope": {"kind": "feature", "query": "x"}}
             | {"root": VALID["root"] | {"kind": "feature", "path": None, "stack": None,
                                         "lifecycle": steps}}) == []
has(broken(lambda n: n["root"].update(lifecycle=["A bare string."])), "text and at")
has(broken(lambda n: n["root"].update(lifecycle=[{"text": "x", "at": ["a"]}] * 8)), "at most 7 steps")
has(broken(lambda n: n["root"].update(lifecycle=[{"text": "x", "at": ["zz"]}])), "unknown shape")
has(broken(lambda n: n["root"].update(lifecycle=[{"text": "x", "at": ["a"]}])), "needs a detail")
has(broken(lambda n: n["root"].pop("overview")), "no overview")
has(broken(lambda n: n["root"].update(overview="One sentence only.")), "2 to 5 sentences")
has(broken(lambda n: n["root"]["flow"]["nodes"][0].pop("about")), "needs an about")
md = prose(VALID)
assert "- a: b" in md, md
assert "## nvim/lua" in md and "Lua modules." in md and "Two Macs drift apart." in md, md
# --prose runs before the note is complete, so a half-written external must not crash it.
half = copy.deepcopy(VALID)
half["root"]["children"][0]["external"] = [{"name": "OpenAI API"}]
assert "- OpenAI API: TODO" in prose(half)

SERVICE = {
    "id": "viewer", "name": "viewer", "kind": "service", "path": "fish",
    "summary": "The fish config.", "role": ["Draws the notes."],
    "flow": {"nodes": [{"id": "i", "name": "note", "end": "in"},
                       {"id": "o", "name": "page", "end": "out"}],
             "edges": [{"from": "i", "to": "o", "label": "call: render"}]},
    "children": [{"id": "fish/functions", "name": "functions", "kind": "package",
                  "path": "fish/functions", "summary": "Git helpers.",
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
has(with_service(lambda n: svc(n).update(lifecycle=[{"text": "x", "at": ["i"]}] * 8)),
    "at most 7 steps")
has(broken(lambda n: n["root"]["children"][0].update(
    lifecycle=[{"text": "x", "at": ["a"]}])), "a node with a flow")
has(with_service(lambda n: n["root"]["flow"].update(
    nodes=n["root"]["flow"]["nodes"][:2], edges=n["root"]["flow"]["edges"][:1])),
    "one root flow shape")
has(with_service(lambda n: n["root"]["flow"]["nodes"].append(
    {"id": "v2", "name": "viewer", "node": "viewer"})), "one root flow shape")
assert with_service(lambda n: n["root"]["flow"]["nodes"].append(
    {"id": "z", "name": "Algolia", "node": None, "about": "x"})) == []
has(with_service(lambda n: shape(n).update(node="nope")), "not a node of the tree")
has(with_service(lambda n: n["root"]["flow"]["nodes"].append(
    {"id": "z", "name": "x", "node": ""})), "not a node of the tree")
has(with_service(lambda n: n["root"]["flow"]["nodes"].append(
    {"id": "z", "name": "x", "node": "nvim/lua"})), "points at package")
ext = lambda **e: lambda n: n["root"]["flow"]["nodes"].append(
    {"id": "z", "name": "metis", "external": e, "about": "x"})
assert with_service(ext(repo="metis", url="https://github.com/o/metis")) == []
assert with_service(ext(repo="metis", url="#note=metis--index-builder")) == []
has(with_service(ext(repo="metis", url="ftp://x")), "external")
has(with_service(ext(url="https://github.com/o/metis")), "external")
has(with_service(lambda n: shape(n).update(
    external={"repo": "metis", "url": "https://github.com/o/metis"})), "external and node")
assert broken(lambda n: n["root"]["flow"]["nodes"][0].update(group="Model providers")) == []
has(broken(lambda n: n["root"]["flow"]["nodes"][0].update(group="")), "group")
has(broken(lambda n: n["root"]["flow"]["nodes"][0].update(group="x" * 40)), "group")
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

# A part's flow reads like the map: a dir with a flow takes steps, a shape links its doc.
PART_FLOW = {"nodes": [{"id": "i", "name": "fish", "end": "in", "about": "The shell.", "doc": ".gitignore#top"},
                       {"id": "o", "name": "nvim", "end": "out"}],
             "edges": [{"from": "i", "to": "o", "label": "call: open"}]}
assert broken(lambda n: n["root"]["children"][0].update(flow=copy.deepcopy(PART_FLOW),
    lifecycle=[{"text": "Fish opens nvim.", "at": ["i", "o"], "detail": "The shell starts the editor."}])) == []
has(broken(lambda n: n["root"]["children"][0].update(flow=copy.deepcopy(PART_FLOW) | {"nodes": [
    PART_FLOW["nodes"][0] | {"doc": "nope.md#x"}, PART_FLOW["nodes"][1]]})), "doc")
has(broken(lambda n: n["root"]["children"][0].update(flow=copy.deepcopy(PART_FLOW),
    lifecycle=[{"text": "x", "at": ["i"], "detail": "x" * 481}])), "detail over")
has(broken(lambda n: n["root"]["children"][0].update(flow=copy.deepcopy(PART_FLOW) | {"nodes": [
    PART_FLOW["nodes"][0] | {"about": "x" * 301}, PART_FLOW["nodes"][1]]})), "about over")
assert "Fish opens nvim." in prose(VALID | {"root": VALID["root"] | {"children": [VALID["root"]["children"][0] | {
    "flow": PART_FLOW, "lifecycle": [{"text": "x", "at": ["i"], "detail": "Fish opens nvim."}]}]}})
print("ok")

# Ramp-up: every note ends with questions to check yourself and the sources to go further.
has(broken(lambda n: n["root"].pop("sources")), "sources")
has(broken(lambda n: n["root"]["sources"][0].update(url="ftp://x")), "sources")
has(broken(lambda n: n["root"]["sources"][0].pop("why")), "sources")
has(broken(lambda n: n["root"].pop("check")), "check")
has(broken(lambda n: n["root"]["check"].pop()), "check")
has(broken(lambda n: n["root"]["check"][0].update(q="x " * 16)), "15 words")
has(broken(lambda n: n["root"]["check"][0].pop("a")), "check")
assert broken(lambda n: n["root"].update(further=[{"q": "How do two Macs share secrets?", "source": 1, "at": "tutorial"}])) == []
has(broken(lambda n: n["root"].update(further=[{"q": "x?", "source": 2, "at": "x"}])), "further")
# A sketch is an SVG the note inlines, so it must parse and carry nothing that runs.
SKETCH = ('<svg viewBox="0 0 360 120" xmlns="http://www.w3.org/2000/svg"><rect x="10" y="10" width="80" height="40"/>'
          '<text x="20" y="30">ring</text></svg>')
plate = lambda svg, **kw: lambda n: n["root"].update(plates=[{"title": "The ring", "svg": svg, "key": ["Ring: the hash space."],
    "caption": "Each key walks clockwise to the next of 3 servers."} | kw])
assert broken(plate(SKETCH)) == []
has(broken(plate("<svg viewBox='0 0 1 1'><rect></svg>")), "invalid XML")
has(broken(plate(SKETCH.replace(' viewBox="0 0 360 120"', ""))), "viewBox")
has(broken(plate(SKETCH.replace("<rect", '<rect onclick="x()"'))), "onclick")
has(broken(plate(SKETCH.replace("<text", "<script>x()</script><text"))), "script")
has(broken(plate(SKETCH.replace("<text", '<image href="https://x/y.png"/><text'))), "image")
has(broken(plate(SKETCH, key=[])), "key")
# A key line per drawn callout, no more, no less: count what you draw.
CALLOUTS = SKETCH.replace("</svg>", '<text x="5" y="5">1</text><text x="5" y="20">2</text></svg>')
has(broken(plate(CALLOUTS)), "callout")
assert broken(plate(CALLOUTS, key=["Ring: holds the hash space.", "Server: owns one arc."])) == []
has(broken(plate(SKETCH, caption="")), "caption")
# A style url() loads from the network as surely as an href does.
has(broken(plate(SKETCH.replace("<rect", '<rect style="fill:url(https://x/y)"'))), "url(")
assert broken(plate(SKETCH.replace("<rect", '<rect style="fill:url(#hatch)"'))) == []

# A concept has no repo: the sources carry the evidence, and the flow is the machine.
CONCEPT = {
    "schema": 2, "slug": "consistent-hashing", "title": "Consistent hashing", "generated": "2026-10-11",
    "repo": None, "scope": {"kind": "concept", "query": "consistent hashing"},
    "words": [{"term": "ring", "def": "The hash space bent into a circle."}],
    "root": {
        "id": "", "name": "Consistent hashing", "kind": "concept", "path": None,
        "summary": "Spreads keys over servers so a new server moves few keys.",
        "role": ["A cache cluster grows without a cold start."],
        "problem": "With hash mod N, one new cache server remaps almost every key.",
        "overview": "Each key and each server hashes onto one ring. A key goes to the next server clockwise.",
        "principles": [{"claim": "A key moves only when its own arc changes owner.", "why": "Each server owns one arc.",
                        "cost": "Arcs differ in size.", "source": 1, "example": [["Add server D", "Only keys on D's arc move."],
                                                                    ["Remove server B", "B's keys go to C."]]}],
        "flow": {"nodes": [{"id": "k", "name": "key", "end": "in", "about": "A cache key."},
                           {"id": "r", "name": "ring", "about": "The hash space as a circle."},
                           {"id": "s", "name": "server", "end": "out", "about": "The next server clockwise."}],
                 "edges": [{"from": "k", "to": "r", "label": "call: hash"}, {"from": "r", "to": "s", "label": "call: walk"}]},
        "lifecycle": [{"text": "A key lands on the ring.", "at": ["k", "r"], "detail": "user:42 hashes to 0x3a."}],
        "sources": [{"title": f"Source {i}", "url": f"https://example.org/{i}", "why": "Covers the ring."} for i in range(3)],
        "check": VALID["root"]["check"],
    },
}
assert check(CONCEPT) == [], check(CONCEPT)
has(check(CONCEPT | {"root": CONCEPT["root"] | {"sources": CONCEPT["root"]["sources"][:2]}}), "3 sources")
has(check(CONCEPT | {"root": CONCEPT["root"] | {"path": "x"}}), "path null")
has(check(CONCEPT | {"root": CONCEPT["root"] | {"lifecycle": []}}), "lifecycle")
# A concept has no tree: a shape with node, even null, would draw dashed as outside a repo.
has(check(CONCEPT | {"root": CONCEPT["root"] | {"flow": CONCEPT["root"]["flow"] | {"nodes": [
    CONCEPT["root"]["flow"]["nodes"][0] | {"node": None}, *CONCEPT["root"]["flow"]["nodes"][1:]]}}}), "omit node")
# A concept has no code to grep, so each principle names the source that backs it.
has(check(CONCEPT | {"root": CONCEPT["root"] | {"principles": [CONCEPT["root"]["principles"][0] | {"source": 0}]}}), "source")
assert check(CONCEPT | {"root": CONCEPT["root"] | {"principles": [{k: v for k, v in CONCEPT["root"]["principles"][0].items() if k != "source"}]}}) != []
# A step says in one sentence what moves and what it means; the detail carries the rest.
has(check(CONCEPT | {"root": CONCEPT["root"] | {"lifecycle": [CONCEPT["root"]["lifecycle"][0] | {"text": "A key lands. It moves."}]}}), "one sentence")
# A count in the overview must match the map, or the reader learns a wrong number.
has(check(CONCEPT | {"root": CONCEPT["root"] | {"overview": "Keys and servers share one ring. A key reaches its server in 2 steps."}}), "2 steps")
assert check(CONCEPT | {"root": CONCEPT["root"] | {"overview": "Keys and servers share one ring. A key reaches its server in 1 step."}}) == []
has(with_service(lambda n: n["root"].update(overview="Fish sets up both Macs. It runs 3 services.")), "3 services")
assert with_service(lambda n: n["root"].update(overview="Fish sets up both Macs. It runs one service.")) == []
assert "## root.check[0]" in prose(CONCEPT) and "Covers the ring." in prose(CONCEPT)
print("ok")
