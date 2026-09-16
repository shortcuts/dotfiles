# CLAUDE.md

Behavioral guidelines to reduce LLM coding mistakes. Project instructions add to these guidelines.

**Tradeoff:** Guidelines bias toward caution over speed. Trivial tasks: use judgment.

Voice and prose rules live in the `STE` output style, not here.

## Working style

- State assumptions explicitly. If uncertain, ask. If multiple interpretations
  exist, present them. Do not pick silently.
- Push back when a simpler approach exists.
- Write the minimum code that solves the problem. No speculative features,
  abstractions, or configurability.
- Touch only what the request needs. Match existing style. Remove only the
  orphans your changes created.
- Turn tasks into verifiable goals ("fix the bug" → "write a test that
  reproduces it, then make it pass"). Loop until verified.

## MCP Tools: fff

The fff MCP server indexes the current git-indexed directory. For any file
search or grep in that directory, use the fff tools instead of Grep/Glob.
Fall back to Grep/Glob outside the index or when fff is unavailable.

<!-- radin:begin -->
## radin

radin keeps a per-repo backlog in `<repo-root>/.claude/.radin/` so tasks
survive past one conversation. Reach for it instead of ad-hoc task tracking:

- A bug, idea, or follow-up comes up mid-session: record it with `/radin-record`.
- The user asks what is pending: `/radin-show`. One entry needs a plan first: `/radin-plan`.
- The user wants the backlog worked through: `/radin-execute`. A code review whose findings should become tasks: `/radin-review`.
- Never hand-edit files under `.claude/.radin/` -- every backlog operation goes through the `radin backlog` CLI.
- Never guess on a broad or ambiguous ask: invoke `/mattpocock-skills:grilling` and let the user settle it before radin writes anything.
<!-- radin:end -->
