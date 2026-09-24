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

<!-- radin:begin -->
## radin

radin keeps a per-repo backlog in `<repo-root>/.claude/.radin/` so tasks
survive past one conversation. Reach for it instead of ad-hoc task tracking:

- A bug, idea, or follow-up comes up mid-session: record it with `/radin-record`.
- The user asks what is pending: `/radin-show`. One entry needs a plan first: `/radin-plan`.
- The user wants the backlog worked through: `/radin-execute`, or `/radin-implement` to skip the planning pass. A code review whose findings should become tasks: `/radin-review`.
- Never hand-edit files under `.claude/.radin/` -- every backlog operation goes through the `radin backlog` CLI.
- Never guess on a broad or ambiguous ask: invoke `/mattpocock-skills:grilling` and let the user settle it before radin writes anything.
<!-- radin:end -->
