---
name: onboard
description: Onboard an engineer on a repository, directory, feature, or function with one zoomable HTML map - the stack, each package's role, how the data flows, and links to the code.
disable-model-invocation: true
argument-hint: "Nothing (whole repo), a path, a function name, or a feature in words"
---

Write one **note**: the data for a zoomable map of the subject. The viewer at
`~/.claude/.onboard/index.html` draws it as nested boxes on one canvas. The first view is
the scope. Each click unfolds one level in place, from the repository to its directories
to its packages.

**The reader** is an engineer new to the codebase. They want the mental map: what each
part is for, how the parts talk, and where the data goes. Leave out implementation
detail: error paths, early returns, retries, logging, function parameters, column names,
and environment variables never reach the prose. The entry points carry the code names.

**The split.** `skeleton.py` does the deterministic work:
- it reindexes the graph and pins the commit;
- it builds the tree from git and finds each node's entry points, with line ranges;
- it adds graph facts as `_` hint keys.

You write every field it leaves as `TODO`: the prose, the flows, and the judgment calls.
`check.py` rejects any `TODO` left over.

**The note is done when:**

- The reader can say what the scope produces, who uses it, and what they get from it.
- The reader can draw the scope's main parts and the arrows between them from memory.
- For each package, the reader can say in one sentence why it exists.
- Each arrow says how the data moves: a plain call, async, HTTP, gRPC, a queue, or the DB.
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

**Feature scope needs the packages first.** Find the feature's code with
`search_graph` (`query`, and `semantic_query` with two to four phrasings), `search_code`
for its literal names, and `Route` nodes for its endpoints. Semantic search misses on
some repos. Then grep the SQL, protobuf, and config files for the feature's names. Pass
the directories to `--packages` in the order the data visits them.

## 3. Shape the tree

The skeleton holds every tracked directory down to the package leaf. Read its hints, then
edit the tree:

| Hint | What to do |
|---|---|
| `_group` | More than 12 children: collect them into `group` nodes by what they do, "Search services", "Ingestion" |
| `_files` | The directory's own files. Add a `file` leaf only for a file that carries a decision (`install.sh`, a whitelist `.gitignore`) |
| `_leaf_reason` | Why the branch stops. Turn a `package` into a `dir` with children only when its parts serve different readers |
| `_blind` | The graph holds no file here (a language without a parser, or an excluded path). Read the source with `git show <sha>:<path>` |
| `_side` | Function scope: caller, callee, or own package. Keep the order: callers, own package, callees |

Remove the nodes a newcomer does not need, such as vendored code and generated code.
Keep `path` and `id` as the skeleton wrote them.

## 4. Confirm the links

The viewer draws the tree and, over it, the links between nodes. The links are the part
that shows how the system talks, so a missing link is a wrong map. Three hints lead you
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

**Done when:** each node the data passes through has at least one link in or out, and a
reader can follow the data from its entry to its last write without leaving the tree.

## 5. Write the content

Read [`SCHEMA.md`](SCHEMA.md) for each field. Follow
[`../_shared/STYLE.md`](../_shared/STYLE.md). The word list is `words`.

**The root** tells the outcome, not the mechanism. The reader first needs what the scope
produces and who uses it. The children carry how it works.

- `summary` and `role`: one line and two lines. The panel opens with them. Name the
  output, its consumer, and what the consumer gets: "builds the files that searches
  read", not "streams jobs to the engine";
- `words`: the terms the rest of the note needs, the five most important first. The
  first term is the scope's own output or unit of work ("build", "index"), in words a
  newcomer to the domain understands;
- `title` and `problem`: what breaks without the subject, as a scene from its domain, in
  two or three sentences. The scene ends at what a user sees;
- one to three `principles`, each with its mammoth of two or three rows. A principle says
  how the system behaves and how its parts talk: "every hand-off is a table", not "the
  driver writes `last_job_id`";
- for repo or path scope, the `stack`, each item linked to its official docs;
- for feature scope, the `lifecycle` of the data: at most six steps through the root
  `flow`, in the order the data moves, from the input to the consumer of the result.
  Each step's `at` names the flow shapes it touches, and the viewer lights them as the
  reader steps. A step says what happens to the data, never which goroutine, batch
  size, or table does it;
- for function scope, the `io`: the inputs, the outputs, and where the result goes;
- the scope's `flow`.

**Every node below the root** gets:

- a `summary` of one sentence: what the node is for, never what it contains;
- a `role` of one paragraph, at most two lines: why it exists, and what the reader loses
  without it;
- its `links`, from step 4;
- a `flow` when it touches a database, a queue, or an external service, which the tree
  cannot draw;
- a `note` for each entry point. Cut the entry points a newcomer needs no link to;
- `external`, promoted from `_external` once the code confirms the call.

**The flow** shows what the tree cannot: the databases, queues, and outside services as
their own shapes. The viewer draws it with ELK, like the map. Mark each database, queue, or
bucket `store`. Each edge label starts with a word from
[Flow labels](SCHEMA.md#flow-labels):

```json
{ "nodes": [{ "id": "scheduler", "name": "job-scheduler" },
            { "id": "pg", "name": "PostgreSQL", "store": true },
            { "id": "builder", "name": "report-builder" },
            { "id": "s3", "name": "S3: reports", "store": true }],
  "edges": [{ "from": "scheduler", "to": "pg", "label": "writes DB: jobs" },
            { "from": "pg", "to": "builder", "label": "reads DB: plans" },
            { "from": "builder", "to": "s3", "label": "async: upload" }] }
```

Seven shapes at most on the root, twelve below it. The root flow draws the outcome: the
input, the subject, what it produces, and who consumes it. Merge the stores of one
database into one shape, and leave internal helpers to the child that owns them. When
more parts touch a node, draw the ones the data passes through. The node's links still
show the rest.

**Fan-out.** More than 25 nodes to write: write the root and `words` first. Then spawn
one subagent per top-level child. Pass each one:

- the path to the skeleton, and its subtree's id;
- `words`, the root's `principles`, and `STYLE.md`;
- the order to add no new term without a definition.

Merge the subtrees back into the one note.

## 6. Review, check, install

1. `python3 check.py "$work/<slug>.json" --prose > "$work/prose.md"`. Run the review
   passes of `STYLE.md` on `prose.md`. The medium is a browser. Each `##` heading names
   the node that a paragraph belongs to. Copy each edit back into the note.
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
