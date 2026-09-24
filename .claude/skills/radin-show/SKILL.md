---
name: radin-show
description: |
  Print the current project's backlog to the terminal. Use for
  /radin-show, "show me the backlog", "what's in the backlog".
---
# Show Backlog

Print the current project's backlog as markdown.

```bash
radin backlog show
```

Pass a category when the user narrows the scope ("show me fix items"):
`radin backlog show fix`. Otherwise pass none.

It exits 1 with "no backlog" when the project has none. Tell the user that,
point them at `radin-record` or `radin-review` to start one, and create no
file.

Print the output as-is: the CLI already orders and formats it.
