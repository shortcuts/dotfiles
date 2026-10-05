---
name: onboard
description: Onboard an engineer on a repository, directory, feature, or function with one zoomable HTML map - the stack, each package's role, how the data flows, and links to the code.
disable-model-invocation: true
argument-hint: "Nothing (whole repo), a path, a function name, or a feature in words"
---

Write one **note**: the data for a zoomable map of the subject. The viewer at
`~/.claude/.onboard/index.html` opens on the title and the root `overview`, then the map
with a panel at its right. The map is the root `flow`: the full loop of the data, from
every system that sends the input to the index or store where the result lands. A header
above it steps through the root `lifecycle`, one step at a time, and lights that step's
shapes.

The panel shows only the selection. It opens on the current step and its `detail`. A click
on a shape with a `node` shows that node's summary and role; a click on any other shape
shows its `about`. A node's panel lists what is inside it, so the reader walks the tree
from the map: a service's panel lists its packages, and **Show its data flow** opens the
service's flow, with its lifecycle as the step list.

**The reader** is an engineer new to the codebase. They want the mental map: what each
part is for, how the parts talk, and where the data goes. Leave out implementation
detail: error paths, early returns, retries, logging, function parameters, column names,
and environment variables never reach the prose. The entry points carry the code names.

**The split.** `skeleton.py` does the deterministic work:
- it reindexes the graph and pins the commit;
- it builds the tree from git, services first when the scope has a Go `main`, and finds each node's entry points, with line ranges;
- it adds graph facts as `_` hint keys.

You write every field it leaves as `TODO`: the prose, the flows, and the judgment calls.
`check.py` rejects any `TODO` left over.

**The note is done when:**

- The reader can say what the scope produces, who uses it, and what they get from it.
- The reader can draw the scope's services, stores, and outside systems, and the arrows
  between them, from memory.
- For each service, the reader can say what starts it, what it writes, and which packages
  it runs.
- For each package, the reader can say in one sentence why it exists.
- Each arrow says how the data moves: a plain call, async, HTTP, gRPC, a queue, or the DB.
- The reader can find each term and each case of the note in the repo.
- `python3 check.py <note.json> --install` in this skill's folder prints `ok`.

## 1. Resolve the scope

| Argument | Scope |
|---|---|
| none | `repo` |
| a path that exists | `path` |
| an identifier that `search_graph` finds | `function` |
| anything else | `feature`, named in the user's words |

An argument that fits two rows (a word that is a directory and a function): ask which.
A feature whose words match one directory name (`report builder` and
`report-builder-driver/`): ask if the user means that directory or the feature. A feature
whose words match only infra or docs directories (`terraform/`, `k8s/`, `docs/`) stays a
`feature`: find its code in step 2, and do not ask.

## 2. Run the skeleton

Pick a fresh work folder, so a parallel run cannot overwrite your files:
`work=<scratchpad>/onboard-$(date +%s)`. From inside the repository:

```bash
python3 <skill>/skeleton.py repo                 --out "$work"
python3 <skill>/skeleton.py path modules/pkg     --out "$work"
python3 <skill>/skeleton.py function BuildIndex  --out "$work"
python3 <skill>/skeleton.py feature "report builder" --packages <dir> <dir> ... --out "$work"
```

It prints the note's path and every warning. Tell the user each warning, for example
`links pin to 614bdc2, 4 commits behind HEAD`.

For `repo` and `path` scope, each directory with a Go `main` becomes a `service` node, and
the root gets a `_services` hint (step 3).

**Feature scope needs the packages first.** Find the feature's code with
`search_graph` (`query`, and `semantic_query` with two to four phrasings), `search_code`
for its literal names, and `Route` nodes for its endpoints. Semantic search misses on
some repos. Then grep the SQL, protobuf, and config files for the feature's names. Pass
the directories to `--packages` in the order the data visits them.

The skeleton writes every feature directory as a flat `package` or `dir`, even a
`cmd/<binary>` that a Dockerfile or a chart deploys. Shape the tree in step 3 as for a
repo scope:

- each deployable directory becomes a `service`, with a `flow` and a `lifecycle`;
- a package that only one service imports moves under that service;
- a package that several services import moves into the `shared` group (id
  `shared-packages`, `kind: "group"`, `path: null`);
- a `dir` whose children are only mocks, SQL files, or embedded assets becomes one
  `package`: drop its children.

## 3. Confirm the services, then shape the tree

The skeleton holds every tracked directory down to the package leaf. With a service, the
root's children are three parts: the `service` nodes, the `shared` group (id
`shared-packages`), and the leftover directories.

**Confirm each service.** Each `_services` entry is `{path, evidence}`. The evidence is
`main`, `Dockerfile`, `helm chart`, `k8s <Kind>`, or `crontab`. Read each one with
`git show <sha>:<path>`, then settle it:

- `main`, a node that is already a `service`: keep it when a Dockerfile, chart, manifest,
  or cron entry runs it, or when its code serves requests or consumes a queue. A `main`
  that is only a dev tool, a code generator, or a one-off migration becomes `kind: "dir"`:
  keep its children and remove its `flow` placeholder.
- `Dockerfile`, `helm chart`, `k8s <Kind>`, or `crontab` that runs a binary already in the
  tree as a `service`: make no tree change. Use it in step 4 as the service's entry (a
  cron schedule, a `CronJob`).
- The same evidence for code in a directory that is not a service yet (a Python worker
  with its own Dockerfile): set that node's `kind` to `"service"` and add a `flow` with
  `end` markers. Its subtree holds `package` nodes only. Each `dir` child becomes a
  `package` (remove its children, keep its `path` and `id`) or gives way to its own
  `package` children. Group them past 12.
- A Dockerfile, chart, or manifest that builds several binaries: make no tree change. It
  maps to no single directory.

The `shared` group keeps the skeleton's shape. Collect its children into `group` nodes past
12. It gets no root flow shape, and no root shape points at a package inside it: a shared
package runs inside each service that imports it, so the service flows draw it. Shape the
leftover directories with the table below.

`path` scope on one service directory (`path services/report-builder`): the root is that
`service` node, and its flow is the root flow. Draw its packages as shapes with no `node`,
because a root shape never points at a package.

| Hint | What to do |
|---|---|
| `_services` | Root only. Each deployable candidate with its evidence. Settle each one as in *Confirm each service* |
| `_group` | More than 12 children: collect them into `group` nodes by what they do, "Search services", "Ingestion" |
| `_files` | The directory's own files. Add a `file` leaf only for a file that carries a decision (`install.sh`, a whitelist `.gitignore`) |
| `_leaf_reason` | Why the branch stops. Turn a `package` into a `dir` with children only when its parts serve different readers |
| `_blind` | The graph holds no file here (a language without a parser, or an excluded path). Read the source with `git show <sha>:<path>` |
| `_side` | Function scope: caller, callee, or own package. Keep the order: callers, own package, callees |

Remove the nodes a newcomer does not need, such as vendored code and generated code.
Keep `path` and `id` as the skeleton wrote them. Keep the `kind` the skeleton wrote,
except the changes in *Confirm each service*.

## 4. Confirm the links

The panel lists each node's links under **Sends to** and **Receives from**, and a note
with no root flow draws them over the box map. The links are the part that shows how the
system talks, so a missing link is a wrong map. Three hints lead you
there:

- `_links`: node-to-node edges from the graph, with the edge count `n`;
- `_edges`: every edge that crosses the node's border, by type and folder;
- `_external`: the services that the node's imports name.

All three are leads, not facts:
- The graph links two symbols that share a name, so a `calls` edge can be false.
- A queue, a table, or an HTTP call made through a wrapper often has no edge at all.

Before a flow shows an arrow, confirm it in the code:
- `get_code_snippet` on the entry point;
- `trace_path(mode="data_flow")` for what the data carries;
- `search_code` for the table, topic, or endpoint name.

Label an arrow `async` only when the code returns before the work ends: a goroutine, a
queue, a callback, or a ticker. A name like `AsyncFoo` is not proof.

Write each confirmed link into `links` on the deepest node that makes the call. Then add
the links the graph cannot see:

- two services that share a table: a link from each one to the node that owns the table
  (`writes DB: jobs`, `reads DB: jobs`);
- a producer and a consumer of one queue or topic;
- a process that starts another one, or reads a file the other one writes.

**Trace the boundary.** The root flow is a high-level system view: one shape per service,
store, and outside system, never a package. Find where the data enters and where it
leaves, including systems outside the repo:

- **Entry:** who or what starts the work: a user, a scheduler, an upstream service, or a
  source store the scope reads from (`Route` nodes, topic subscribers, cron entries, the
  clients in `_external`);
- **Exit:** who consumes the result: a database, an index, a queue, or a downstream
  service.

Read each service's calls from its config and clients: the gRPC and HTTP client
constructors, the queue and topic names, the table names. Those name the neighbours the
graph misses.

**Trace the full loop, past the scope.** The root flow is the map, so it draws every path
the data takes, not only the scope's own services:

- **Every input path.** Each system that sends the input gets its own path. A live write
  that another repo forwards (Metis and its indexing extension) is one path. A reindex
  that an admin API or a scheduler queues for an extractor is another. Find the callers by
  the client package of the scope's API (`grep` its import path across the repo), and read
  the docs of the other repos the scope serves.
- **The system that writes the result.** When another system writes the destination (the
  scope sends a partial update that Metis indexes), draw that system between the scope
  and the destination.
- **Every outside call.** Draw each vendor and each download the services make: model
  providers, image URLs, other APIs. One shape each, `node: null`.
- A service of this repo that sits outside the scope's tree (an extractor, a scheduler)
  is a shape with no `node`.

Trace each service the same way. Its entry (a route, a topic subscriber, a cron entry from
`_services`) is its flow's `end: "in"`, and its last write is its `end: "out"`.

**Done when:** each node the data passes through has at least one link in or out, and a
reader can follow the data from its entry to its last write without leaving the tree.

## 5. Write the content

Read [`SCHEMA.md`](SCHEMA.md) for each field. Follow
[`../_shared/STYLE.md`](../_shared/STYLE.md), except its mammoth: the `example` of each
principle replaces it. The word list is `words`.

**Keep the subject's words.** The team already named its parts. The reader searches the
code, the docs, and the chat for those names, so a renamed part is a part they cannot
find.

- Take each term, node name, and flow shape name as the code, the docs, or the user's
  diagram spell it. The code says `judgement`: the note says "judgement", not
  "tie-break".
- A term that needs explaining keeps its name. Its `words` definition explains it.
- A code name in prose reads as its words: `last_scanned_job_id` is "last scanned job
  ID", in every field of the note, principles included.
- `check.py` greps each term of `words` in the repo. A term from a doc outside the repo
  names that doc in `from`.
- `check.py` also greps the name of each queue or table store in a flow. A store that
  another repo owns names that repo in `from`.

**Take the examples from the repo.** A reader pictures a case they can find again.

- Take each case from the repository: a test fixture, a sample payload, a seed file, a
  prompt, or a doc. Keep its real values: the ID, the field value, the count.
- No repo case fits: invent one with the repo's data shape, and say so in the row.
- Each case is an object of the subject itself: a job, a request, a row. A comparison
  from daily life makes the reader map it back, and the map is where they get lost.

**The root** tells the outcome, not the mechanism. The reader first needs what the scope
produces and who uses it. The children carry how it works.

- `overview`: two to five sentences above the map, the whole idea in plain words. Say
  what the scope produces, for whom, the paths the input takes, and where the result
  lands. The reader reads it before the map, so it names the parts the map draws;
- `summary` and `role`: one line and two lines, for the root's own panel; Name the
  output, its consumer, and what the consumer gets: "builds the files that searches
  read", not "streams jobs to the engine";
- `words`: the subject's terms that the rest of the note needs, the five most important
  first. The first term is the scope's own output or unit of work, as the code names it
  ("build", "index"). The definition explains it to a newcomer to the domain;
- `title` and `problem`: why the subject exists, in two or three sentences. Say what its
  users need, why the obvious way fails, and what a user sees when it fails. Take the
  case from the repo;
- one to three `principles`. The reader who knows why a rule holds can guess how the
  code follows it, so each principle gives the why before the case:
  - `claim`: how the parts behave and talk: "every hand-off is a table", not "the driver
    writes `last_job_id`";
  - `why`: the constraint that forces the claim, in one or two sentences;
  - `example`: two or three rows, each one real case and what the system does with it.
    A row is an event the reader could find in a log line or a database row:
    `["Job 8812 asks for the March sales report", "The scheduler writes a jobs row. The
    builder picks it up on its next poll."]`;
  - `except`: optional, the case where the claim does not hold;
  - `cost`: what the claim costs;
- for repo or path scope, the `stack`, each item linked to its official docs;
- the `lifecycle` of the data: at most six steps through the root `flow`, in the order the
  data moves, from the input to the consumer of the result. It is required for feature
  scope, and the map's step header needs it for every scope. Each step's `at` names the
  flow shapes it touches, and the viewer lights them as the reader steps. Each root step
  also takes a `detail`, two to four sentences that the panel shows beside the map: who
  starts the stage, what happens to the record, and what the reader would see, with a
  real case. "A customer adds a product. Before Metis writes it, the extension sends it
  to the API", not "the middleware invokes the stream handler". A step says what happens to the data, never which goroutine, batch
  size, or table does it;
- for function scope, the `io`: the inputs, the outputs, and where the result goes;
- the scope's `flow`, with one shape per service, its `node` set to the service's id.
  Every root shape with no tree `node` takes an `about`: one or two sentences on what that
  system is and what it does in the loop. The panel shows it when the reader clicks the
  shape;
- `problem`, `principles`, `words`, and `stack` stay in the note: the Obsidian page holds
  them, and each word gives its terms a tooltip. The viewer's panel does not show them, so
  keep them short.

**Every node below the root** gets:

- a `summary` of one sentence: what the node is for, never what it contains;
- a `role` of one paragraph, at most two lines: why it exists, and what the reader loses
  without it;
- its `links`, from step 4;
- a `flow` when it touches a database, a queue, or an external service, which the tree
  cannot draw;
- a `note` for each entry point. Cut the entry points a newcomer needs no link to;
- `external`, promoted from `_external` once the code confirms the call.

**Every service** also gets:

- a `flow` that draws how its packages work together. Each package the data passes through
  is a shape with `node` set to the package's id, owned or shared. The stores it reads and
  writes are `store` shapes. The services and outside systems it talks to take `node` set
  to the service's id, `node: null`, or `external`. Mark its entry `end: "in"` and its last
  write `end: "out"`. Twelve shapes at most;
- a `lifecycle`: at most six steps through its own flow, written like the feature-scope
  root `lifecycle`. The viewer shows it as the step list of the service's flow;
- for each package that a shape points at, `entry` with the function where that stage
  starts first.

**The flow** shows what the tree cannot: the databases, queues, and outside services as
their own shapes. The viewer draws it with ELK, like the map. Mark each database, queue, or
bucket `store`. Each edge label starts with a word from
[Flow labels](SCHEMA.md#flow-labels). This is the root flow of the harbor example:

```json
{ "nodes": [{ "id": "scheduler", "name": "job-scheduler", "node": "services/job-scheduler", "end": "in" },
            { "id": "pg", "name": "PostgreSQL", "store": true },
            { "id": "builder", "name": "report-builder", "node": "services/report-builder" },
            { "id": "s3", "name": "S3: reports", "store": true, "end": "out" }],
  "edges": [{ "from": "scheduler", "to": "pg", "label": "writes DB: jobs" },
            { "from": "pg", "to": "builder", "label": "reads DB: plans" },
            { "from": "builder", "to": "s3", "label": "async: upload" }] }
```

The root has no shape cap: one shape per service, store, and outside system, never a
package. Twelve shapes at most below it. The root flow draws the outcome: the
input, the subject, what it produces, and who consumes it.

**The root flow reads in to out.** Mark the shape where the data starts `"end": "in"`, and
the shape where the result lands `"end": "out"`. The viewer pins them to the far left and
the far right. `check.py` requires both, and rejects an `in` shape with an incoming edge
or an `out` shape with an outgoing edge. A system that is both (Algolia is the source
index and the destination index) takes two shapes: `Algolia: source index` with `end: in`,
`Algolia: enriched index` with `end: out`. One shape for both puts it mid-graph and hides
the direction. The same holds for a system that the data crosses twice, once on the way in
and once on the way out: name each shape by its role, `Metis: live writes` and
`Metis: write-back`. One shape draws an edge back from the far right to the left, and
that edge tangles the layout. Draw each service once, with its `node`. A system outside the repo gets `node: null`, or
`external` when it is another repo, which the viewer dashes. Draw the databases and queues
as `store`. Merge the stores of one database into one shape. When more parts touch a
node, draw the ones the data passes through. The service flows show the packages.

**Keep the map readable.** The viewer lays the flow out left to right, so the shape order
and the label lengths set its width:

- Keep each edge label to its leading word and a payload of one to three words, about 24
  characters: `grpc: EnrichStream`, `queue: run`, `http: partial update`. A long label
  widens the gap between two columns. The lifecycle steps carry the detail.
- List the shapes in the order the data moves: the inputs, then each path, then the
  scope's services, then the outside calls and the writers, then the destination.
- Draw a response edge (`grpc: merged record`) only between two neighbouring shapes. A
  short loop stays readable; a long one crosses the map.
- Write the root `lifecycle` for every scope, because the map steps through it. With
  several input paths, give each path its own step and name it first: "Live path: ...",
  "Reindex path: ...".

**Fan-out.** More than 25 nodes to write: write the root and `words` first. Then spawn
one subagent per top-level child. Pass each one:

- the path to the skeleton, and its subtree's id. The top-level children are the services,
  the `shared` group, and the leftover directories;
- the root `flow`, so each service flow reuses its shape names and ids;
- `words`, the root's `principles`, and `STYLE.md`;
- the two rules above: keep the subject's words, and take the examples from the repo.

Merge the subtrees back into the one note.

## 6. Review, check, install

1. `python3 check.py "$work/<slug>.json" --prose > "$work/prose.md"`. Run the review
   passes of `STYLE.md` on `prose.md`. The medium is a browser. Each `##` heading names
   the node that a paragraph belongs to. Tell both passes to keep each term of `words`
   as written. Copy each edit back into the note.
2. `python3 check.py "$work/<slug>.json" --install`. Fix each line it prints, and run it
   again until it prints `ok`.
3. Open the note:

   ```bash
   open "file://$HOME/.claude/.onboard/index.html#note=<slug>"
   ```

Then stop. To share one note, the reader clicks **Download as one file** in the viewer.
The viewer's design and its decisions live in `~/.claude/.onboard/CLAUDE.md`.

A follow-up question about one part gets its answer in the conversation. Regenerate the
note only when the user asks.
