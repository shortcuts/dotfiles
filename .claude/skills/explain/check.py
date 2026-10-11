#!/usr/bin/env python3
"""Validate an explain note: python3 check.py <note.json> [--install | --prose].

Prints `ok` or every failure. --install writes the note into the Obsidian vault
(obsidian.py), so a note reaches the vault only after it passes. --prose
prints every prose field as Markdown for the review passes.
"""
import json
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

KINDS = {"repo", "dir", "service", "package", "file", "group", "function", "feature", "concept"}
PATHLESS = {"group", "function", "feature", "concept"}
SCOPES = {"repo", "path", "function", "feature", "concept"}
FLOW_WORDS = {"call", "async", "http", "grpc", "reads DB", "writes DB", "queue", "file"}
MAX_SUMMARY = 140
# Short enough to read on a phone: two lines of role, three of problem.
MAX_ROLE = 160
MAX_PROBLEM = 240
# The overview sits above the map: two to five sentences that give the whole idea.
MAX_OVERVIEW = 600
# A step's detail sits under the map, and a shape's about is its key line.
MAX_DETAIL = 480
MAX_ABOUT = 300
# A group name heads a frame on the graph, so it stays one short line.
MAX_GROUP = 32
SENTENCE = re.compile(r"[.!?](\s|$)")
MAX_SHAPES = 14
MAX_STEPS = 7
# The principles explain behavior; a column, a variable, or a code span is implementation.
IDENTIFIER = re.compile(r"`|\b\w+_\w+\b|\b[a-z]\w*\.[a-z_]\w+\b")
MAX_CHILDREN = 12
# A question the reader answers in their head: a long one tests reading, not understanding.
MAX_QUESTION_WORDS = 15
# The note inlines a sketch, so it may draw shapes and text, and nothing that runs or loads.
SKETCH_TAGS = {"svg", "g", "path", "rect", "circle", "ellipse", "line", "polyline", "polygon",
               "text", "tspan", "title", "defs", "marker"}
NUMBERS = {w: i for i, w in enumerate("one two three four five six seven eight nine ten eleven twelve".split(), 1)}
# "3 services", "six steps": a count the reader takes as a fact about the map.
COUNT = re.compile(r"\b(\d+|" + "|".join(NUMBERS) + r")\s+(service|store|step)s?\b", re.I)
SLUG = r"[a-z0-9]+(-[a-z0-9]+)*(--[a-z0-9]+(-[a-z0-9]+)*)?"


def tracked(repo, sha):
    out = subprocess.run(["git", "-C", repo, "ls-tree", "-r", "--name-only", sha],
                         capture_output=True, text=True)
    if out.returncode:
        return None, None
    files = set(out.stdout.splitlines())
    dirs = {""} | {str(p) for f in files for p in Path(f).parents if str(p) != "."}
    return files, dirs


def spelled(repo, sha, term):
    # "render job" also matches render_job, renderJob, and render-job.
    words = re.findall(r"[A-Za-z0-9]+", term)
    pattern = "[^[:alnum:]]?".join(words)
    return subprocess.run(["git", "-C", repo, "grep", "-q", "-I", "-i", "-E", "-e", pattern, sha],
                          capture_output=True).returncode == 0


def check_flow(where, flow, limit=MAX_SHAPES, ends=False):
    if not (isinstance(flow, dict) and flow.get("nodes") and flow.get("edges")):
        return [f"{where}: flow needs nodes and edges"]
    errors = []
    ids = {n.get("id") for n in flow["nodes"]}
    if limit is not None and len(flow["nodes"]) > limit:
        errors.append(f"{where}: flow has {len(flow['nodes'])} shapes, at most {limit}")
    for n in flow["nodes"]:
        if not (n.get("id") and n.get("name")):
            errors.append(f"{where}: flow shape without id or name: {n}")
        if (ext := n.get("external")) is not None:
            # https:// is the other repo's docs; #note=<slug> is its own explain note.
            url = ext.get("url", "") if isinstance(ext, dict) else ""
            if not (isinstance(ext, dict) and ext.get("repo") and isinstance(url, str)
                    and (url.startswith("https://") or re.fullmatch("#note=" + SLUG, url))):
                errors.append(f"{where}: flow shape {n.get('id')!r}: external needs repo and an "
                              "https:// or #note=<slug> url")
            if n.get("node") is not None:
                errors.append(f"{where}: flow shape {n.get('id')!r}: external and node both "
                              "set; a shape is in the tree or outside it")
        if len(n.get("about") or "") > MAX_ABOUT:
            errors.append(f"{where}: flow shape {n.get('id')!r}: about over {MAX_ABOUT} characters")
        if not isinstance(n.get("decision", False), bool):
            errors.append(f"{where}: flow shape {n.get('id')!r}: decision is true or false")
        if "group" in n and not (isinstance(n["group"], str) and 0 < len(n["group"]) <= MAX_GROUP):
            errors.append(f"{where}: flow shape {n.get('id')!r}: group is a name of 1 to "
                          f"{MAX_GROUP} characters")
    for e in flow["edges"]:
        for flag in ("both", "back"):
            if not isinstance(e.get(flag, False), bool):
                errors.append(f"{where}: flow edge {e.get('from')!r} to {e.get('to')!r}: {flag} is true or false")
        for end in ("from", "to"):
            if e.get(end) not in ids:
                errors.append(f"{where}: flow edge {end} unknown shape {e.get(end)!r}")
        if e.get("label", "").split(":")[0].strip() not in FLOW_WORDS:
            errors.append(f"{where}: flow label {e.get('label')!r} is not one of "
                          f"{sorted(FLOW_WORDS)}")
    # The root flow reads in to out. A system that is both the source and the destination
    # (Algolia) takes two shapes, or the layout puts it mid-graph.
    for n in flow["nodes"]:
        if n.get("end") not in (None, "in", "out"):
            errors.append(f"{where}: flow shape {n.get('id')!r}: end is 'in' or 'out'")
    if ends:
        for end, word in (("in", "source"), ("out", "destination")):
            marked = {n["id"] for n in flow["nodes"] if n.get("end") == end and n.get("id")}
            if not marked:
                errors.append(f"{where}: flow has no {word}: mark one shape end {end!r}")
            # A two-way edge leaves and enters both shapes, so it makes neither a source nor a sink.
            for e in (e for e in flow["edges"] if not e.get("both")):
                if e.get("to" if end == "in" else "from") in marked:
                    errors.append(f"{where}: flow {word} {e.get('to' if end == 'in' else 'from')!r}"
                                  f" has no {'incoming' if end == 'in' else 'outgoing'} edge:"
                                  " split it into two shapes")
    return errors


def check_lifecycle(where, steps, flow, detail=False):
    # Each step lights its shapes in the node's flow, so the reader steps through the graph.
    errors = []
    shapes = {n.get("id") for n in flow.get("nodes", [])} if isinstance(flow, dict) else set()
    if len(steps) > MAX_STEPS:
        errors.append(f"{where}: lifecycle has at most {MAX_STEPS} steps")
    for i, step in enumerate(steps, 1):
        if not (isinstance(step, dict) and step.get("text") and step.get("at")):
            errors.append(f"{where}: lifecycle step {i} needs text and at")
            continue
        if len(SENTENCE.findall(step["text"].strip())) > 1:
            errors.append(f"{where}: lifecycle step {i}: text is one sentence, what moves and what it "
                          "means; the detail carries the rest")
        if bad := [a for a in step["at"] if a not in shapes]:
            errors.append(f"{where}: lifecycle step {i}: unknown shape {bad[0]!r} in the "
                          f"{where} flow")
        # The root's steps sit under the map, so each one explains its stage.
        if detail:
            if not step.get("detail"):
                errors.append(f"{where}: lifecycle step {i} needs a detail")
            elif len(step["detail"]) > MAX_DETAIL:
                errors.append(f"{where}: lifecycle step {i}: detail over {MAX_DETAIL} characters")
        elif len(step.get("detail") or "") > MAX_DETAIL:
            errors.append(f"{where}: lifecycle step {i}: detail over {MAX_DETAIL} characters")
    return errors


def check_rampup(root, concept):
    """The end of the note: the questions that check the idea, then where to read next."""
    errors = []
    sources = root.get("sources") or []
    least = 3 if concept else 1
    if len(sources) < least:
        errors.append(f"root: needs at least {least} sources" + (", 3 sources for a concept" if concept else ""))
    for i, s in enumerate(sources, 1):
        if not (isinstance(s, dict) and s.get("title") and s.get("why")
                and str(s.get("url", "")).startswith("https://")):
            errors.append(f"root: sources {i} needs title, https url, and why")
    questions = root.get("check") or []
    if len(questions) != 3:
        errors.append("root: check needs 3 questions")
    for i, c in enumerate(questions, 1):
        if not (isinstance(c, dict) and c.get("q") and c.get("a")):
            errors.append(f"root: check {i} needs q and a")
        elif len(c["q"].split()) > MAX_QUESTION_WORDS:
            errors.append(f"root: check {i}: question over {MAX_QUESTION_WORDS} words")
    for i, f in enumerate(root.get("further") or [], 1):
        if not (isinstance(f, dict) and f.get("q") and f.get("at")
                and isinstance(f.get("source"), int) and 1 <= f["source"] <= len(sources)):
            errors.append(f"root: further {i} needs q, at, and source, the number of a sources entry")
    for i, plate in enumerate(root.get("plates") or [], 1):
        errors += [f"root: plate {i}: {e}" for e in check_sketch(plate)]
    return errors


def check_sketch(plate):
    if not (isinstance(plate, dict) and plate.get("title") and plate.get("svg")):
        return ["needs title and svg"]
    errors = [] if plate.get("key") else ["needs a key: one line per numbered part"]
    if not plate.get("caption"):
        errors.append("needs a caption: what moves, and the true numbers")
    try:
        svg = ET.fromstring(plate["svg"])
    except ET.ParseError as e:
        return errors + [f"invalid XML ({e})"]
    if "viewBox" not in svg.attrib:
        errors.append("no viewBox")
    if svg.attrib.get("width", "100%") != "100%":
        errors.append("fixed width; the note sizes the sketch")
    for el in svg.iter():
        tag = el.tag.split("}")[-1]
        if tag not in SKETCH_TAGS:
            errors.append(f"<{tag}> is not allowed; draw with {sorted(SKETCH_TAGS)}")
        for attr, value in el.attrib.items():
            name = attr.split("}")[-1]
            if name.startswith("on") or name == "href":
                errors.append(f"<{tag} {name}> is not allowed; a sketch runs and loads nothing")
            if re.search(r"url\(\s*['\"]?(?!#)", value):
                errors.append(f"<{tag} {name}>: url( loads from outside; only url(#id) is allowed")
    # Count what you draw: each circled number gets exactly one key line.
    numbers = {int(t) for el in svg.iter() if el.tag.split("}")[-1] == "text"
               and (t := "".join(el.itertext()).strip()).isdigit()}
    if numbers and (numbers != set(range(1, max(numbers) + 1)) or len(plate.get("key") or []) != max(numbers)):
        errors.append(f"callouts {sorted(numbers)} need callouts 1 to n and one key line each, "
                      f"found {len(plate.get('key') or [])}")
    return errors


def services(node):
    return (node.get("kind") == "service") + sum(services(c) for c in node.get("children") or [])


def check_counts(root):
    flow = root.get("flow") if isinstance(root.get("flow"), dict) else {}
    have = {"service": services(root) - (root.get("kind") == "service"),
            "store": sum(bool(n.get("store")) for n in flow.get("nodes", [])),
            "step": len(root.get("lifecycle") or [])}
    errors = []
    for key in ("overview", "summary"):
        for m in COUNT.finditer(root.get(key) or ""):
            said = NUMBERS.get(m.group(1).lower()) or int(m.group(1))
            what = m.group(2).lower()
            if said != have[what]:
                errors.append(f"root: {key} says {m.group(0)!r}; the map has {have[what]} {what}s")
    return errors


def check_root(note, root):
    kind = note["scope"]["kind"]
    errors = check_rampup(root, kind == "concept") + check_counts(root)
    if not root.get("problem"):
        errors.append("root: no problem")
    elif len(root["problem"]) > MAX_PROBLEM:
        errors.append(f"root: problem over {MAX_PROBLEM} characters")
    overview = root.get("overview") or ""
    if not overview:
        errors.append("root: no overview")
    elif len(overview) > MAX_OVERVIEW or not 2 <= len(SENTENCE.findall(overview)) <= 5:
        errors.append(f"root: overview is 2 to 5 sentences, at most {MAX_OVERVIEW} characters")
    if not root.get("flow"):
        errors.append("root: no flow")
    # A root shape with no tree node has no page of its own, so its key line carries its text.
    for n in (root.get("flow") or {}).get("nodes", []) if isinstance(root.get("flow"), dict) else []:
        if n.get("node") is None and not n.get("about"):
            errors.append(f"root: flow shape {n.get('id')!r} needs an about for its key line")
        elif len(n.get("about") or "") > MAX_ABOUT:
            errors.append(f"root: flow shape {n.get('id')!r}: about over {MAX_ABOUT} characters")
    principles = root.get("principles") or []
    sources = root.get("sources") or []
    for i, p in enumerate(principles, 1):
        src = p.get("source")
        if src is None and kind == "concept":
            errors.append(f"root: principle {i} needs source, the number of the sources entry that backs it")
        elif src is not None and not (isinstance(src, int) and 1 <= src <= len(sources)):
            errors.append(f"root: principle {i}: source {src!r} is not the number of a sources entry")
    if not 1 <= len(principles) <= 3:
        errors.append("root: needs 1 to 3 principles")
    for i, p in enumerate(principles, 1):
        rows = p.get("example") or []
        if not (p.get("claim") and p.get("why") and p.get("cost") and len(rows) >= 2
                and all(isinstance(r, list) and len(r) == 2 for r in rows)):
            errors.append(f"root: principle {i} needs claim, why, cost, and example rows")
            continue
        if not 2 <= len(rows) <= 3:
            errors.append(f"root: principle {i}: example needs 2 or 3 rows")
        if p.get("except", "").lower().startswith("except"):
            errors.append(f"root: principle {i}: except repeats the prefix the note prints")
        text = [p["claim"], p["why"], p["cost"], p.get("except", ""), *(c for r in rows for c in r)]
        if found := [x for t in text for x in IDENTIFIER.findall(t)]:
            errors.append(f"root: principle {i}: code identifier {found[0]!r}; name the behavior")
    if kind in ("repo", "path") and not root.get("stack"):
        errors.append("root: repo and path scopes need a stack")
    if kind in ("feature", "concept") and not root.get("lifecycle"):
        errors.append(f"root: {kind} scope needs a lifecycle")
    errors += check_lifecycle("root", root.get("lifecycle") or [], root.get("flow"), detail=True)
    if kind == "function":
        io = root.get("io") or {}
        if not (io.get("inputs") and io.get("outputs") and io.get("goes")):
            errors.append("root: function scope needs io inputs, outputs and goes")
    return errors


def hints_removed(value):
    """skeleton.py's `_` keys are graph hints for the writer, never note data."""
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
    if note["schema"] != 2:
        errors.append(f"schema: {note['schema']!r}; check.py reads schema 2 only, regenerate the note")
    if not re.fullmatch(SLUG, note["slug"]):
        errors.append(f"slug {note['slug']!r}: use <repo> or <repo>--<scope>, [a-z0-9-]")
    if not re.fullmatch(r"\d{4}-\d{2}-\d{2}", note["generated"]):
        errors.append("generated: not YYYY-MM-DD")
    if note["scope"].get("kind") not in SCOPES:
        errors.append(f"scope.kind: not one of {sorted(SCOPES)}")
        return errors
    for w in note["words"]:
        if not (w.get("term") and w.get("def")):
            errors.append(f"words: entry without term or def: {w}")

    # A concept has no repo: nothing to pin, and the sources stand in for the code.
    repo = note["repo"]
    if note["scope"]["kind"] == "concept":
        if repo is not None:
            errors.append("repo: a concept has repo null")
        repo, files, dirs = None, set(), {""}
    else:
        files, dirs = tracked(repo.get("path", ""), repo.get("sha", ""))
        if files is None:
            return errors + [f"repo: git cannot list {repo.get('sha')} in {repo.get('path')}"]

    text = json.dumps(note["root"]).lower()
    for w in note["words"]:
        if w.get("term") and w["term"].lower() not in text:
            errors.append(f"words: {w['term']!r} is defined but the note never uses it; "
                          "a synonym took its place")
        if repo and w.get("term") and not w.get("from") and not spelled(repo["path"], repo["sha"], w["term"]):
            errors.append(f"words: {w['term']!r} appears nowhere in the repo; use the subject's "
                          "own term, or name the doc it comes from in `from`")

    seen, lineage, kinds, flows = set(), {}, {}, []

    def walk(node, depth, above=(), service=None):
        where = node.get("id", "?")
        for key in ("id", "name", "kind", "summary", "role"):
            if not node.get(key) and not (key == "id" and depth == 0):
                errors.append(f"{where}: no {key}")
        if where in seen:
            errors.append(f"{where}: duplicate id")
        seen.add(where)
        lineage[where] = above
        kind = kinds[where] = node.get("kind")
        if service and kind not in ("package", "group"):
            errors.append(f"{where}: a {kind} under service {service}; a service holds "
                          f"packages, grouped past {MAX_CHILDREN}")
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
            errors.append(f"{where}: path {path!r} not tracked at {repo['sha'][:7] if repo else 'no repo'}"
                          + (" as a directory" if kind != "file" and path in files else ""))
        children = node.get("children") or []
        if kind in ("package", "file") and children:
            errors.append(f"{where}: {kind} has children; the {kind} is a leaf")
        if len(children) > MAX_CHILDREN:
            errors.append(f"{where}: {len(children)} children; group them, at most "
                          f"{MAX_CHILDREN}")
        if node.get("flow"):
            flows.append((where, depth, node["flow"]))
            for n in node["flow"].get("nodes", []) if isinstance(node["flow"], dict) else []:
                if n.get("doc") and n["doc"].split("#")[0] not in files:
                    errors.append(f"{where}: flow shape {n.get('id')!r}: doc {n['doc']!r} is not a tracked file")
            errors.extend(check_flow(where, node["flow"], MAX_SHAPES if depth else None,
                                     ends=not depth or kind == "service"))
        elif kind == "service":
            errors.append(f"{where}: a service needs a flow")
        if depth and node.get("lifecycle"):
            # A part's flow steps through its own graph, so any node with a flow takes steps.
            if kind == "service" or node.get("flow"):
                errors.extend(check_lifecycle(where, node["lifecycle"], node.get("flow")))
            else:
                errors.append(f"{where}: lifecycle sits on the root, a service, or a node with a flow")
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
            walk(child, depth + 1, above + (where,), where if kind == "service" else service)

    walk(note["root"], 0)

    if repo is None:
        for n in (note["root"].get("flow") or {}).get("nodes", []) if isinstance(note["root"].get("flow"), dict) else []:
            if "node" in n:
                errors.append(f"root: flow shape {n.get('id')!r}: a concept has no tree; omit node")

    # A shape's node points into the tree; null is an outside system.
    on_root = {}
    for where, depth, flow in flows:
        for n in flow.get("nodes", []) if isinstance(flow, dict) else []:
            target = n.get("node")
            if target is None:
                continue
            if target not in kinds or target == note["root"].get("id"):
                errors.append(f"{where}: flow shape {n.get('id')!r}: node {target!r} is not a "
                              "node of the tree")
            elif not depth:
                on_root[target] = on_root.get(target, 0) + 1
                if kinds[target] == "package":
                    errors.append(f"root: flow shape {n.get('id')!r} points at package "
                                  f"{target!r}; the root draws services, stores, and outside "
                                  "systems")
    for node_id, kind in kinds.items():
        if kind == "service" and node_id != note["root"].get("id") and on_root.get(node_id, 0) != 1:
            errors.append(f"{node_id}: a service takes one root flow shape, found "
                          f"{on_root.get(node_id, 0)}")

    # A queue or table drawn in a flow must be one the repo names, or one another repo owns.
    for where, _, flow in flows:
        if not isinstance(flow, dict):
            continue
        shapes = {n.get("id"): n for n in flow.get("nodes", [])}
        stores = {e.get(end) for e in flow.get("edges", [])
                  if e.get("label", "").split(":")[0].strip() in ("queue", "reads DB", "writes DB")
                  for end in ("from", "to")
                  if shapes.get(e.get(end), {}).get("store")}
        for n in (shapes[s] for s in stores):
            name = n.get("name", "").split(":", 1)[-1].strip()
            if repo and not n.get("from") and not spelled(repo["path"], repo["sha"], name):
                errors.append(f"{where}: flow shape {n['id']!r}: {name!r} appears nowhere in the "
                              "repo; use its real name, or name the other repo in `from`")

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
    for key in ("overview", "problem"):
        if root.get(key):
            out += [f"## root.{key}", root[key], ""]
    for i, p in enumerate(root.get("principles", [])):
        out += [f"## root.principles[{i}]", p["claim"], p["why"],
                *(f"- {case}: {does}" for case, does in p["example"]),
                *([f"Except: {p['except']}"] if p.get("except") else []), p["cost"], ""]
    for i, step in enumerate(root.get("lifecycle", [])):
        out += [f"## root.lifecycle[{i}]", step["text"], *([step["detail"]] if step.get("detail") else []), ""]
    for shape in (root.get("flow") or {}).get("nodes", []) if isinstance(root.get("flow"), dict) else []:
        if shape.get("about"):
            out += [f"## root.flow.{shape['id']} ({shape['name']})", shape["about"], ""]

    def walk(n):
        out.extend([f"## {n['id'] or '/'} ({n['name']})", n["summary"], *n["role"],
                    *(f"- {e['name']}: {e['note']}" for e in n.get("entry", [])),
                    *(f"- {s['name']}: {s.get('how', 'TODO')}" for s in n.get("external", [])),
                    *(f"- step {i}: {s['text']}" + (f" {s['detail']}" if s.get("detail") else "")
                      for i, s in enumerate(n.get("lifecycle") or [], 1) if n["id"]),
                    *(f"- shape {s['name']}: {s['about']}" for s in (n.get("flow") or {}).get("nodes", [])
                      if n["id"] and s.get("about")), ""])
        for c in n.get("children") or []:
            walk(c)

    walk(root)
    for key in ("check", "further"):
        for i, c in enumerate(root.get(key) or []):
            out += [f"## root.{key}[{i}]", c["q"], *([c["a"]] if c.get("a") else []), ""]
    for i, p in enumerate(root.get("plates") or []):
        out += [f"## root.plates[{i}] ({p['title']})", *(f"{n}. {k}" for n, k in enumerate(p.get("key", []), 1)), ""]
    for i, s in enumerate(root.get("sources") or []):
        out += [f"## root.sources[{i}] ({s['title']})", s["why"], ""]
    out += ["## words", *(f"- {w['term']}: {w['def']}" for w in note["words"])]
    return "\n".join(out)


if __name__ == "__main__":
    note = json.loads(Path(sys.argv[1]).read_text())
    if "--prose" in sys.argv:
        sys.exit(print(prose(note)))
    errors = check(note)
    print("\n".join(errors) or "ok")
    if errors:
        sys.exit(1)
    if "--install" in sys.argv:
        import obsidian
        page = obsidian.install(hints_removed(note))
        print(f"installed {page}\nopen '{obsidian.open_url(page)}'")
