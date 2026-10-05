# Note schema

A note is one JSON object. `skeleton.py` writes it with every content field set to
`"TODO"`. `check.py` validates it, then installs it as
`~/.claude/.onboard/notes/<slug>.js`, so the viewer can load it from `file://`.

A key that starts with `_` is a hint from `skeleton.py` (see SKILL.md, step 3). `check.py`
ignores the hints, and `--install` strips them.

```jsonc
{
  "schema": 2,
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
  "words": [{ "term": "render job", "def": "One clause." }],  // most important first
  // check.py greps each term in the repo. A term from a doc outside it adds "from": "<the doc>"
  "root": { /* Node */ }
}
```

## Node

| Key | Type | Rule |
|---|---|---|
| `id` | string | Unique in the note. Use the path, or a slug for a group |
| `name` | string | What the tree shows. The directory name, or a short noun |
| `kind` | enum | `repo`, `dir`, `service`, `package`, `file`, `group`, `function`, `feature` |
| `path` | string or null | Repo-relative. `""` is the repo root. `null` for `group`, `function`, `feature` |
| `summary` | string | One sentence, at most 140 characters. The tree prints it beside the name |
| `role` | string[] | One paragraph, at most 160 characters (two lines of the panel): why the node exists |
| `flow` | Flow | No cap on the root, 12 shapes at most below it. Required on the root, on every service, and on a node that touches a database, a queue, or an external service |
| `lifecycle` | Step[] | Optional. On the root and on a `service` only: see [Lifecycle](#lifecycle) |
| `links` | Link[] | Optional. How this node talks to other nodes of the tree |
| `entry` | Entry[] | Optional. Ordered by importance |
| `external` | Service[] | Optional. Services outside the repo this node calls |
| `children` | Node[] | Optional. Empty or absent on a leaf |

Kind rules:

- `service` is a deployable unit: it has its own main, Dockerfile, deploy entry, or cron
  entry. Its subtree holds `package` nodes only, grouped past 12; no `dir` node sits under
  it, and each package keeps its directory in `path`. `path` is the service's directory.
  Its flow carries `end` markers, like the root flow.
- `package` is the deepest code level. A `package` node has no children.
- `file` is a leaf beside directories, for a tracked file that carries a decision
  (`install.sh`, `.gitignore`). It gets a summary and a role, never a file analysis.
- `group` is a synthetic node that collects siblings when a directory has more than 12
  children. Its children keep their real paths.
- `path` on `repo`, `dir`, `service`, `package`, and `file` must be tracked by git at
  `repo.sha`.

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

The viewer lays the flow out with ELK. The root flow is the map: the first graph the
reader sees, beside the root's panel. List `nodes` from the entry point
to the endpoint: in a loop, an edge from a later node to an earlier one draws backward, so
the list order sets left to right. `store` marks a database, a queue, or
a bucket, and the viewer draws it as a pill. `end` is `"in"` or `"out"`: it pins the
shape to the first or the last column. The root flow and every service flow need at least
one of each; several `out` shapes are allowed. An `in` shape has no incoming edge, and an
`out` shape has no outgoing edge. Each edge `label` follows [Flow labels](#flow-labels).

`node` is optional. It is the `id` of the tree node the shape stands for, never the root.
`null` marks an outside system. The root flow draws one shape per service, store, and
outside system, never a package, and each service takes exactly one root shape:

```json
{ "id": "builder", "name": "report-builder", "node": "services/report-builder" }
```

`about` is required on each root shape with no tree `node`, at most 300 characters: one
or two sentences on what the system is and what it does in the loop. The panel shows it
when the reader clicks the shape. A shape with a `node` shows that node's summary and role.

`external` is optional, on a shape that stands for another repo. `repo` names it, and
`url` is its docs (`https://...`) or its own onboard note (`#note=<slug>`). A shape with
`external` has no `node`:

```json
{ "id": "metis", "name": "metis", "external": { "repo": "metis", "url": "#note=metis" } }
```

`check.py` greps the real name, the part after the colon, of each `store` shape that a
`queue`, `reads DB`, or `writes DB` edge touches. `from` is optional on a store shape: it
names the repo that owns the queue or table, and skips that grep:

```json
{ "id": "q", "name": "Pub/Sub: extractor topic", "store": true, "from": "metis" }
```

### Lifecycle

```json
[{ "text": "The scheduler queues one render job.", "at": ["scheduler", "pg"],
   "detail": "Job 8812 asks for the March sales report. The scheduler writes a jobs row, and the builder picks it up on its next poll." }]
```

`detail` is required on each root step, at most 480 characters: the panel beside the map
shows it while the step is lit. A service step takes no `detail`.

At most 6 steps, one per stage of the data, in order. `at` names the shapes of the same
node's `flow` that the step touches. The viewer steps through the graph and lights those
shapes and the edges between them. A lifecycle sits on the root or on a `service`. The
root needs one for `feature` scope. Write one for every scope: the root flow is the map,
and its header steps through the root lifecycle.

### Service

```json
{ "name": "Amazon S3", "url": "https://docs.aws.amazon.com/s3/",
  "how": "Reads snapshots, writes built indexes. Async, through the upload queue." }
```

`url` points to the vendor's own documentation.

## Root-only keys

| Key | When | Shape |
|---|---|---|
| `overview` | always | string, two to five sentences, at most 600 characters: the whole idea, shown above the map |
| `problem` | always | string, at most 240 characters (three lines): why the subject exists |
| `principles` | always | 1–3 of `{ "claim", "why", "example": [[case, what the system does], …], "except"?, "cost" }`, with 2 or 3 rows. No code identifier: no `snake_case`, no `table.column`, no backticks. The viewer prints `Except:` before `except` |
| `stack` | `repo`, `path` | `[{ "name", "url", "role" }]`: language, runtime, main libraries |
| `io` | `function` | `{ "inputs": [..], "outputs": [..], "goes": "where the result goes" }` |

## Flow labels

Label each edge with how the data moves, so the reader sees sync against async at a
glance. Start each label with one of these words: `call`, `async`, `http`, `grpc`,
`reads DB`, `writes DB`, `queue`, `file`. Add the payload after a colon:
`async: upload`, `reads DB: jobs`. Name a database or a queue by its real name in the
shape: `PostgreSQL: indexes`. `check.py` greps that name in the repo.

Keep a label to its leading word and a payload of one to three words, about 24
characters. The label width sets the gap between two columns of the layout, so a long
label widens the whole map. The lifecycle steps carry the detail.
