# Note schema

A note is one JSON object. `skeleton.py` writes it with every content field set to
`"TODO"`. `check.py` validates it, then installs it as
`~/.claude/.onboard/notes/<slug>.js`, so the viewer can load it from `file://`.

A key that starts with `_` is a hint from `skeleton.py` (see SKILL.md, step 3). `check.py`
ignores the hints, and `--install` strips them.

```jsonc
{
  "schema": 1,
  "slug": "harbor--report-builder",        // <repo>, or <repo>--<scope>; [a-z0-9-]
  "title": "How harbor builds a report",   // the viewer header
  "generated": "2026-09-29",              // output of `date +%F`
  "repo": {
    "name": "harbor",
    "path": "/Users/me/Documents/harbor",  // git toplevel; check.py reads git here
    "sha": "<40-hex commit>",             // every link pins to this commit
    "web": "https://github.com/acme/harbor"  // null when no GitHub remote
  },
  "scope": { "kind": "repo | path | function | feature", "query": "report builder" },
  "words": [{ "term": "render job", "def": "One clause." }],  // most important first; the viewer shows 5
  "root": { /* Node */ }
}
```

## Node

| Key | Type | Rule |
|---|---|---|
| `id` | string | Unique in the note. Use the path, or a slug for a group |
| `name` | string | What the tree shows. The directory name, or a short noun |
| `kind` | enum | `repo`, `dir`, `package`, `file`, `group`, `function`, `feature` |
| `path` | string or null | Repo-relative. `""` is the repo root. `null` for `group`, `function`, `feature` |
| `summary` | string | One sentence, at most 140 characters. The tree prints it beside the name |
| `role` | string[] | One paragraph, at most 160 characters (two lines of the panel): why the node exists |
| `flow` | Flow | 7 shapes at most on the root, 12 below it. Required on the root, and on a node that touches a database, a queue, or an external service |
| `links` | Link[] | Optional. How this node talks to other nodes of the tree |
| `entry` | Entry[] | Optional. Ordered by importance. The viewer shows 3 and folds the rest |
| `external` | Service[] | Optional. Services outside the repo this node calls |
| `children` | Node[] | Optional. Empty or absent on a leaf |

Kind rules:

- `package` is the deepest code level. A `package` node has no children.
- `file` is a leaf beside directories, for a tracked file that carries a decision
  (`install.sh`, `.gitignore`). It gets a summary and a role, never a file analysis.
- `group` is a synthetic node that collects siblings when a directory has more than 12
  children. Its children keep their real paths.
- `path` on `repo`, `dir`, `package`, and `file` must be tracked by git at `repo.sha`.

### Entry

```json
{ "name": "BuildIndex", "path": "modules/pkg/engine/build.go", "lines": [37, 55],
  "note": "Turns one render job into a PDF report." }
```

`path` is a file tracked at `repo.sha`. `lines` come from the graph node
(`start_line`, `end_line`).

### Link

```json
{ "to": "modules/pkg/harbordb", "label": "writes DB: job row, report ID" }
```

`to` is the `id` of another node, never an ancestor or a descendant: the tree already
draws that relation. Put a link on the deepest node that makes the call. The viewer lifts
it to whichever level the reader is on, so `driver -> harbordb` also shows as
`report-builder-driver -> harbordb` one level up. The label follows
[Flow labels](#flow-labels).

### Flow

```json
{ "nodes": [{ "id": "scheduler", "name": "job-scheduler" },
            { "id": "pg", "name": "PostgreSQL: jobs", "store": true }],
  "edges": [{ "from": "scheduler", "to": "pg", "label": "writes DB: jobs" }] }
```

The viewer lays the flow out with ELK, like the map. `store` marks a database, a queue, or
a bucket, and the viewer draws it as a pill. Each edge `label` follows
[Flow labels](#flow-labels).

### Service

```json
{ "name": "Amazon S3", "url": "https://docs.aws.amazon.com/s3/",
  "how": "Reads snapshots, writes built indexes. Async, through the upload queue." }
```

`url` points to the vendor's own documentation.

## Root-only keys

| Key | When | Shape |
|---|---|---|
| `problem` | always | string, at most 240 characters (three lines): what breaks without the subject |
| `principles` | always | 1–3 of `{ "claim", "mammoth": { "rows": [[scene, subject], …], "breaks" }, "cost" }`, with 2 or 3 rows. No code identifier: no `snake_case`, no `table.column`, no backticks. The viewer prints `Breaks down at:` before `breaks` |
| `stack` | `repo`, `path` | `[{ "name", "url", "role" }]`: language, runtime, main libraries |
| `lifecycle` | `feature` | `[{ "text", "at": [shape id, …] }]`: at most 6 steps, one per stage of the data, in order. `at` names the root `flow` shapes the step touches. The viewer steps through the graph and lights those shapes and the edges between them |
| `io` | `function` | `{ "inputs": [..], "outputs": [..], "goes": "where the result goes" }` |

## Flow labels

Label each edge with how the data moves, so the reader sees sync against async at a
glance. Start each label with one of these words: `call`, `async`, `http`, `grpc`,
`reads DB`, `writes DB`, `queue`, `file`. Add the payload after a colon:
`async: upload`, `reads DB: jobs`. Name a database or a queue by its real name in the
shape: `PostgreSQL: indexes`.
