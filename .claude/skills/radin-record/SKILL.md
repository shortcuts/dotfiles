---
name: radin-record
description: |
  Log feedback, bugs, follow-ups, or ideas raised mid-session as structured
  backlog entries, so they survive past the conversation. Use for
  /radin-record, "log this to the backlog", "add as follow-up/bug/idea",
  "record what we just found", "note this for later", "add findings to
  backlog". Triggers even on vague asks ("add the findings"): scan the
  whole session, not just the literal text.
---
# Record to Backlog

Turn feedback, bugs, follow-ups, and ideas from the live session into
backlog entries that survive past the conversation. This captures what a
human said. `radin-review` logs what a diff revealed, and `radin-plan` and
`radin-execute` consume the backlog afterward.

All writes go through the shared CLI at
`$HOME/.claude/.radin/lib/radin-backlog.sh`. It owns the index's schema and
resolves the per-project namespace, so never hand-edit a backlog file or
compute its path yourself.

## Step 1: Decide what to log

The instruction after `/radin-record` sets the scope:

- **Specific** ("add the auth timeout bug"): log exactly that item, nothing
  else.
- **Generic** ("add the findings", bare `/radin-record`): scan the whole
  session for anything a reasonable person calls a bug, follow-up, idea, or
  feedback, including "we should probably..." asides nobody wrote down.
  Each distinct item becomes its own entry.

Stay faithful to what was actually said. This is a capture tool: log only
what the conversation raised, worded close to how it was raised.

One raised thing can be several sequential pieces of work ("add rate
limiting on top of new auth middleware" needs the middleware first). Log
each piece as its own entry, split by the work's shape rather than the user's
phrasing.

When scope or split is genuinely unclear, invoke `/grilling` on that point
and let the user settle it before logging, mid-scan too. Distinguish that
from an item that is *real but not yet sharp* (clear boundary, fuzzy work,
as in "figure out caching at some point"): log it as a stub with a short
title and a body saying plainly it's unspecified and what's known so far.
`radin-plan`
sharpens it when someone picks it up; grilling now has nothing concrete to
grill about.

## Step 2: Chart each item's open decisions (MANDATORY GATE)

The user is at the keyboard now, and `radin-execute` may later run with
nobody behind it. This is the only point in the whole flow where that's true,
so settle judgment calls here and execution never has to.

For each item, list what an executor with zero session context would have
to decide that the conversation didn't settle. Tag each question:

- **Fact**: checkable against the repo, docs, or an API. Never ask the
  user for these. Note each in the entry body as an open fact to verify.
  `radin-execute` resolves facts AFK by dispatching its own read-only
  fact-finding sub-agent.
- **Decision**: a judgment call only the user can make (tradeoff, scope
  boundary, behavior choice). Invoke `/grilling` on these NOW, before moving
  to the next item, one question at a time. Do not batch decisions across
  items into a single end-of-scan question, and do not summarize the
  decision yourself and ask the user to confirm your summary. `/grilling`
  asks the actual question. Keep every settled answer for Step 5's body.

One test decides whether an item may skip this step: what would an executor
with no session context have to guess to land it without asking anyone? Name
even one plausible guess (a threshold, a naming choice, keep-vs-remove, which
of two reasonable approaches) and it is a Decision, so grill it. The only
pass condition is "there is no second reasonable way to do this". An item
that clears the test skips the step, so don't manufacture questions for it. A
stub from Step 1 also skips: it is one deliberately deferred whole, not an
item with grillable edges.

If the user defers a question or stops answering, record the question itself
as an open decision in the entry body, options and your recommendation
included, so `radin-execute` blocks on it explicitly instead of guessing.

## Step 3: Note any skill invoked for this item

If the request that raised the item explicitly invoked a skill (e.g.
`/radin-record /frontend-design make the accent color...`, or a skill ran
earlier and the item continues that work), record it as a standing
instruction, even if it looks redundant or wrong-fit to you. Nobody
downstream re-judges it, and `radin-execute`'s sub-agent has no visibility
into this conversation: without the line it re-implements from bare text
and never invokes the skill the user chose.

`/radin-record /other-skill <...>` means "record an instruction to run
`/other-skill` later", and never run `/other-skill` now. Treat `/other-skill
<...>` as the text to log: go to Step 1 with it as the item, log with
`--skill other-skill`, and stop. `radin-execute` invokes the skill later,
against the task's file. Running it now would log the item as already
resolved, which is exactly what this form exists to avoid.

## Step 4: Classify each item and note dependencies

Does landing this item require another item in the batch (or an existing
backlog task) to land first, whether by sharing a file/function/behavior or by an explicit
build-on? If so, the dependent entry's description must name the other
entry's exact title and say why it comes first, in plain prose, e.g.
"Depends on the '<other title>' entry, which adds the endpoint it needs."
`radin-execute`'s prioritization reads entry bodies for exactly this
signal; leave it out and it stays invisible.

Classify into exactly one category (conventional-commit vocabulary):

- **feat**: a new capability asked for (idea, feature request).
- **fix**: something broken or behaving incorrectly.
- **chore**: a maintenance follow-up (docs, tooling, cleanup).
- **refactor**: structure should change without behavior change.

Two plausible fits: pick the closer one and move on, because `radin-execute` and
`radin-plan` read the description regardless of category.

## Step 5: Review, confirm scope with user, then append via the CLI

Before anything is appended, review each entry against one bar: can an
agent with no session context and no user reachable plan and execute this
without inventing a choice? An entry passes by carrying its decisions, or
by naming plainly what stays open (an open fact, a deferred decision, a
stub). If it fails and the gap is grillable, return to Step 2.

It also fails when the ask carried literal content (an error string, a path,
a snippet, an explicit constraint) and the entry has no `**Raised as:**`
quote of it. Add the quote before appending.

**Generic ask**: show the finalized list (title + category per item) and
confirm before running the CLI. A session scan is a guess about what the
user wants captured; don't let the guess become entries unchecked.
**Specific ask**: log directly, nothing to check.

For each confirmed item:

```bash
bash "$HOME/.claude/.radin/lib/radin-backlog.sh" add <category> "<short title>" [--skill <skill-name>] <<'EOF'
<as exhaustive a description as the situation warrants: what was being
worked on when this came up, the item close to how the user stated it, and
why it matters. radin-execute/radin-plan act on this entry with no other
session context, so don't compress it to one line.>

<a `**Raised as:**` block quoting the triggering text verbatim: the user's
words, plus any error string, path, or snippet they pasted. Quote, don't
summarize: the executor cannot see this conversation, so your paraphrase is
the only version that survives. Omit the block only when the ask carried no
literal content to quote.>

<one `**Decision:** <question — settled answer>` line per Step 2 answer, using
the same marker radin-execute appends when it settles one, so downstream
readers see one vocabulary. Then any open facts or deferred decisions, in
plain prose.>
EOF
```

Pass Step 3's skill(s) as `--skill <skill-name>` (repeatable). The CLI
appends the canonical `**Skill:**` instruction line itself; never write it
by hand. Omit the flag when no skill applies.

Always append; never scan for near-duplicates or merge with an existing
entry. A false-positive merge silently drops something the user cared
about, which is worse than an occasional repeat. Let `radin-execute`, `radin-plan`,
or a human dedupe later.

## Step 6: Report back

- How many entries logged, with titles and categories.
- Decisions settled by grilling, and questions left open, per entry.
- The backlog path (the CLI prints it on each `add`).
- If nothing in scope rose to a loggable item, say so plainly, and don't pad
  the file with a vague entry to prove the skill ran.
