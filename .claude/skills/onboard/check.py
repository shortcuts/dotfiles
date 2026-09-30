#!/usr/bin/env python3
"""Validate an onboard note: python3 check.py <note.json> [--install | --prose].

Prints `ok` or every failure. --install writes the note into the viewer's notes/,
rebuilds notes/manifest.js, and bundles notes/<slug>.html, so a note reaches the viewer
only after it passes. --prose
prints every prose field as Markdown for the review passes.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ONBOARD = Path(__file__).resolve().parents[2] / ".onboard"
KINDS = {"repo", "dir", "package", "file", "group", "function", "feature"}
PATHLESS = {"group", "function", "feature"}
SCOPES = {"repo", "path", "function", "feature"}
FLOW_WORDS = {"call", "async", "http", "grpc", "reads DB", "writes DB", "queue", "file"}
MAX_SUMMARY = 140
# The panel measure is 76ch: two lines of role, three of problem.
MAX_ROLE = 160
MAX_PROBLEM = 240
MAX_SHAPES = 12
# The principles explain behavior; a column, a variable, or a code span is implementation.
IDENTIFIER = re.compile(r"`|\b\w+_\w+\b|\b[a-z]\w*\.[a-z_]\w+\b")
MAX_CHILDREN = 12


def tracked(repo, sha):
    out = subprocess.run(["git", "-C", repo, "ls-tree", "-r", "--name-only", sha],
                         capture_output=True, text=True)
    if out.returncode:
        return None, None
    files = set(out.stdout.splitlines())
    dirs = {""} | {str(p) for f in files for p in Path(f).parents if str(p) != "."}
    return files, dirs


def check_flow(where, flow):
    if not (isinstance(flow, dict) and flow.get("nodes") and flow.get("edges")):
        return [f"{where}: flow needs nodes and edges"]
    errors = []
    ids = {n.get("id") for n in flow["nodes"]}
    if len(flow["nodes"]) > MAX_SHAPES:
        errors.append(f"{where}: flow has {len(flow['nodes'])} shapes, at most {MAX_SHAPES}")
    for n in flow["nodes"]:
        if not (n.get("id") and n.get("name")):
            errors.append(f"{where}: flow shape without id or name: {n}")
    for e in flow["edges"]:
        for end in ("from", "to"):
            if e.get(end) not in ids:
                errors.append(f"{where}: flow edge {end} unknown shape {e.get(end)!r}")
        if e.get("label", "").split(":")[0].strip() not in FLOW_WORDS:
            errors.append(f"{where}: flow label {e.get('label')!r} is not one of "
                          f"{sorted(FLOW_WORDS)}")
    return errors


def check_root(note, root):
    errors = []
    if not root.get("problem"):
        errors.append("root: no problem")
    elif len(root["problem"]) > MAX_PROBLEM:
        errors.append(f"root: problem over {MAX_PROBLEM} characters")
    if not root.get("flow"):
        errors.append("root: no flow")
    principles = root.get("principles") or []
    if not 1 <= len(principles) <= 3:
        errors.append("root: needs 1 to 3 principles")
    for i, p in enumerate(principles, 1):
        m = p.get("mammoth") or {}
        if not (p.get("claim") and p.get("cost") and m.get("breaks")
                and len(m.get("rows", [])) >= 2
                and all(len(r) == 2 for r in m["rows"])):
            errors.append(f"root: principle {i} needs claim, cost, mammoth rows and breaks")
            continue
        if not 2 <= len(m["rows"]) <= 3:
            errors.append(f"root: principle {i}: mammoth needs 2 or 3 rows")
        if m["breaks"].lower().startswith("breaks down at"):
            errors.append(f"root: principle {i}: breaks repeats the prefix the viewer prints")
        text = [p["claim"], p["cost"], m["breaks"], *(c for r in m["rows"] for c in r)]
        if found := [x for t in text for x in IDENTIFIER.findall(t)]:
            errors.append(f"root: principle {i}: code identifier {found[0]!r}; name the behavior")
    kind = note["scope"]["kind"]
    if kind in ("repo", "path") and not root.get("stack"):
        errors.append("root: repo and path scopes need a stack")
    if kind == "feature" and not root.get("lifecycle"):
        errors.append("root: feature scope needs a lifecycle")
    # Each step lights its shapes in the root flow, so the reader steps through the graph.
    flow = root.get("flow")
    shapes = {n.get("id") for n in flow.get("nodes", [])} if isinstance(flow, dict) else set()
    for i, step in enumerate(root.get("lifecycle") or [], 1):
        if not (isinstance(step, dict) and step.get("text") and step.get("at")):
            errors.append(f"root: lifecycle step {i} needs text and at")
        elif bad := [a for a in step["at"] if a not in shapes]:
            errors.append(f"root: lifecycle step {i}: unknown shape {bad[0]!r} in the root flow")
    if kind == "function":
        io = root.get("io") or {}
        if not (io.get("inputs") and io.get("outputs") and io.get("goes")):
            errors.append("root: function scope needs io inputs, outputs and goes")
    return errors


def hints_removed(value):
    """skeleton.py's `_` keys are graph hints for the writer, never viewer data."""
    if isinstance(value, dict):
        return {k: hints_removed(v) for k, v in value.items() if not k.startswith("_")}
    if isinstance(value, list):
        return [hints_removed(v) for v in value]
    return value


def unfilled(value, where="note"):
    if value == "TODO":
        return [f"unfilled: {where}"]
    if isinstance(value, dict):
        return [e for k, v in value.items() for e in unfilled(v, f"{where}.{k}")]
    if isinstance(value, list):
        return [e for i, v in enumerate(value) for e in unfilled(v, f"{where}[{i}]")]
    return []


def check(note):
    note = hints_removed(note)
    errors = unfilled(note)
    missing = [f"missing key: {k}" for k in
               ("schema", "slug", "title", "generated", "repo", "scope", "words", "root")
               if k not in note]
    if missing:
        return errors + missing
    if not re.fullmatch(r"[a-z0-9]+(-[a-z0-9]+)*(--[a-z0-9]+(-[a-z0-9]+)*)?", note["slug"]):
        errors.append(f"slug {note['slug']!r}: use <repo> or <repo>--<scope>, [a-z0-9-]")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", note["generated"]):
        errors.append("generated: not YYYY-MM-DD")
    if note["scope"].get("kind") not in SCOPES:
        errors.append(f"scope.kind: not one of {sorted(SCOPES)}")
        return errors
    for w in note["words"]:
        if not (w.get("term") and w.get("def")):
            errors.append(f"words: entry without term or def: {w}")

    repo = note["repo"]
    files, dirs = tracked(repo.get("path", ""), repo.get("sha", ""))
    if files is None:
        return errors + [f"repo: git cannot list {repo.get('sha')} in {repo.get('path')}"]

    seen, lineage = set(), {}

    def walk(node, depth, above=()):
        where = node.get("id", "?")
        for key in ("id", "name", "kind", "summary", "role"):
            if not node.get(key) and not (key == "id" and depth == 0):
                errors.append(f"{where}: no {key}")
        if where in seen:
            errors.append(f"{where}: duplicate id")
        seen.add(where)
        lineage[where] = above
        kind = node.get("kind")
        if kind not in KINDS:
            errors.append(f"{where}: kind {kind!r} not one of {sorted(KINDS)}")
        if len(node.get("summary", "")) > MAX_SUMMARY:
            errors.append(f"{where}: summary over {MAX_SUMMARY} characters")
        role = node.get("role") or []
        if len(role) > 1:
            errors.append(f"{where}: role is one paragraph")
        elif role and len(role[0]) > MAX_ROLE:
            errors.append(f"{where}: role over {MAX_ROLE} characters")
        path = node.get("path")
        if kind in PATHLESS:
            if path is not None:
                errors.append(f"{where}: a {kind} node has path null")
        elif path is None or (path not in files if kind == "file" else path not in dirs):
            errors.append(f"{where}: path {path!r} not tracked at {repo['sha'][:7]}"
                          + (" as a directory" if kind != "file" and path in files else ""))
        children = node.get("children") or []
        if kind in ("package", "file") and children:
            errors.append(f"{where}: {kind} has children; the {kind} is a leaf")
        if len(children) > MAX_CHILDREN:
            errors.append(f"{where}: {len(children)} children; group them, at most "
                          f"{MAX_CHILDREN}")
        if node.get("flow"):
            errors.extend(check_flow(where, node["flow"]))
        for e in node.get("entry", []):
            if e.get("path") not in files:
                errors.append(f"{where}: entry {e.get('name')}: {e.get('path')!r} is "
                              "not a tracked file")
            lines = e.get("lines") or []
            if not (len(lines) == 2 and all(isinstance(n, int) for n in lines)
                    and 0 < lines[0] <= lines[1]):
                errors.append(f"{where}: entry {e.get('name')}: lines not [start, end]")
        for s in node.get("external", []):
            if not (s.get("name") and s.get("how")
                    and str(s.get("url", "")).startswith("https://")):
                errors.append(f"{where}: external {s.get('name')}: needs name, how, https url")
        for child in children:
            walk(child, depth + 1, above + (where,))

    walk(note["root"], 0)

    def links(node):
        for link in node.get("links", []):
            yield node["id"], link
        for child in node.get("children") or []:
            yield from links(child)

    for src, link in links(note["root"]):
        dst, label = link.get("to"), link.get("label", "")
        if dst not in lineage:
            errors.append(f"{src}: link to unknown node {dst!r}")
        elif dst == src:
            errors.append(f"{src}: link to itself")
        elif dst in lineage[src] or src in lineage[dst]:
            # The tree already draws that relation; a link would draw it twice.
            errors.append(f"{src}: link to its ancestor or descendant {dst!r}")
        if label.split(":")[0].strip() not in FLOW_WORDS:
            errors.append(f"{src}: link label {label!r} does not start with one of "
                          f"{sorted(FLOW_WORDS)}")
    return errors + check_root(note, note["root"])


def prose(note):
    """Every prose field as Markdown, for the review passes; the ids say where edits go."""
    out, root = [], note["root"]
    for key in ("problem",):
        if root.get(key):
            out += [f"## root.{key}", root[key], ""]
    for i, p in enumerate(root.get("principles", [])):
        out += [f"## root.principles[{i}]", p["claim"], p["cost"],
                f"Breaks down at: {p['mammoth']['breaks']}", ""]
    for i, step in enumerate(root.get("lifecycle", [])):
        out += [f"## root.lifecycle[{i}]", step["text"], ""]

    def walk(n):
        out.extend([f"## {n['id'] or '/'} ({n['name']})", n["summary"], *n["role"],
                    *(f"- {e['name']}: {e['note']}" for e in n.get("entry", [])),
                    *(f"- {s['name']}: {s.get('how', 'TODO')}" for s in n.get("external", [])), ""])
        for c in n.get("children") or []:
            walk(c)

    walk(root)
    out += ["## words", *(f"- {w['term']}: {w['def']}" for w in note["words"])]
    return "\n".join(out)


def install(note):
    notes = ONBOARD / "notes"
    notes.mkdir(parents=True, exist_ok=True)
    # </ inside a <script> ends it early when bundle.py inlines the note.
    body = json.dumps(hints_removed(note), ensure_ascii=False).replace("</", "<\\/")
    (notes / f"{note['slug']}.js").write_text(f"ONBOARD.register({body});\n")
    entries = []
    for f in sorted(notes.glob("*.js")):
        if f.name == "manifest.js":
            continue
        n = json.loads(f.read_text().removeprefix("ONBOARD.register(").rstrip().rstrip(";")
                       .removesuffix(")"))
        entries.append({k: n[k] for k in ("slug", "title", "generated")}
                       | {"repo": n["repo"]["name"], "scope": n["scope"]["kind"]})
    (notes / "manifest.js").write_text(f"ONBOARD.manifest({json.dumps(entries, indent=1)});\n")
    # The viewer owns the page, so it owns the one-file copy too. A failed bundle, such as
    # an offline first run, leaves the note installed.
    done = subprocess.run([sys.executable, ONBOARD / "bundle.py", note["slug"]],
                          capture_output=True, text=True)
    if done.returncode:
        print(f"warning: no one-file copy: {done.stderr.strip().splitlines()[-1]}")
    return notes / f"{note['slug']}.js"


if __name__ == "__main__":
    note = json.loads(Path(sys.argv[1]).read_text())
    if "--prose" in sys.argv:
        sys.exit(print(prose(note)))
    errors = check(note)
    print("\n".join(errors) or "ok")
    if errors:
        sys.exit(1)
    if "--install" in sys.argv:
        print(f"installed {install(note)}")
