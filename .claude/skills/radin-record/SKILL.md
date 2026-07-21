---
name: radin-record
description: |
  Capture feedback, bugs, follow-ups, or ideas that surface mid-session and log
  them as structured entries in the current project's ISSUES.md — so nothing
  a user raises in conversation gets lost once the session ends. Use whenever
  the user invokes /radin-record, or asks to "log this to ISSUES.md", "add
  this as a follow-up/bug/idea", "record what we just found", "note this for
  later", "add the findings to the backlog", or otherwise wants something said
  in the conversation turned into a durable backlog entry instead of staying
  buried in chat history. Trigger even when the user's instruction is vague
  ("add the findings") — that means scan the whole session, not just the
  literal argument text.
---
# Record to Issues

Turn feedback, bugs, follow-ups, or ideas raised during a live session into
structured entries in `ISSUES.md`, so they survive past the conversation
that surfaced them. Companion to `radin-review` (which logs code-review
findings) and `radin-plan`/`radin-orchestrator` (which consume the backlog
afterward) — this skill is the capture step for everything that isn't a
code-review finding: things a human said, not things a diff revealed.

## Step 1: Resolve project namespace, locate ISSUES_FILE

Radin never writes backlog/state files into the target repo. Resolve the
canonical, per-project namespace under `~/.claude/.radin/` first:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if command -v md5 >/dev/null 2>&1; then
  HASH_CMD="md5"
else
  HASH_CMD="md5sum"
fi
if [ -n "$REPO_ROOT" ]; then
  SLUG="$(basename "$REPO_ROOT")-$(printf '%s' "$REPO_ROOT" | $HASH_CMD | cut -c1-8)"
else
  SLUG="no-repo-$(printf '%s' "$PWD" | $HASH_CMD | cut -c1-8)"
fi
NAMESPACE_DIR="$HOME/.claude/.radin/projects/$SLUG"
mkdir -p "$NAMESPACE_DIR/state" "$NAMESPACE_DIR/plans" "$NAMESPACE_DIR/reviews"
ISSUES_FILE="$NAMESPACE_DIR/ISSUES.md"

REGISTRY="$HOME/.claude/.radin/registry.json"
[ -f "$REGISTRY" ] || echo '{}' > "$REGISTRY"
TMP="$REGISTRY.tmp.$$"   # same dir as $REGISTRY -- required for atomic mv
if command -v jq >/dev/null 2>&1; then
  jq --arg k "$SLUG" --arg p "$REPO_ROOT" --arg t "$(date -u +%FT%TZ)" \
     '.[$k] = {path: $p, updated_at: $t}' "$REGISTRY" > "$TMP" && mv "$TMP" "$REGISTRY"
elif command -v python3 >/dev/null 2>&1; then
  python3 -c "
import json
r = json.load(open('$REGISTRY'))
r['$SLUG'] = {'path': '$REPO_ROOT', 'updated_at': __import__('datetime').datetime.utcnow().isoformat()+'Z'}
json.dump(r, open('$TMP', 'w'), indent=2)
" && mv "$TMP" "$REGISTRY"
else
  echo "note: no jq/python3 found, skipping registry.json index update (non-critical)" >&2
fi
```

`registry.json` is a best-effort index — a skipped upsert never blocks
`$ISSUES_FILE` from being written correctly.

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
