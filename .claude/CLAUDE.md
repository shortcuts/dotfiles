# CLAUDE.md

Project instructions add to these guidelines.

## Working style

- Multiple readings of the request exist: present them. Never pick one silently.
- Touch only what the request needs. Match existing style. Remove only the orphans your
  changes created.
- Turn the task into a loop you can watch go **red**, then green. "Fix the bug" becomes
  "write the test that reproduces it, then make it pass." Loop until it is green.

## MCP Tools: fff

The fff MCP server indexes the current git-indexed directory. Search and grep inside that
directory with the fff tools. Fall back to Grep/Glob outside the index, or when fff is
unavailable.


<!-- codebase-memory-mcp MCP tools -->
## MCP Tools: codebase-memory-mcp

This machine has the codebase-memory-mcp knowledge graph. For a structural
question (where a symbol is defined, who calls it, what a change affects), use
its MCP tools before Grep/Glob/Read -- they answer in fewer tokens than file
scanning. If the tools are deferred, load them with `ToolSearch` first:

- `search_graph` to find a symbol: `query` for BM25, `semantic_query` when you know the idea but not the name; `search_code` for text inside indexed files
- `get_file_outline` for the symbols in one file, before reading all of it
- `check_index_coverage` before trusting an empty result for a path
- `trace_path` for callers and callees, before changing anything shared
- `detect_changes` to map the working-tree diff to affected symbols and blast radius
- `get_code_snippet` to read one function, `get_architecture` for an unfamiliar area
- `query_graph` for Cypher-shaped questions, after `get_graph_schema`
- `index_repository` when `list_projects` does not list this repo yet, `index_status` while it runs; the background watcher keeps it current after that

A graph hit is a pointer: read the file before editing it, and never conclude
something does not exist from an empty result. Fall back to file scanning when
the graph does not cover what you need. The MCP tools document their own
parameters and use.

<!-- radin:begin -->
## radin

radin keeps a per-repo backlog in `<repo-root>/.claude/.radin/` so tasks
survive past one conversation. Reach for it instead of ad-hoc task tracking:

- A bug, idea, or follow-up comes up mid-session: record it with `/radin-record`.
- The user asks what is pending: run `radin backlog show` and print its output. One entry needs a plan first: `/radin-plan`.
- The user wants the backlog worked through: `/radin-batch` (it asks whether to plan each task first), or `/radin-do <prompt>` for one ad-hoc task. A code review whose findings should become tasks: `/radin-review`.
- Never hand-edit files under `.claude/.radin/` -- every backlog operation goes through the `radin backlog` CLI.
- Never guess on a broad or ambiguous ask: invoke `/mattpocock-skills:grilling` and let the user settle it before radin writes anything.
<!-- radin:end -->
