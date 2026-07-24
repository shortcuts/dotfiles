---
name: radin-record
description: |
  Log feedback, bugs, follow-ups, or ideas raised mid-session as structured
  BACKLOG.md entries, so they survive past the conversation. Use for
  /radin-record, "log this to BACKLOG.md", "add as follow-up/bug/idea",
  "record what we just found", "note this for later", "add findings to
  backlog". Triggers even on vague asks ("add the findings") — scan the
  whole session, not just the literal text.
---
# Record to Backlog

Turn feedback, bugs, follow-ups, or ideas raised during a live session into
structured entries in `BACKLOG.md`, so they survive past the conversation
that surfaced them. This is the capture step for everything that isn't a
code-review finding — things a human said, not things a diff revealed.
`radin-review` logs code-review findings instead. `radin-plan` and
`radin-execute` consume the backlog afterward.

## Step 1: Resolve project namespace, locate BACKLOG_FILE

All radin state for a project lives inside that project's repo, in
`.claude/.radin/` at the repo root (example: repo `/Users/x/proj` →
`/Users/x/proj/.claude/.radin/BACKLOG.md`). Do not compute this path
yourself — run the shared namespace-resolution script and read `REPO_ROOT`,
`NAMESPACE_DIR`, `BACKLOG_FILE` from its output:

```bash
bash "$HOME/.claude/radin-lib/radin-namespace.sh"
```

Re-run this line in any later Bash call before using these variables.

## Step 2: Decide what to log

The user's instruction after `/radin-record` decides scope:

- **Specific** (names a particular thing — "add the auth timeout bug",
  "log the caching idea we discussed"): log exactly that item. Don't go
  digging for other candidates the user didn't point at.
- **Generic** ("add the findings", "log what we discussed", bare
  `/radin-record` with no argument): scan the whole session so far for
  anything a reasonable person would call a bug, follow-up, idea, or piece
  of feedback. Include things the user stated outright, and things that
  were clearly surfaced as a "we should probably..." aside mid-task, even
  if nobody stopped to write them down. Each distinct item becomes its own
  entry.

Either way, stay faithful to what was actually said. This is a capture tool,
not a brainstorming one — don't invent items the conversation didn't raise,
and don't editorialize on top of what the user said.

## Step 3: Classify each item

`BACKLOG_FILE` is organized into top-level semver-style category sections —
`## feat`, `## fix`, `## chore`, `## refactor` — same vocabulary as a
conventional-commit type. Classify each item into exactly one:

- **feat** — a new capability or behavior is being asked for (an idea, a
  "what if we...", a feature request).
- **fix** — something is broken or behaving incorrectly.
- **chore** — maintenance-shaped: a follow-up/TODO that isn't a new feature
  or a bug (docs, tooling, cleanup, "we should probably go back and...").
- **refactor** — feedback that an existing approach/structure should change
  without changing behavior (e.g. "I don't love how this got structured").

When an item could plausibly fit two categories, pick the closer one and
move on — don't stall on classification; a slightly-off category costs
nothing since `radin-execute`/`radin-plan` read the description
regardless of category.

## Step 4: Append entries to BACKLOG.md

Create `$BACKLOG_FILE` with a `# Backlog` heading first if it doesn't exist
yet. For each classified item, find (or create) its category section — in
canonical order feat → fix → chore → refactor relative to whichever
sections already exist — then append an entry under it in this exact shape:

```
### <short title>
<as exhaustive a description as the situation warrants: what was being
discussed/worked on when this came up, the item itself close to how the
user stated or clearly implied it, and why it matters if that's not
already obvious. radin-execute/radin-plan will act on this entry with
no other session context, so don't compress it down to one line.>
```

Always append — don't scan `BACKLOG_FILE` for near-duplicates or try to merge
with an existing entry; let `radin-execute`/`radin-plan` or a human
dedupe later, since a false-positive merge silently drops something the
user cared about, which is worse than an occasional repeated entry.

## Step 5: Report back

Tell the user:

- How many entries were logged, with their titles and categories.
- Path to `$BACKLOG_FILE`.
- If nothing in scope (Step 2) actually rose to the level of a loggable
  item, say so plainly — don't pad the file with a vague entry just to prove
  the skill ran.
