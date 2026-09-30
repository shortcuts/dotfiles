#!/usr/bin/env python3
"""Write the deterministic half of an onboard note; the model fills every TODO.

    python3 skeleton.py repo                         --out DIR
    python3 skeleton.py path <dir>                   --out DIR
    python3 skeleton.py function <name>              --out DIR
    python3 skeleton.py feature "<words>" --packages <dir> [<dir> ...] --out DIR

Run it from inside the repository. It reindexes the graph, pins the commit, builds the
tree, and adds graph facts as `_` keys. `check.py --install` strips those keys.
"""
import argparse
import datetime
import json
import os
import re
import subprocess
import sys
from collections import Counter, defaultdict
from pathlib import PurePosixPath

TODO = "TODO"
MAX_CHILDREN = 12
PACKAGE_MARKERS = {"go.mod", "package.json", "Cargo.toml", "pyproject.toml", "setup.py",
                   "build.zig", "mix.exs", "Gemfile", "pom.xml", "build.gradle"}
EDGE_TYPES = "CALLS|HTTP_CALLS|GRPC_CALLS|ASYNC_CALLS|DATA_FLOWS|WRITES|IMPORTS"
# Character classes instead of backslashes: the pattern crosses JSON and Cypher quoting.
TEST_CYPHER = ".*(_test[.]|[.]test[.]|[.]spec[.]|/testdata/|/tests?/|^tests?/).*"
TEST_PATH = re.compile(r"(_test\.|\.test\.|\.spec\.|(^|/)tests?/|(^|/)testdata/)")
# Import strings that name a service outside the repo, and the docs the note links.
SERVICES = [
    (r"aws-sdk|@aws-sdk/|boto3|aws/aws-sdk-go", "AWS", "https://docs.aws.amazon.com/"),
    (r"cloud\.google\.com/go|google-cloud-|@google-cloud/", "Google Cloud",
     "https://cloud.google.com/docs"),
    (r"\bopenai\b", "OpenAI API", "https://platform.openai.com/docs"),
    (r"\banthropic\b", "Claude API", "https://docs.anthropic.com/"),
    (r"jackc/pgx|lib/pq|psycopg|\bpg-promise\b|node-postgres", "PostgreSQL",
     "https://www.postgresql.org/docs/"),
    (r"go-redis|redis-py|ioredis|\bredis\b", "Redis", "https://redis.io/docs/"),
    (r"segmentio/kafka|confluent-kafka|kafkajs|IBM/sarama", "Apache Kafka",
     "https://kafka.apache.org/documentation/"),
    (r"elastic/go-elasticsearch|@elastic/elasticsearch", "Elasticsearch",
     "https://www.elastic.co/docs"),
    (r"mongo-driver|pymongo|\bmongodb\b", "MongoDB", "https://www.mongodb.com/docs/"),
    (r"stripe-go|\bstripe\b", "Stripe", "https://docs.stripe.com/"),
    (r"algoliasearch", "Algolia", "https://www.algolia.com/doc/"),
]


def run(*cmd, cwd=None, check=True):
    out = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True)
    if check and out.returncode:
        sys.exit(f"{' '.join(cmd[:4])}: {out.stderr.strip()[:300]}\n{' '.join(cmd[4:])[:400]}")
    return out.stdout.strip() if out.returncode == 0 else None


def git(root, *args, check=True):
    return run("git", "-C", root, *args, check=check)


def cbm(tool, **args):
    out = run("codebase-memory-mcp", "cli", "--quiet", tool, json.dumps(args))
    return json.loads(out)


def slugify(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def web_url(remote):
    m = re.match(r"(?:git@github\.com:|https://github\.com/)([^/]+/[^/]+?)(?:\.git)?/?$",
                 remote or "")
    return f"https://github.com/{m.group(1)}" if m else None


def pin(root, warnings):
    """HEAD when a remote holds it, else the newest ancestor a remote holds."""
    head = git(root, "rev-parse", "HEAD")
    if git(root, "branch", "-r", "--contains", head, check=False):
        return head
    branch = git(root, "rev-parse", "--abbrev-ref", "HEAD", check=False)
    for ref in ("@{u}", f"origin/{branch}", "origin/HEAD"):
        base = git(root, "merge-base", "HEAD", ref, check=False)
        if base:
            ahead = git(root, "rev-list", "--count", f"{base}..HEAD")
            warnings.append(f"HEAD is on no remote; links pin to {base[:7]} "
                            f"({ref}), {ahead} commits behind HEAD")
            return base
    warnings.append("no remote holds HEAD or an ancestor; GitHub links will 404")
    return head


def placeholder(node_id, name, kind, path):
    return {"id": node_id, "name": name, "kind": kind, "path": path,
            "summary": TODO, "role": [TODO]}


def build_tree(files, scope, max_depth, is_root=True):
    """Directory nodes from tracked files; a package or a leafless directory ends a branch."""
    dirs, direct = defaultdict(set), defaultdict(list)
    for f in files:
        p = PurePosixPath(f)
        direct[str(p.parent) if str(p.parent) != "." else ""].append(p.name)
        for parent in list(p.parents)[:-1]:
            up = str(parent.parent) if str(parent.parent) != "." else ""
            dirs[up].add(str(parent))

    def node(path, depth, is_root):
        name = PurePosixPath(path).name or "/"
        # A chain of single-child directories reads as one path: modules/services.
        while not is_root and len(dirs[path]) == 1 and not direct[path]:
            path = next(iter(dirs[path]))
            name = f"{name}/{PurePosixPath(path).name}"
        subs = sorted(dirs[path])
        marker = not is_root and PACKAGE_MARKERS & set(direct[path])
        if not is_root and (not subs or marker or depth >= max_depth):
            n = placeholder(path, name, "package", path)
            n["_leaf_reason"] = ("package marker" if marker else
                                 "no subdirectory" if not subs else f"depth {max_depth}")
        else:
            n = placeholder(path, name, "dir", path)
            n["children"] = [node(s, depth + 1, False) for s in subs]
            if len(n["children"]) > MAX_CHILDREN:
                n["_group"] = f"{len(n['children'])} children: collect them into groups"
        if direct[path]:
            n["_files"] = sorted(direct[path])[:30]
        return n

    return node(scope, 0, is_root)


def feature_tree(files, packages, max_depth):
    root = placeholder(None, "", "feature", None)
    root["children"] = [build_tree([f for f in files if under(f, p)], p, max_depth,
                                   is_root=False) for p in (x.strip("/") for x in packages)]
    return root


def walk(n):
    yield n
    for c in n.get("children") or []:
        yield from walk(c)


def folder(path):
    parent = str(PurePosixPath(path).parent)
    return "/" if parent == "." else parent


def under(path, prefix):
    return prefix == "" or path == prefix or path.startswith(prefix + "/")


def annotate(root_node, edges, grep_hits, graph_files, mains=()):
    """Entry points, cross-boundary edges and service imports per node, from graph rows."""
    for n in walk(root_node):
        p = n["path"]
        if p is None:
            continue
        fan_in, out_edges, in_edges = Counter(), Counter(), Counter()
        spans = {}
        for kind, src, name, dst, start, end in edges:
            inside_src, inside_dst = under(src, p), under(dst, p)
            if inside_src == inside_dst:
                continue
            if inside_dst and kind == "CALLS" and start:
                fan_in[(name, dst)] += 1
                spans[(name, dst)] = [int(start), int(end or start)]
            if inside_src:
                out_edges[f"{kind.lower()} -> {folder(dst)}"] += 1
            else:
                in_edges[f"{kind.lower()} <- {folder(src)}"] += 1
        # Function scope already carries the traced callers and callees as entries.
        starts = [{"name": "main", "path": f, "lines": [s, e], "note": TODO}
                  for f, s, e in mains if under(f, p)]
        n.setdefault("entry", (starts + [
            {"name": name, "path": path, "lines": spans[(name, path)], "note": TODO}
            for (name, path), _ in fan_in.most_common(6)])[:6])
        if not n["entry"]:
            del n["entry"]
        if out_edges or in_edges:
            n["_edges"] = {"out": dict(out_edges.most_common(12)),
                           "in": dict(in_edges.most_common(12))}
        services = Counter(s for f, s in grep_hits if under(f, p))
        if services:
            n["_external"] = [{"name": s, "url": url, "files": services[s]}
                              for _, s, url in SERVICES if s in services]
        if graph_files is not None and not any(under(f, p) for f in graph_files):
            n["_blind"] = "no file here is in the graph: read the source"


LINK_WORDS = {"CALLS": "call", "IMPORTS": "call", "DATA_FLOWS": "call", "HTTP_CALLS": "http",
              "GRPC_CALLS": "grpc", "ASYNC_CALLS": "async"}


def link_hints(root_node, edges):
    """Lead links between tree nodes: each edge lands on the deepest node at both ends."""
    nodes = [n for n in walk(root_node) if n["path"] is not None]
    lineage = {}

    def mark(n, above):
        lineage[n["id"]] = above
        for c in n.get("children") or []:
            mark(c, above + (n["id"],))

    mark(root_node, ())

    def owner(file):
        best = None
        for n in nodes:
            if under(file, n["path"]) and (best is None or len(n["path"]) > len(best["path"])):
                best = n
        return best

    counts = Counter()
    for kind, src, _, dst, _, _ in edges:
        word = LINK_WORDS.get(kind)
        a, b = owner(src), owner(dst)
        if not (word and a and b) or a is b:
            continue
        if a["id"] in lineage[b["id"]] or b["id"] in lineage[a["id"]]:
            continue
        counts[(a["id"], b["id"], word)] += 1
    by_id = {n["id"]: n for n in nodes}
    for (a, b, word), n in counts.most_common():
        hints = by_id[a].setdefault("_links", [])
        if len(hints) < 10:
            hints.append({"to": b, "label": word, "n": n})


def query_all(project, q):
    rows, cursor = [], None
    while True:
        page = {"cursor": cursor} if cursor else {}
        # One big page: each CLI call reloads the whole graph from disk.
        res = cbm("query_graph", project=project, format="json", max_rows=99998,
                  max_output_tokens=1000000, query=q, **page)
        rows += res.get("rows", [])
        cursor = res.get("next_cursor")
        if not (res.get("has_more") and cursor):
            return rows


def edge_rows(rows):
    """Drop same-file edges; blank the span of a target that has no body to read."""
    out = []
    for kind, src, name, dst, start, end, labels in rows:
        # The engine compares a property only to a literal, so same-file edges drop here.
        if not (src and dst) or src == dst:
            continue
        # A struct field or an interface method shares a name with a call, not a body.
        body = any(l in labels for l in ("Function", "Method")) and start != end
        out.append((kind, src, name, dst, start if body else None, end if body else None))
    return out


def graph_edges(project, prefixes):
    """Cross-file edges touching the prefixes; the filters run in the graph, not in Python."""
    near = " OR ".join(f"a.file_path STARTS WITH '{p}' OR b.file_path STARTS WITH '{p}'"
                       for p in prefixes if p)
    q = (f"MATCH (a)-[r:{EDGE_TYPES}]->(b) WHERE "
         f"NOT a.file_path =~ '{TEST_CYPHER}' " + (f"AND ({near}) " if near else "") +
         "RETURN type(r), a.file_path, b.name, b.file_path, b.start_line, b.end_line, "
         "labels(b)")
    return edge_rows(query_all(project, q))


def service_imports(root, sha, scope):
    pattern = "|".join(f"({p})" for p, _, _ in SERVICES)
    out = git(root, "grep", "-I", "-l", "-E", pattern, sha, "--", scope or ".",
              check=False) or ""
    hits = []
    for line in out.splitlines():
        path = line.split(":", 1)[1]
        if TEST_PATH.search(path):
            continue
        text = git(root, "show", f"{sha}:{path}", check=False) or ""
        hits += [(path, s) for p, s, _ in SERVICES if re.search(p, text)]
    return hits


def function_tree(project, name):
    found = cbm("search_graph", project=project, format="json",
                name_pattern=f"^{re.escape(name)}$", limit=5)
    groups = [g for g in found.get("groups", []) if g.get("rows")]
    if not groups:
        sys.exit(f"search_graph found no symbol named {name}")
    if len(groups) > 1 or len(groups[0]["rows"]) > 1:
        sys.exit(f"{name} is ambiguous: " + ", ".join(g["file"] for g in groups))
    file, row = groups[0]["file"], groups[0]["rows"][0]
    start, end = (int(x) for x in row[2].split("-"))
    root = placeholder(None, name, "function", None)
    root["entry"] = [{"name": name, "path": file, "lines": [start, end], "note": TODO}]
    root["io"] = {"inputs": [TODO], "outputs": [TODO], "goes": TODO}
    order = []
    for direction, pat in (("caller", "(c)-[:CALLS*1..3]->(f)"),
                           ("callee", "(f)-[:CALLS*1..3]->(c)")):
        res = cbm("query_graph", project=project, format="json", max_rows=500, query=(
            f"MATCH {pat} WHERE f.name = '{name}' AND f.file_path = '{file}' "
            "RETURN DISTINCT c.name, c.file_path, c.start_line, c.end_line"))
        for cname, cfile, cs, ce in res.get("rows", []):
            if cfile and not TEST_PATH.search(cfile):
                order.append((direction, str(PurePosixPath(cfile).parent), cname, cfile,
                              int(cs), int(ce or cs)))
    own = str(PurePosixPath(file).parent)
    packages = {}
    for direction, pkg, cname, cfile, cs, ce in order:
        n = packages.setdefault(pkg, placeholder(pkg, pkg.rsplit("/", 1)[-1], "package",
                                                 pkg) | {"_side": set(), "entry": []})
        n["_side"].add("own package" if pkg == own else direction)
        if len(n["entry"]) < 6:
            n["entry"].append({"name": cname, "path": cfile, "lines": [cs, ce],
                               "note": TODO})
    if own not in packages:
        packages[own] = placeholder(own, own.rsplit("/", 1)[-1], "package", own) | {
            "_side": {"own package"}}
    for n in packages.values():
        n["_side"] = sorted(n["_side"])
    # Callers first, then the function's own package, then callees: the reading order.
    rank = {"caller": 0, "own package": 1, "callee": 2}
    root["children"] = sorted(packages.values(), key=lambda n: min(rank[s] for s in n["_side"]))
    return root


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("scope", choices=["repo", "path", "function", "feature"])
    ap.add_argument("arg", nargs="?", default="")
    ap.add_argument("--packages", nargs="*", default=[])
    ap.add_argument("--depth", type=int, default=3)
    ap.add_argument("--out", required=True)
    a = ap.parse_args()

    root = run("git", "rev-parse", "--show-toplevel")
    warnings = []
    print("reindexing (mode=full)...", file=sys.stderr)
    idx = cbm("index_repository", repo_path=root, mode="full")
    project = idx["project"]
    sha = pin(root, warnings)
    web = web_url(git(root, "remote", "get-url", "origin", check=False))
    name = slugify(web.rsplit("/", 1)[1] if web else os.path.basename(root)) or "repo"
    files = [f for f in git(root, "ls-tree", "-r", "--name-only", sha).splitlines()]

    scope = a.arg.strip("/") if a.scope == "path" else ""
    if a.scope == "path" and not any(under(f, scope) for f in files):
        sys.exit(f"{scope} is not tracked at {sha[:7]}")
    if a.scope == "feature" and not a.packages:
        sys.exit("feature scope needs --packages: the directories the data visits, in order")

    if a.scope in ("repo", "path"):
        tree = build_tree([f for f in files if under(f, scope)], scope, a.depth)
        tree["kind"] = "repo" if a.scope == "repo" else "dir"
        tree["name"] = name if a.scope == "repo" else tree["name"]
        tree["stack"] = [{"name": TODO, "url": TODO, "role": TODO}]
    elif a.scope == "function":
        tree = function_tree(project, a.arg)
    else:
        tree = feature_tree(files, a.packages, a.depth)
        tree["name"] = a.arg
        tree["lifecycle"] = [{"text": TODO, "at": [TODO]}]
    tree["id"] = tree["id"] or ""
    tree["problem"] = TODO
    tree["principles"] = [{"claim": TODO, "cost": TODO,
                           "mammoth": {"rows": [[TODO, TODO], [TODO, TODO]], "breaks": TODO}}]
    tree["flow"] = {"nodes": [{"id": TODO, "name": TODO}],
                    "edges": [{"from": TODO, "to": TODO, "label": TODO}]}

    paths = [n["path"] for n in walk(tree) if n["path"] is not None]
    edges = graph_edges(project, [scope] if a.scope in ("repo", "path") else paths)
    graph_files = [r[0] for r in query_all(project, "MATCH (f:File) RETURN f.file_path")
                   if r and r[0]]
    mains = [(f, int(s), int(e)) for f, s, e in query_all(project, (
        "MATCH (f:Function) WHERE f.name = 'main' "
        "RETURN f.file_path, f.start_line, f.end_line")) if f and s and not TEST_PATH.search(f)]
    annotate(tree, edges, service_imports(root, sha, scope) if paths else [], graph_files,
             mains)
    link_hints(tree, edges)
    if a.scope == "function":
        tree.pop("_edges", None)

    slug = name if a.scope == "repo" else f"{name}--{slugify(a.arg)}"
    note = {
        "schema": 1, "slug": slug, "title": TODO,
        "generated": datetime.date.today().isoformat(),
        "repo": {"name": name, "path": root, "sha": sha, "web": web},
        "scope": {"kind": a.scope, "query": a.arg},
        "words": [{"term": TODO, "def": TODO}],
        "root": tree,
        "_index": {"project": project, "warnings": warnings,
                   **{k: idx.get(k) for k in ("excluded", "not_indexed_files",
                                              "parse_unusable") if idx.get(k)}},
    }
    os.makedirs(a.out, exist_ok=True)
    path = os.path.join(a.out, f"{slug}.json")
    with open(path, "w") as f:
        json.dump(note, f, indent=1, ensure_ascii=False)
    todo = json.dumps(note).count(f'"{TODO}"')
    print(f"{path}: {len(list(walk(tree)))} nodes, {todo} TODO fields")
    for w in warnings:
        print(f"warning: {w}")


if __name__ == "__main__":
    main()
