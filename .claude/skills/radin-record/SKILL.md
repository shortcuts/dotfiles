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

This skill turns feedback, bugs, follow-ups, and ideas from the live session into structured backlog entries that survive past the conversation. It captures what a human said, not what a diff revealed. `radin-review` logs code-review findings instead. `radin-plan` and `radin-execute` consume the backlog afterward.

All backlog writes go through the shared CLI at
`$HOME/.claude/.radin/lib/radin-backlog.sh`. It resolves the per-project
namespace (`<repo-root>/.claude/.radin/backlog/`, a JSONL index plus one
markdown file per task) and appends entries deterministically. Never
hand-edit the index or a task file. Never compute paths yourself.

## Step 1: Decide what to log

The user's instruction after `/radin-record` decides the scope:

- **Specific** (names a particular thing — "add the auth timeout bug",
  "log the caching idea we discussed"): log exactly that item. Don't dig
  for other candidates the user didn't point at.
- **Generic** ("add the findings", "log what we discussed", bare
  `/radin-record` with no argument): scan the whole session so far for
  anything a reasonable person calls a bug, follow-up, idea, or feedback.
  Include things the user stated outright, and things clearly surfaced as a
  "we should probably..." aside mid-task, even if nobody wrote them down.
  Each distinct item becomes its own entry.

Either way, stay faithful to what was actually said. This is a capture
tool, not brainstorming. Don't invent items the conversation didn't raise.
Don't editorialize on top of what the user said.

A single thing raised in conversation can be broad enough to be two or more
sequential pieces of work. For example, "add rate limiting on top of new
auth middleware" needs the middleware to exist first. Log each piece as its
own entry. Don't let one entry hide two tasks. Splitting is about the work's
shape, not the user's phrasing — a single sentence can still name two
sequential tasks.

When it is genuinely unclear whether something belongs in scope, or whether
it's one entry or several, don't guess. Invoke `/grilling` on the ambiguous
point and let the user settle it before logging anything. This applies
mid-scan for generic asks too: surfacing a question beats silently deciding
a boundary the user never stated.

That's a different case from an item that's *real but not yet sharp* — the
scope/split boundary is clear, but the shape of the work itself isn't (a
"we should figure out caching at some point" aside with no concrete
approach yet). Don't grill the user just to force detail that doesn't exist
yet, and don't invent detail to fill the gap either. Log it as a stub: short
title, a body that says plainly it's not yet specified and what's known so
far, no invented approach or scope. `radin-plan` sharpens it into a real
plan once someone picks it up — grilling at that point has the concrete
question to grill about, which right now it doesn't.

## Step 1b: Note any skill invoked for this item

If the request that raised this item explicitly invoked a skill (e.g. the
user wrote `/radin-record /frontend-design make the accent color...`, or a
skill ran earlier in the session and this item continues that work), record
it as a standing instruction, not a note. The user chose that skill for this
task — record it even if it looks redundant, wrong-fit, or skippable to you.
Nobody downstream re-judges it either: not `radin-record` now, not
`radin-execute`'s sub-agent later. `radin-execute`'s sub-agent has no
visibility into this conversation. Without this line it re-implements the
item from bare description text and never invokes the skill the user asked
for.

## Step 2: Classify each item and note dependencies

Before writing each item, ask: does landing it require another item in the
same batch (or a task already in the backlog) to land first? Use the same
signal `radin-execute` and `radin-plan` already use: both touch the same
file, function, or behavior, or the item explicitly builds on the other. If
so, the dependent entry's description must name the other entry's exact
title and say why it comes first — e.g. "Depends on the '<other title>'
entry — needs the endpoint it adds before this can call it." Use plain
prose, not a special tag. `radin-execute`'s prioritization step reads entry
bodies for exactly this signal when ordering the backlog. Leave it out of
the text and it stays invisible to that step.

Classify each item into exactly one category (same vocabulary as
conventional-commit type):

- **feat** — new capability or behavior asked for (idea, "what if we...",
  feature request).
- **fix** — something broken or behaving incorrectly.
- **chore** — maintenance-shaped: follow-up/TODO not new feature or bug
  (docs, tooling, cleanup, "we should probably go back and...").
- **refactor** — feedback existing approach/structure should change
  without changing behavior (e.g. "I don't love how this got structured").

An item could plausibly fit two categories — pick the closer one and move
on. Don't stall on classification. A slightly-off category costs nothing,
since `radin-execute` and `radin-plan` read the description regardless of
category.

## Step 3: Confirm scope with user, then append via the CLI

**Generic ask** (Step 1 scanned the whole session): before writing
anything, show the user the finalized item list — title and category per
item — and confirm it's the right set before running the CLI. Scanning
free-form conversation for "anything a reasonable person calls a bug/idea"
is a guess about what the user actually wants captured. Don't let that guess
become a backlog entry unchecked. **Specific ask** (user named the exact
item): skip confirmation and log directly — nothing ambiguous to check.

For each confirmed, classified item:

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" add <category> "<short title>" [--skill <skill-name>] <<'EOF'
<as exhaustive a description as the situation warrants: what was being
discussed/worked on when this came up, the item itself close to how the
user stated or clearly implied it, and why it matters if that's not
already obvious. radin-execute/radin-plan will act on this entry with
no other session context, so don't compress it down to one line.>
EOF
```

If Step 1b found a skill, pass it as `--skill <skill-name>` (repeatable) —
the CLI appends the canonical `**Skill:** Invoke <skill-name> to tackle
this task.` line to the body itself, worded as an instruction
`radin-execute` follows verbatim. Omit the flag entirely if no skill
applies. Never write the `**Skill:**` line by hand.

The CLI handles file creation, section ordering, appending, and the skill
line. You only supply the category, title, body, and any `--skill` flags.

Always append. Don't scan the backlog for near-duplicates. Don't try to
merge with an existing entry — let `radin-execute`, `radin-plan`, or a
human dedupe later. A false-positive merge silently drops something the
user cared about, which is worse than an occasional repeated entry.

## Step 4: Report back

Tell user:

- How many entries were logged, with titles and categories.
- The path to the backlog file (the CLI prints it on each `add`).
- If nothing in scope (Step 1) actually rose to the level of a loggable
  item, say so plainly — don't pad the file with a vague entry just to
  prove the skill ran.
