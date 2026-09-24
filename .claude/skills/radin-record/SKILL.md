---
name: radin-record
description: |
  Log feedback, bugs, follow-ups, or ideas raised mid-session as structured
  backlog entries, so they survive past the conversation. Use for
  /radin-record or any request to save something from this session for
  later (a bug, follow-up, idea, or finding). Triggers even on vague asks ("add the findings"): scan the
  whole session, not just the literal text.
---
# Record to Backlog

This captures what a human said; `radin-review` logs what a diff revealed. Every
downstream reader -- `radin-plan`, `radin-execute`, the execution sub-agent it
dispatches -- is a **cold start**: it sees the entry and nothing of this
conversation. Every step below exists to make an entry survive that.

## Step 1: Decide what to log

The instruction after `/radin-record` sets the scope:

- **Specific** ("add the auth timeout bug"): log exactly that item, nothing else.
- **Generic** ("add the findings", bare `/radin-record`): scan the whole session
  for anything a reasonable person calls a bug, follow-up, idea, or feedback,
  including "we should probably..." asides nobody wrote down. Each distinct item
  becomes its own entry.

Log only what the conversation raised, worded close to how it was raised.

One raised thing can be several sequential pieces of work ("add rate limiting on
top of new auth middleware" needs the middleware first). Log each piece as its
own entry, sized as a **vertical slice**:

- It cuts a narrow but COMPLETE path through every layer it touches -- vertical,
  not a horizontal slice of one layer.
- Landed, it is demoable or verifiable on its own.
- It fits one fresh context window, the cold start it gets.
- A **prefactor** -- the restructuring that makes the real change easy -- is its
  own entry, which every entry needing it depends on. Make the change easy, then
  make the easy change.

One mechanical change whose blast radius fans across the codebase -- rename a
column, retype a shared symbol -- is the exception: no vertical slice of it
lands green, so log it as one entry per batch the change breaks, plus a final
entry that puts the tree back green depending on every batch.

An item too fuzzy to phrase as a sharp question is a **stub** ("figure out
caching at some point"): log one stub over the whole area, its body saying what
is unspecified and what is known, rather than pre-slicing it. `radin-plan`
sharpens it later. A question you *can* state precisely is an ordinary entry,
blocked or not.

### An Atlassian ticket in the ask (optional)

A ticket key or a Jira/Confluence URL: fetch it through the Atlassian MCP and
treat the ticket as more of the user's prompt. No Atlassian MCP, or a failed
fetch: log from the ask alone, and continue.

## Step 2: Chart each item's open decisions

The user is at the keyboard now, and `radin-execute` may later run with nobody
behind it: settle judgment calls here and execution never has to.

For each item, list what a cold start would have to decide that the conversation
didn't settle. Tag each question:

- **Fact**: checkable against the repo, docs, or an API. Never ask the user for
  these; note each in the entry body as an open fact to verify.
- **Decision**: a judgment call only the user can make (tradeoff, scope boundary,
  behavior choice). Invoke `/mattpocock-skills:grilling` on this item's decisions
  now, before the next item. Keep every settled answer for Step 5's body.

Name even one plausible guess (a threshold, a naming choice, keep-vs-remove) and
the item has a Decision, so grill it. An item with no second reasonable way to do
it skips this step, and so does a stub -- one deliberately deferred whole.

If the user defers a question or stops answering, record the question itself as an
open decision in the entry body, options and your recommendation included, so
`radin-execute` blocks on it explicitly instead of guessing.

## Step 3: Note any skill invoked for this item

If the request that raised the item explicitly invoked a skill (e.g.
`/radin-record /frontend-design make the accent color...`, or a skill ran earlier
and the item continues that work), record it as a standing instruction, even if it
looks redundant or wrong-fit to you: without the line a cold start re-implements
from bare text and never invokes the skill the user chose.

`/radin-record /other-skill <...>` means "record an instruction to run
`/other-skill` later", and never run `/other-skill` now. Treat `/other-skill
<...>` as the text to log: go to Step 1 with it as the item, log with
`--skill other-skill`, and stop.

## Step 4: Classify each item and note dependencies

Does landing this item require another item in the batch (or an existing backlog
task) to land first, by sharing a file/function/behavior or by an explicit
build-on? Note the other entry's exact title for Step 5's `set-deps`, and say why
it comes first in the dependent entry's description -- the `depends_on` field
carries the ordering, the prose the reason.

Classify into exactly one category (conventional-commit vocabulary):

- **feat**: a new capability asked for (idea, feature request).
- **fix**: something broken or behaving incorrectly.
- **chore**: a maintenance follow-up (docs, tooling, cleanup).
- **refactor**: structure should change without behavior change.

## Step 5: Review, quiz the user on the batch, then append via the CLI

An entry passes by carrying its decisions, or by naming what stays open. Literal
content in the ask -- an error string, a path, a snippet, an explicit constraint
-- belongs in the `**Raised as:**` quote before anything is appended.

Present the batch as a numbered list, each item showing:

- **Title**: the short descriptive name.
- **Category**: from Step 4.
- **Blocked by**: the entries that gate it, or "None -- can start immediately".
- **What it delivers**: the end-to-end behavior this entry makes work.

Then ask whether the granularity, the dependencies, and the split are right.
Iterate until the user approves the batch. One run skips the gate: a specific ask
that produced exactly one entry with no dependencies. A generic ask always
quizzes, single entry included, because a session scan is a guess about what the
user wants captured.

A cold start reads the body and nothing else, so quote rather than paraphrase --
your paraphrase is the only version that survives. Name the behavior and each
file by its role, because the paths and snippets you would write yourself go
stale within a commit or two. Two exceptions stay verbatim: the `**Raised as:**`
quote, paths and snippets the user pasted included, and a snippet that encodes a
decision more precisely than prose can (state machine, schema, type shape),
trimmed to the decision-rich part.

For each approved item:

```bash
radin backlog add <category> "<short title>" [--skill <skill-name>] <<'EOF'
<the description: what was being worked on, the item close to how the user
stated it, why it matters>

<**Raised as:** and the triggering text verbatim, the user's words plus any
error string, path or snippet they pasted.>

<one **Decision:** <question -- settled answer> line per Step 2 answer, then any
open facts or deferred decisions in plain prose.>
EOF
```

Pass Step 3's skill(s) as `--skill <skill-name>` (repeatable). The CLI composes
the canonical instruction sentence itself; never write it by hand. Omit the
flag when no skill applies.

Acceptance criteria live on the entry, not in the body: one call per entry
whose session already stated a checkable outcome, each criterion as bare text
with no bullet and no checkbox. Never ask for criteria, never synthesise one.

```bash
radin backlog set-meta <id> acceptance "<criterion>" "<criterion>"
```

Once every approved item is added -- each `add` prints its id -- record Step 4's
dependencies, one call per dependent entry, always after all the adds:

```bash
radin backlog set-deps <dependent-id> <csv-of-ids-it-depends-on>
```

Each noted title is either an id an `add` just printed, or, for a task that already
existed, `radin backlog field "<title>" TASK_ID`.

Always append; never scan for near-duplicates or merge with an existing entry: a
false-positive merge silently drops something the user cared about, which is worse
than an occasional repeat. The user dedupes.

## Step 6: Report back

- How many entries logged, with titles and categories, and the backlog path the
  CLI printed.
- Decisions settled by grilling, and questions left open, per entry.
- If nothing in scope rose to a loggable item, say so plainly, and don't pad the
  file with a vague entry to prove the skill ran.
