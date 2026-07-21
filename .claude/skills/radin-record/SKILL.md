---
name: radin-record
description: |
  Log feedback, bugs, follow-ups, or ideas raised mid-session as structured
  ISSUES.md entries, so they survive past the conversation. Use for
  /radin-record, "log this to ISSUES.md", "add as follow-up/bug/idea",
  "record what we just found", "note this for later", "add findings to
  backlog". Triggers even on vague asks ("add the findings") — scan the
  whole session, not just the literal text.
---
# Record to Issues

Turn feedback, bugs, follow-ups, or ideas raised during a live session into
structured entries in `ISSUES.md`, so they survive past the conversation
that surfaced them. Companion to `radin-review` (which logs code-review
findings) and `radin-plan`/`radin-orchestrator` (which consume the backlog
afterward) — this skill is the capture step for everything that isn't a
code-review finding: things a human said, not things a diff revealed.

## Step 1: Resolve project namespace, locate ISSUES_FILE

Radin never writes backlog/state files into the target repo. Run the shared
namespace-resolution script — the single source of truth for this logic,
shared by every radin agent/skill — and read `REPO_ROOT`, `NAMESPACE_DIR`, and
`ISSUES_FILE` from its output:

```bash
bash "$HOME/.claude/radin-lib/radin-namespace.sh"
```

This creates `$NAMESPACE_DIR/state`, `$NAMESPACE_DIR/plans`, and
`$NAMESPACE_DIR/reviews`, and best-effort upserts `registry.json` (a skipped
upsert never blocks `$ISSUES_FILE` from being written correctly). Use the
printed `REPO_ROOT` / `NAMESPACE_DIR` / `ISSUES_FILE` values for the rest of
this session.

## Step 2: Decide what to log

The user's instruction after `/radin-record` decides scope:

- **Specific** (names a particular thing — "add the auth timeout bug",
  "log the caching idea we discussed"): log exactly that item. Don't go
  digging for other candidates the user didn't point at.
- **Generic** ("add the findings", "log what we discussed", bare
  `/radin-record` with no argument): scan the whole session so far for
  anything a reasonable person would call a bug, follow-up, idea, or piece
  of feedback — things the user stated outright, and things that were
  clearly surfaced as a "we should probably..." aside mid-task, even if
  nobody stopped to write it down. Each distinct item becomes its own entry.

Either way, stay faithful to what was actually said. This is a capture tool,
not a brainstorming one — don't invent items the conversation didn't raise,
and don't editorialize on top of what the user said.

## Step 3: Classify each item

`ISSUES_FILE` is organized into top-level semver-style category sections —
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
nothing since `radin-orchestrator`/`radin-plan` read the description
regardless of category.

## Step 4: Append entries to ISSUES.md

Create `$ISSUES_FILE` with a `# Issues` heading first if it doesn't exist
yet. For each classified item, find (or create) its category section — in
canonical order feat → fix → chore → refactor relative to whichever
sections already exist — then append an entry under it in this exact shape:

```
### <short title>
<as exhaustive a description as the situation warrants: what was being
discussed/worked on when this came up, the item itself close to how the
user stated or clearly implied it, and why it matters if that's not
already obvious. radin-orchestrator/radin-plan will act on this entry with
no other session context, so don't compress it down to one line.>
```

Always append — don't scan `ISSUES_FILE` for near-duplicates or try to merge
with an existing entry; let `radin-orchestrator`/`radin-plan` or a human
dedupe later, since a false-positive merge silently drops something the
user cared about, which is worse than an occasional repeated entry.

## Step 5: Report back

Tell the user:

- How many entries were logged, with their titles and categories.
- Path to `$ISSUES_FILE`.
- If nothing in scope (Step 2) actually rose to the level of a loggable
  item, say so plainly — don't pad the file with a vague entry just to prove
  the skill ran.
