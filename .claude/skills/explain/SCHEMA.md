# Note schema

A note is one JSON object. `skeleton.py` writes it with every content field set to
`"TODO"`. `check.py` validates it, then `--install` writes it into the Obsidian vault as
`Explain/<slug>/`: the pages, and the note itself as `note.json`
([`OUTPUT.md`](OUTPUT.md)).

A key that starts with `_` is a hint from `skeleton.py` (see SKILL.md, step 3). `check.py`
ignores the hints, and `--install` strips them.

```jsonc
{
  "schema": 2,
  "slug": "harbor--report-builder",        // <repo>, or <repo>--<scope>; [a-z0-9-]
  "title": "How harbor builds a report",   // the main page's name and heading
  "generated": "2026-09-29",              // output of `date +%F`
  "repo": {                                // null for a concept
    "name": "harbor",
    "path": "/Users/me/Documents/harbor",  // git toplevel; check.py reads git here
    "sha": "<40-hex commit>",             // every link pins to this commit
    "web": "https://github.com/acme/harbor"  // null when no GitHub remote
  },
  "scope": { "kind": "repo | path | function | feature | concept", "query": "report builder" },
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
| `kind` | enum | `repo`, `dir`, `service`, `package`, `file`, `group`, `function`, `feature`, `concept` |
| `path` | string or null | Repo-relative. `""` is the repo root. `null` for `group`, `function`, `feature`, `concept` |
| `summary` | string | One sentence, at most 140 characters. The tree prints it beside the name |
| `role` | string[] | One paragraph, at most 160 characters (two lines on a phone): why the node exists |
| `flow` | Flow | No cap on the root, 12 shapes at most below it. Required on the root, on every service, and on a node that touches a database, a queue, or an external service |
| `lifecycle` | Step[] | Optional. On the root, a `service`, or any node with a `flow`: see [Lifecycle](#lifecycle) |
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
draws that relation. Put a link on the deepest node that makes the call. Its page lists it under
**Sends to**, and the target's page under **Receives from**. The label follows
[Flow labels](#flow-labels).

### Flow

```json
{ "nodes": [{ "id": "scheduler", "name": "job-scheduler" },
            { "id": "pg", "name": "PostgreSQL: jobs", "store": true }],
  "edges": [{ "from": "scheduler", "to": "pg", "label": "writes DB: jobs" }] }
```

`render.mjs` lays the flow out with ELK, top to bottom, and draws it as a static SVG.
The root flow is the map: the first graph the reader sees. Each shape carries its number
in the `nodes` list, and the key under the map follows that order. List `nodes` from the
entry point to the endpoint: in a loop, an edge from a later node to an earlier one draws
backward. `store` marks a database, a queue, or a bucket, and the map draws it as a pill.
`end` is `"in"` or `"out"`: it pins the shape to the top or the bottom row. The root flow and every service flow need at least
one of each; several `out` shapes are allowed. An `in` shape has no incoming edge, and an
`out` shape has no outgoing edge. Each edge `label` follows [Flow labels](#flow-labels).

`decision` is optional, `true` on a shape that branches, such as a cache hit or miss. The
map draws it as a rhombus. Label each outgoing edge with its branch, and say both
outcomes in `about`. `both` is optional, `true` on an edge for a call that answers: the
map draws an arrow at each end. A `both` edge makes neither end a source or a destination. `back` is optional,
`true` on an edge that loops back up the map, such as a vendor that answers on a webhook of
a service drawn above it. The layout reverses it and keeps its arrow on `to`, so
the loop never re-layers the shapes above it.

`node` is optional. It is the `id` of the tree node the shape stands for, never the root.
`null` marks an outside system. The root flow draws one shape per service, store, and
outside system, never a package, and each service takes exactly one root shape:

```json
{ "id": "builder", "name": "report-builder", "node": "services/report-builder" }
```

`about` is required on each root shape with no tree `node`, at most 300 characters: one
or two sentences on what the system is and what it does in the loop. It is the shape's line
in the key. A shape with a `node` links that node's page, with its summary.
Below the root, `about` is optional with the same cap.

`doc` is optional: a tracked file with an optional anchor
(`docs/velou/how-it-works.md#the-funnel`). The key line links it as **Read more**, so a shape
stays short and the doc holds the depth.

`external` is optional, on a shape that stands for another repo. `repo` names it, and
`url` is its docs (`https://...`) or its own explain note (`#note=<slug>`). The key line
links the other note's main page once that note is in the vault. A shape with
`external` has no `node`:

```json
{ "id": "metis", "name": "metis", "external": { "repo": "metis", "url": "#note=metis" } }
```

`group` is optional, at most 32 characters: the name of a frame the map draws around
every shape with that name. One group is one deployment: the scope's own cloud project,
another project the data passes through, or the vendors a service calls. The frames let
the reader see who owns what, so give every shape that a deployment owns its group:

```json
{ "id": "openai", "name": "OpenAI", "node": null, "group": "Model providers" }
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

`detail` is required on each root step, at most 480 characters: the page prints it after
the step. Below the root, `detail` is optional with the same cap.

At most 6 steps, one per stage of the data, in order. `text` is one sentence: what moves,
and what that means. `at` names the shapes of the same
node's `flow` that the step touches. The page cites their key numbers after the step, so the
reader finds them on the map. A lifecycle sits on the root or on a `service`. The
root needs one for `feature` scope. Write one for every scope: the root lifecycle is how the
reader reads the map.

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
| `principles` | always | 1–3 of `{ "claim", "why", "example": [[case, what the system does], …], "except"?, "cost", "source"? }`, with 2 or 3 rows. `source` is the 1-based number of the `sources` entry that backs it, required for a concept. No code identifier: no `snake_case`, no `table.column`, no backticks. The page prints `Except:` before `except` |
| `stack` | `repo`, `path` | `[{ "name", "url", "role" }]`: language, runtime, main libraries |
| `io` | `function` | `{ "inputs": [..], "outputs": [..], "goes": "where the result goes" }` |
| `sources` | always | `[{ "title", "url", "why" }]`, an `https` url each. At least 3 for a concept, 1 otherwise. The best read first |
| `check` | always | 3 of `{ "q", "a" }`. A question of at most 15 words; the page folds the answer in a callout |
| `further` | optional | Up to 3 of `{ "q", "source", "at" }`: `source` is the 1-based number of a `sources` entry, `at` its section |
| `plates` | optional | `[{ "title", "svg", "key": [..], "caption" }]`: a sketch, one key line per drawn callout `1` to `n`, and one caption sentence with the true numbers. See [`PLATES.md`](PLATES.md) |

The main page shows the ramp-up below the map, in this order: the problem, the principles,
and the plates under **Why it works**, then **Check yourself**, **Go further**, and
**Sources**.

## Concept

A concept has `repo: null`, a root of `kind: "concept"` with `path: null`, and no
`children`. Its flow shapes omit `node`: the map dashes a shape with `node: null`, for a
system outside the repo. `check.py` skips every git check, so the `sources` carry the
evidence. A `lifecycle` with a `detail` on each step is required: one trip through the
machine.

```json
{ "schema": 2, "slug": "consistent-hashing", "title": "Consistent hashing",
  "generated": "2026-10-11", "repo": null,
  "scope": { "kind": "concept", "query": "consistent hashing" },
  "words": [{ "term": "ring", "def": "The hash space, bent into a circle." }],
  "root": { "id": "", "name": "Consistent hashing", "kind": "concept", "path": null,
    "summary": "...", "role": ["..."], "overview": "...", "problem": "...",
    "principles": [...], "flow": {...}, "lifecycle": [...],
    "plates": [...], "check": [...], "further": [...], "sources": [...] } }
```

## Flow labels

Label each edge with how the data moves, so the reader sees sync against async at a
glance. Start each label with one of these words: `call`, `async`, `http`, `grpc`,
`reads DB`, `writes DB`, `queue`, `file`. Add the payload after a colon:
`async: upload`, `reads DB: jobs`. Name a database or a queue by its real name in the
shape: `PostgreSQL: indexes`. `check.py` greps that name in the repo.

Keep a label to its leading word and a payload of one to three words, about 24
characters. The label width sets the gap between two columns of the layout, so a long
label widens the whole map. The lifecycle steps carry the detail.
