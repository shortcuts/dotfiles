---
name: radin-record
description: |
  Log feedback, bugs, follow-ups, or ideas raised mid-session as structured
  backlog entries, so they survive past the conversation. Use for
  /radin-record, "log this to the backlog", "add as follow-up/bug/idea",
  "record what we just found", "note this for later", "add findings to
  backlog". Triggers even on vague asks ("add the findings") — scan the
  whole session, not just the literal text.
---
# Record to Backlog

Feedback, bugs, follow-ups, ideas from live session → structured backlog entries. Survive past conversation that raised them. Capture step for anything not code-review finding — human said, not diff revealed. `radin-review` logs code-review findings instead. `radin-plan` and `radin-execute` consume backlog after.

All backlog writes go through shared CLI at
`$HOME/.claude/.radin/lib/radin-backlog.sh`. Resolves per-project
namespace (`<repo-root>/.claude/.radin/backlog/`, JSONL index plus one
markdown file per task), appends entries deterministic. Never
hand-edit index or task file, never compute paths yourself.

## Step 1: Decide what to log

User's instruction after `/radin-record` decides scope:

- **Specific** (names particular thing — "add the auth timeout bug",
  "log the caching idea we discussed"): log exactly that item. Don't dig
  for other candidates user didn't point at.
- **Generic** ("add the findings", "log what we discussed", bare
  `/radin-record` with no argument): scan whole session so far for
  anything reasonable person calls bug, follow-up, idea, feedback. Include
  things user stated outright, and things clearly surfaced as "we should
  probably..." aside mid-task, even if nobody wrote down. Each distinct
  item becomes own entry.

Either way, stay faithful to what actually said. Capture tool, not
brainstorming — don't invent items conversation didn't raise, don't
editorialize on top of what user said.

Single thing raised in conversation can be broad enough it's really
two or more sequential pieces of work — e.g. "add rate limiting on top of
new auth middleware" needs middleware exist first. Log each piece own
entry, don't let one entry hide two tasks. Splitting about work's shape,
not user's phrasing — single sentence can still name two sequential tasks.

## Step 2: Classify each item and note dependencies

Before writing each item, ask: landing it require another item in same
batch (or task already in backlog) land first? Use same signal
`radin-execute` and `radin-plan` already use: same file, function, or
behavior touched by both, or item explicitly builds on other. If so,
dependent entry's description must name other entry's exact title, say
why comes first — e.g. "Depends on the '<other title>' entry — needs
the endpoint it adds before this can call it." Plain prose, not special
tag. `radin-execute`'s prioritization step reads entry bodies for exactly
this signal when ordering backlog. Leave out of text → invisible to it
later.

Classify each item into exactly one category (same vocabulary as
conventional-commit type):

- **feat** — new capability or behavior asked for (idea, "what if we...",
  feature request).
- **fix** — something broken or behaving incorrectly.
- **chore** — maintenance-shaped: follow-up/TODO not new feature or bug
  (docs, tooling, cleanup, "we should probably go back and...").
- **refactor** — feedback existing approach/structure should change
  without changing behavior (e.g. "I don't love how this got structured").

Item could plausibly fit two categories → pick closer one, move on. Don't
stall on classification; slightly-off category costs nothing since
`radin-execute`/`radin-plan` read description regardless of category.

## Step 3: Append entries via the CLI

For each classified item:

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" add <category> "<short title>" <<'EOF'
<as exhaustive a description as the situation warrants: what was being
discussed/worked on when this came up, the item itself close to how the
user stated or clearly implied it, and why it matters if that's not
already obvious. radin-execute/radin-plan will act on this entry with
no other session context, so don't compress it down to one line.>
EOF
```

CLI handles file creation, section ordering, appending — you only supply
category, title, body.

Always append. Don't scan backlog for near-duplicates, don't try merge
with existing entry — let `radin-execute`/`radin-plan` or human dedupe
later. False-positive merge silently drops something user cared about,
worse than occasional repeated entry.

## Step 4: Report back

Tell user:

- How many entries logged, with titles and categories.
- Path to backlog file (CLI prints it on each `add`).
- If nothing in scope (Step 1) actually rose to level of loggable item,
  say so plainly — don't pad file with vague entry just to prove skill ran.