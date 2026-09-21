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

**Wide refactors are the exception to vertical slicing.** A **wide refactor** is
one mechanical change -- rename a column, retype a shared symbol -- whose **blast
radius** fans across the codebase, so a single edit breaks call sites everywhere
at once and no vertical slice lands green. Sequence it as **expand-contract**,
each arrow a Step 4 dependency: expand (add the new form beside the old) depends
on nothing; one migrate entry per batch sized by blast radius (per package, per
directory) depends on the expand; contract (delete the old form) depends on every
migrate entry. When even one batch cannot stay green alone, keep that sequence
and add a final integrate-and-verify entry depending on every batch, where green
is promised.

An item can instead be a **stub**. The test is whether you can state the question
precisely now, not whether you can answer it now: a sharp question is an ordinary
entry even when it is blocked and nobody can act on it yet, and a question you
cannot yet phrase that sharply is the stub ("figure out caching at some point").
Log one stub covering the whole fuzzy area, its body saying plainly what is
unspecified and what is known so far, rather than pre-slicing that area into
entry-sized pieces. `radin-plan` sharpens it later.

### An Atlassian ticket in the ask (optional)

A ticket key or a Jira/Confluence URL: fetch it through the Atlassian MCP and
treat the ticket as more of the user's prompt. No Atlassian MCP, or a failed
fetch: log from the ask alone, and continue.

## Step 2: Chart each item's open decisions (MANDATORY GATE)

The user is at the keyboard now, and `radin-execute` may later run with nobody
behind it: settle judgment calls here and execution never has to.

For each item, list what a cold start would have to decide that the conversation
didn't settle. Tag each question:

- **Fact**: checkable against the repo, docs, or an API. Never ask the user for
  these; note each in the entry body as an open fact to verify.
- **Decision**: a judgment call only the user can make (tradeoff, scope boundary,
  behavior choice). Invoke `/mattpocock-skills:grilling` on this item's decisions
  now, before the next item. Keep every settled answer for Step 5's body.

One test decides whether an item may skip this step: what would a cold start have
to guess to land it without asking anyone? Name even one plausible guess (a
threshold, a naming choice, keep-vs-remove, which of two reasonable approaches)
and it is a Decision, so grill it. An item with no second reasonable way to do it
clears the test and skips the step. A stub skips too: one deliberately deferred
whole, not an item with grillable edges.

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
build-on? If so, note the other entry's exact title: Step 5 records it with
`set-deps`, and that `depends_on` field is the only dependency signal
`radin-execute`'s prioritization reads. Say why it comes first in the dependent
entry's description too ("Depends on the '<other title>' entry, which adds the
endpoint it needs") -- the field carries the ordering, the prose the reason.

Classify into exactly one category (conventional-commit vocabulary):

- **feat**: a new capability asked for (idea, feature request).
- **fix**: something broken or behaving incorrectly.
- **chore**: a maintenance follow-up (docs, tooling, cleanup).
- **refactor**: structure should change without behavior change.

Two plausible fits: pick the closer one and move on, because `radin-execute` and
`radin-plan` read the description regardless of category.

## Step 5: Review, quiz the user on the batch, then append via the CLI

Re-run Step 2's test on each finished entry before anything is appended: it passes
by carrying its decisions, or by naming plainly what stays open (an open fact, a
deferred decision, a stub). A grillable gap sends you back to Step 2; literal
content in the ask (an error string, a path, a snippet, an explicit constraint)
with no `**Raised as:**` quote of it means adding the quote first.

Present the batch as a numbered list, each item showing:

- **Title**: the short descriptive name.
- **Category**: from Step 4.
- **Blocked by**: the entries that gate it, or "None -- can start immediately".
- **What it delivers**: the end-to-end behavior this entry makes work.

Then ask, by name:

- Does the granularity feel right? (too coarse / too fine)
- Are the dependencies correct -- does each entry depend only on entries that
  genuinely gate it?
- Should any entries be merged or split further?

Iterate until the user approves the batch: revise the list from their answers,
re-present it, and leave this gate on their approval. One run skips the gate --
the degenerate one, a specific ask that produced exactly one entry with no
dependencies, where all three questions have no content: log it directly. A
generic ask always quizzes, single entry included, because a session scan is a
guess about what the user wants captured.

A cold start reads the body, so the description carries every fact a downstream
agent needs to act and stops there. Quote rather than paraphrase -- your
paraphrase is the only version that survives.
Name the behavior, and each file by its role, rather than the paths and snippets
you would write yourself, which go stale within a commit or two. One exception: a
snippet that encodes a decision more precisely than prose can (state machine,
reducer, schema, type shape), trimmed to the decision-rich part. The
`**Raised as:**` quote is provenance and stays verbatim, paths and snippets the
user pasted included.

Write a section only when it carries content a downstream agent acts on; a
label with nothing under it goes nowhere.

For each approved item:

```bash
radin backlog add <category> "<short title>" [--skill <skill-name>] <<'EOF'
<the description: what was being worked on, the item close to how the user
stated it, why it matters>

<**Raised as:** and the triggering text verbatim, the user's words plus any
error string, path or snippet they pasted.>

<one **Decision:** <question -- settled answer> line per Step 2 answer, then any
open facts or deferred decisions in plain prose.>

<**Acceptance:** and one `- [ ] <criterion>` bullet per criterion, each on a
single unindented line, only when the session already stated a checkable
outcome: never ask for criteria, never synthesise one.>
EOF
```

Pass Step 3's skill(s) as `--skill <skill-name>` (repeatable). The CLI appends the
canonical `**Skill:**` instruction line itself; never write it by hand. Omit the
flag when no skill applies.

Once every approved item is added -- each `add` prints its id -- record Step 4's
dependencies, one call per dependent entry, always after all the adds and never as
`--depends-on` on `add`:

```bash
radin backlog set-deps <dependent-id> <csv-of-ids-it-depends-on>
```

Each noted title is either an id an `add` just printed, or, for a task that already
existed, `radin backlog field "<title>" TASK_ID`. The CLI rejects an unknown id
and any cycle, so a rejection means the dependency is misidentified, not that the
flag is optional.

Always append; never scan for near-duplicates or merge with an existing entry: a
false-positive merge silently drops something the user cared about, which is worse
than an occasional repeat. The user dedupes.

## Step 6: Report back

- How many entries logged, with titles and categories, and the backlog path the
  CLI printed.
- Decisions settled by grilling, and questions left open, per entry.
- If nothing in scope rose to a loggable item, say so plainly, and don't pad the
  file with a vague entry to prove the skill ran.
