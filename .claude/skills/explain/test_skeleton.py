#!/usr/bin/env python3
"""python3 test_skeleton.py: the parts of skeleton.py that need no git or graph."""
from skeleton import (annotate, build_tree, edge_rows, feature_tree, link_hints,
                      service_candidates, service_dirs, service_tree, slugify, walk, web_url)

assert web_url("git@github.com:acme/harbor.git") == "https://github.com/acme/harbor"
assert web_url("https://github.com/shortcuts/dotfiles") == "https://github.com/shortcuts/dotfiles"
assert web_url("git@gitlab.com:o/r.git") is None
assert slugify(".config") == "config"
assert slugify("Report builder!") == "report-builder"

files = ["README.md", "install.sh",
         "nvim/init.lua", "nvim/lua/plugins/a.lua", "nvim/lua/plugins/b.lua",
         "modules/services/api/go.mod", "modules/services/api/cmd/main.go",
         "modules/services/api/internal/x.go"]
tree = build_tree(files, "", max_depth=3)
by_id = {n["id"]: n for n in [tree, *tree["children"]]}
assert tree["_files"] == ["README.md", "install.sh"]
# modules and services each hold one directory and no file, so the chain folds.
api = by_id["modules/services/api"]
assert api["name"] == "modules/services/api"
assert api["kind"] == "package" and api["_leaf_reason"] == "package marker", api
lua = by_id["nvim"]["children"][0]
assert lua["id"] == "nvim/lua/plugins" and lua["kind"] == "package", lua

edges = [("CALLS", "nvim/init.lua", "setup", "nvim/lua/plugins/a.lua", "3", "9"),
         ("CALLS", "install.sh", "setup", "nvim/lua/plugins/a.lua", "3", "9"),
         ("HTTP_CALLS", "nvim/lua/plugins/b.lua", "/api", "modules/services/api/cmd/main.go",
          None, None)]
annotate(tree, edges, [("nvim/lua/plugins/b.lua", "OpenAI API")], graph_files=["nvim/init.lua"])
assert lua["entry"][0] == {"name": "setup", "path": "nvim/lua/plugins/a.lua",
                           "lines": [3, 9], "note": "TODO"}, lua["entry"]
assert lua["_edges"]["out"] == {"http_calls -> modules/services/api/cmd": 1}, lua["_edges"]
assert lua["_external"][0]["name"] == "OpenAI API"
assert "_blind" in api and "_blind" not in by_id["nvim"]
link_hints(tree, edges)
# Each edge lands on the deepest nodes at both ends; a root-level file is the root's own.
assert lua["_links"] == [{"to": "modules/services/api", "label": "http", "n": 1}], lua
assert "_links" not in tree

# A struct field or an interface method is no entry point: the reader needs a body.
rows = [["CALLS", "a.go", "Param", "b/x.go", "75", "75", '["Field"]'],
        ["CALLS", "a.go", "Embed", "b/x.go", "33", "33", '["Method"]'],
        ["CALLS", "a.go", "Run", "b/x.go", "10", "20", '["Function"]'],
        ["CALLS", "b/x.go", "Run", "b/x.go", "10", "20", '["Function"]']]
assert edge_rows(rows) == [("CALLS", "a.go", "Param", "b/x.go", None, None),
                           ("CALLS", "a.go", "Embed", "b/x.go", None, None),
                           ("CALLS", "a.go", "Run", "b/x.go", "10", "20")], edge_rows(rows)

# Nothing calls main, so fan-in never finds it; a binary still starts there.
annotate(tree, [], [], None, mains=[("modules/services/api/cmd/main.go", 3, 12)])
assert api["entry"][0] == {"name": "main", "path": "modules/services/api/cmd/main.go",
                           "lines": [3, 12], "note": "TODO"}, api["entry"]

# A --packages directory expands like a path scope, not into one flat leaf.
feat = feature_tree(files, ["nvim", "modules/services/api"], max_depth=3)
assert [c["id"] for c in feat["children"]] == ["nvim", "modules/services/api"]
assert feat["children"][0]["kind"] == "dir", feat["children"][0]
assert feat["children"][0]["children"][0]["id"] == "nvim/lua/plugins"
assert feat["children"][1]["_leaf_reason"] == "package marker"

# A Go binary is a service: its own packages sit under it, packages two binaries use go shared.
assert service_dirs([("cmd/api/main.go", 3, 9), ("cmd/worker/main.go", 1, 5),
                     ("scripts/tool.py", 1, 4)], "") == ["cmd/api", "cmd/worker"]
assert service_dirs([("main.go", 1, 2), ("cmd/api/main.go", 1, 2)], "") == ["cmd/api"]
files = ["README.md", "docs/guide.md", "cmd/api/main.go", "cmd/api/handlers/h.go",
         "cmd/worker/main.go", "pkg/db/db.go", "pkg/log/log.go"]
imports = [("cmd/api", "cmd/api/handlers"), ("cmd/api/handlers", "pkg/db"),
           ("cmd/worker", "pkg/db"), ("cmd/worker", "pkg/log"), ("cmd/api", "vendor/x")]
svc = service_tree(files, "", ["cmd/api", "cmd/worker"], imports, 3)
kids = {c["id"]: c for c in svc["children"]}
assert list(kids) == ["cmd/api", "cmd/worker", "shared-packages", "docs"], list(kids)
assert svc["_files"] == ["README.md"], svc
assert kids["cmd/api"]["kind"] == "service" and "flow" in kids["cmd/api"]
assert [{k: c[k] for k in ("id", "name", "kind")} for c in kids["cmd/api"]["children"]] == [
    {"id": "cmd/api/handlers", "name": "handlers", "kind": "package"}], kids["cmd/api"]
assert [(c["id"], c["name"]) for c in kids["cmd/worker"]["children"]] == [("pkg/log", "pkg/log")]
shared = kids["shared-packages"]
assert shared["kind"] == "group" and shared["path"] is None
assert [c["id"] for c in shared["children"]] == ["pkg/db"], shared
assert "vendor/x" not in {n["id"] for n in walk(svc)}
one = service_tree(files, "cmd/worker", ["cmd/worker"], imports, 3)
assert one["kind"] == "service" and one["id"] == "cmd/worker", one
assert [c["id"] for c in one["children"]] == ["pkg/db", "pkg/log"], one
assert service_candidates(files + ["build/Dockerfile", "deploy/chart/Chart.yaml", "ops/crontab"],
                          ["cmd/api"], [("k8s/worker.yaml", "CronJob")]) == [
    {"path": "cmd/api", "evidence": "main"},
    {"path": "build/Dockerfile", "evidence": "Dockerfile"},
    {"path": "deploy/chart", "evidence": "helm chart"},
    {"path": "k8s/worker.yaml", "evidence": "k8s CronJob"},
    {"path": "ops/crontab", "evidence": "crontab"}]
print("ok")
