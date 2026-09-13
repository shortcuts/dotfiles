---
name: explain
description: Explain any topic as one terse note in the user's Obsidian vault - from zero knowledge to the subject itself, plus the links to go deeper.
disable-model-invocation: true
argument-hint: "A topic, concept, commit hash, PR/commit URL, file, or directory"
---

The user asked you to explain something. Produce one Markdown note in the user's Obsidian vault. Assume the reader knows nothing about the subject. They read it in a few minutes and come out with:

- **Why** it exists: the motivation and the decisions.
- **How** it works: the architecture, the key mechanisms, the non-obvious parts.

## What the note is for

Three ideas decide everything else.

**It serves a mission.** The user asked for a reason - to review a change in that area, to debug something, to stop nodding along in a meeting. Infer the reason from how they asked. The mission decides what goes on the note, and what stays off it. Without a mission the note drifts into a generic overview of the subject, which is this skill's main failure mode.

**It builds fluency, not retention.** The reader needs to hold the subject now. One read cannot build long-term recall. Do not pad the note with exercises to fake it.

**It starts from zero.** Assume no prior knowledge of the subject, and none of its prerequisites. The reader is sharp and knows their own field. They may have never heard the word in the title. Every step anchors to a step already on the note. Five unanchored concepts explain nothing.

## Depth

ELI5 at the entry point and in tone. Far past ELI5 in substance. Deliberately short of exhaustive.

Calibrate to this: the reader can hold the subject, follow a conversation about it, and ask a sharp question. Not this: the reader can implement or maintain it.

Give one concrete win the reader gets immediately. They can review a change here, name the moving parts, or know where to look when it breaks. Name that win in the TL;DR.

The cut is the point. Name what you left out instead of covering it. Each skipped mechanism becomes a linked line in **Sources**.

One note is the cap, not the target. Too big a topic means you narrow the topic and say which parts you dropped. A second note defeats the format. A small topic still deserves a short note.

### The ladder

Order the note as rungs, not as topics. Each rung is one step, and it stands on the rung below it. The ladder runs from no knowledge to peer knowledge:

- **Rung one uses no term from the subject.** It states the problem in plain words, or shows the thing that breaks. Anchor it outside the subject: an everyday object, a problem the reader has hit.
- **The top rung reads as if written for someone who already knows the subject.** No anchoring, no analogy, exact names and numbers. A reader who arrives there has been walked up to it.
- **Each middle rung adds at most one new idea**, and uses only terms the note already defined. Five to eight rungs carry most subjects. More than that means the topic is too big - narrow it.
- Define every term at first use, in one clause, inline. No forward references. An idea a rung needs goes lower on the ladder, or off the note.
- Test a rung by deleting the rungs below it. If it still reads on its own, it is an aside, not a rung. Cut it or move it.

**Every rung carries one concrete example**, worked by hand with small real values, matched to that rung's altitude: a physical analogy low down, one traced call or one computed result high up. A reader who follows one case owns the mechanism. A reader who only reads the general rule does not. A rung with no example is a rung the reader cannot check.

Number the rungs in their headings, say how many there are, and name the one idea each adds (`## Rung 3 of 7 - who owns which index`). A reader mid-climb needs to see how far is left.

### Precision

The note is worthless if the reader cannot trust a number.

- **Never compute a value by hand and present it as the system's output.** Run the function, read the test, or quote the config. When a number is your own arithmetic, say so on the line.
- **Never state a rule more strongly than the source does.** "Today one shard per plan" and "one shard per plan" are different claims. Keep the hedge that the source earns; cut the hedge you added yourself.
- **Separate what the code does from what the deployment does.** Code defaults and chart values drift apart. Say which one you read.
- **One term per concept.** Pick the source's word and reuse it. A synonym reads as a second concept.
- Unknown stays unknown. Name who would know.

## Resolving the input

| Input | Meaning |
|---|---|
| Anything not listed below | A concept, subsystem, tool, protocol, practice, event, or idea |
| Bare commit hash | A commit of the repo in the current directory |
| GitHub commit URL | A commit of that remote repo |
| GitHub PR URL | The full PR: commits, body, review discussion |
| A path | That code as it stands, not a change to it |

A bare word can be a concept or a directory. Ask which. Keep questions to that one - the user wants a note, not an interview.

## Gathering the source material

Find the primary source first, whatever the subject is: the spec, the RFC, the reference implementation, the maintainers' own docs, the standard reference work for a general idea.

When one source owns the subject, quote it. When none does - a math idea, a practice, a piece of history - read two independent sources, and say on the note where they disagree.

When the subject also lives in the current repo, explain the general shape from the primary source and the local shape from the local code. Mark which is which.

### When the subject is code, a commit, or a PR

Use `git` and `gh` read operations only. Any write - push, comment, review, label - makes you a participant in a history you are here to read.

The artifact is half the story. Commit messages, PR bodies, and review discussions hold the decisions: why this approach, what reviewers pushed back on, what the author deferred. Gather them every time.

The non-obvious calls:

```bash
gh api repos/OWNER/REPO/commits/SHA/pulls   # the PR a commit landed through
gh api repos/OWNER/REPO/pulls/N/comments    # inline review threads - decision gold
gh api repos/OWNER/REPO/issues/N/comments   # top-level PR discussion, a separate endpoint
git log -S<symbol>                          # when a mechanism first appeared
```

Chase every reference while you gather - each one becomes a link on the note. Issues named in the PR body (`Fixes #123`). Tracker keys hiding in branch names, PR titles, and commit subjects (`PROJ-1234` for Jira, `ENG-456` for Linear) - `gh pr view --json title,body,headRefName,commits` surfaces all three at once. Design docs, runbooks, dashboards, and earlier PRs the discussion names.

For code as it stands, read the code, then recover what it cannot state. `git log --follow <path>` gives the commits that shaped it. `gh pr list --search <path>` gives the discussions behind it.

#### Repository conventions

Read `AGENTS.md` and `CLAUDE.md` - the root ones, and any in the directories the topic touches. Use `gh api repos/OWNER/REPO/contents/...` for a remote topic. They explain choices the code cannot: why this layer, why this naming, why this test shape. Cite them when they explain a decision.

#### Changes the user's own agent wrote

Compare the commit author against `git config user.email`, and the PR author against `gh api user --jq .login`. A match means a coding agent probably did the work for the user, even with no `Co-Authored-By` trailer. Authorship on record does not mean the user knows the change.

- Never compress material because "the user wrote this". They did not. Explaining what their agent did is the whole job.
- The agent also wrote the commit messages and the PR body. Those record what the agent decided, not what the user asked for. Flag on the note where the two might diverge.
- "Ask the author" is a dead end here. Point open questions at reviewers and the owning team.

## Grounding

Never explain from parametric knowledge. It produces confident, plausible, wrong notes, and the reader cannot tell. Every claim traces to something you read: the code, the commit messages, the discussion, the primary source, or the conventions files. Where each trace *appears* on the note is [Provenance](#provenance)'s job.

Establish the motivation before you walk the mechanism - a mechanism without its why is noise. Rank the sources for it: for a concept, the spec rationale, the design notes, what people did before it; for a change, the linked issue, then the PR body, then the commit messages, then the review discussion, which often records the rejected alternatives, the sharpest form of why.

When the sources hold no motivation, say so on the note. Name who would know: a reviewer, the owning team, the spec authors. An invented motivation is worse than an admitted gap.

## Carrying the idea visually

Prose is the slowest way to convey a shape. Per mechanism, pick the form that carries it fastest:

- **Pseudocode** for logic and algorithms - the decision, not the syntax.
- **A call tree** for runtime control flow.
- **A shallow file tree** for responsibility and layering, one comment per entry.
- **A component tree** for UI structure, with the state and module boundaries that matter.
- **A Mermaid sequence or flow diagram** for interaction across components or services.
- **A diff, or a before-and-after pair** when the point is what changed and the surrounding shape exists already. Match it to the topic: diff the file tree for a layout change, the call tree for a flow change, the pseudocode for a logic change.
- **A real code block** when most of it is new, or when the missing context would hide ownership or order.
- **A small table** for a finite set of cases, states, or side-by-side options.

Keep only the calls, files, props, states, and boundaries that answer the question at hand. A complete diagram is a failed diagram. Put each visual next to the short text it supports, never in a gallery at the end. One or two forms carry most notes.

## The note

Structure:

- **Header**: title, linked ref (primary source, commit, PR, or path). For a change, add author, date, merge state. Say what the subject is, positively - a reader with no model of it cannot use "this is not a queue".
- **TL;DR**: one or two sentences - why the subject exists and how it works - then the reader's win on its own line. The first sentence defines the subject in plain words, and uses no term the reader must already know. Two sentences is the cap, not the target.
- **Why**: the motivation and the decisions, in plain present tense - the problem the subject solves, and what it would cost to not have it. The receipts for those claims live in **How it got here**, and so do the rejected alternatives.
- **How**: the shape first - the one tree, table, or diagram that holds the whole subject. For a change, the file tree or the `--stat`. Then the rungs, lowest first. Each gets its example, its visual form, and a line of prose. Call out the non-obvious parts, and how repo conventions shaped them.
- **Sharp edges**, at most: the traps a reader hits that the rungs could not hold - a stale test, a lock order, a "quick fix" still in place. One line each.
- **How it got here**: the history, in one place. See [Provenance](#provenance).
- **Sources**: every link worth opening next. See [Links](#links).

The top rung ends the explanation. Only those three sections follow it. Reference material - full config tables, metric lists, sizing charts - is not a rung and does not earn a section; link it in **Sources** instead. That appendix is where the format bloats.

Every mechanism gets a heading. Obsidian builds the outline pane from them, so write no jump list of your own.

### Shaping it for a reader who skims

A reader opens this note mid-task, with a browser full of tabs. The note competes with those tabs. Shape it to survive a distracted read:

- **Open every section with its substance.** The first line after a heading is the mechanism, the command, the number, or the path - never a lead-in announcing what the section will cover. Cut "This section explains", "Let's look at", "Before we dive in".
- **Cap a list or table at five rows.** More than five and the reader stops reading rows and starts scanning for the end. Rank them, show the five that matter, and link the rest. This cap is on the note - it does not apply to prose, to code blocks, or to a table whose whole point is being exhaustive (a state machine's states, a fixed enum).
- **One bounded idea per list item.** No item that hides a second step behind "and then".
- **Concrete units, never vague quantifiers.** "Every 100 ms", "4 GB", "99% of indices" - not "frequently", "a lot of memory", "most". A vague quantifier is a claim you did not check.
- **Close with one thing the reader can do in two minutes**: open this file, run this query, look at this dashboard panel. Then the line inviting them back with questions - you answer faster than the note, and the note cannot answer at all.

The reader asked for an explanation, so length is not the enemy. Preamble, recap, and restatement are.

### Writing the note

Markdown carries the note: headings, tables, code fences, Mermaid blocks, links. The vault theme styles all of it, so write no CSS. Reach for inline HTML only for a shape Markdown cannot express - Obsidian strips `<script>`, and a `<style>` block fights the user's theme and dark mode.

```bash
vault="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes"
```

#### Frontmatter

The vault already has a frontmatter convention, set by the notes the web clipper writes. Reuse those keys - a new key of your own is a property Obsidian shows in its own row and no other note shares.

```yaml
---
title: Fair build scheduling in the index builder
description: One sentence - the TL;DR's first line. Obsidian shows it in hover previews and search results.
source: https://algolia.atlassian.net/wiki/spaces/.../RFC+-+Fair+build+scheduling
author: indexing-scale team
created: 2026-09-11
aliases:
  - c2m
  - orchestrator
tags:
  - explain
  - engineering-distributed-systems
  - metis
---
```

| Key | What goes in it |
|---|---|
| `title` | The note title, same as the `#` heading |
| `description` | The TL;DR's first sentence. This is what the reader sees before opening the note |
| `source` | The **one best read** only - the primary source. The rest stay in **Sources** |
| `tags` | `explain`, then the field, then the repo or product if there is one |
| `created` | `date +%F`. Never type today's date from memory |
| `author`, `published`, `aliases` | Only when they apply: the owning team or spec author, the source's own date, the acronyms and alternate names a reader would search for |

**Match the vault's existing tags before you invent one.** The taxonomy is flat `field-subfield` kebab-case (`engineering-distributed-systems`, `engineering-apis`, `health-fitness`), not nested `#engineering/distributed`. Read what is already in use, and reuse the closest:

```bash
grep -rhE '^  - [a-z0-9-]+$' "$vault" --include='*.md' | sort -u
```

Every note the skill writes carries `explain`, so `tag:#explain` lists them all. Add at most three more: the field, the repo or product, and the subsystem if it earns its own tag. Wikilink tags (`- "[[GitHub]]"`) appear in clipped notes - that is the clipper's habit, not a convention to copy.

Scope the note by repository, the way `fish/functions/obsd.fish` does:

| Subject | Path under the vault |
|---|---|
| Code, a commit, a PR, or anything else in a git repo | `<repo>/explain/<slug>.md` |
| A general concept, with no repo behind it | `Knowledge/<slug>.md` |

Name the slug after the subject: `data-ingestion-pr7959`, `metis-metricsreporter`, `oauth-pkce`. Never write the note into the user's repository or working directory - an explanation is not a project artifact.

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null)
rel="Knowledge/<slug>.md"
[ -n "$root" ] && rel="$(basename "$root")/explain/<slug>.md"

mkdir -p "$vault/$(dirname "$rel")"
# write the note to "$vault/$rel", then:
for i in 1 2 3 4 5 6; do obsidian open vault=notes path="$rel" && break; sleep 0.5; done
```

Obsidian indexes a new file with a delay, so the open retries.

## Provenance

History is not explanation. A reader meeting the subject for the first time cannot use a ticket key, a PR number, a commit hash, or a date - those are receipts for a claim they have no reason to doubt yet. Dropped mid-sentence they break the ladder: the reader stops following the mechanism and starts wondering whether they were supposed to recognise that number.

So the explanation states what is true now, and **How it got here** holds why it became that way.

- **In the rungs**: plain words and present tense. "Two codebases, because Classic has no read API a migration can use." Cite the thing the reader can open and read *as documentation* - the file and line, the spec section, the function name. Never a ticket key, a PR number, a commit hash, or a date.
- **Quote a source in a rung only when its wording is the explanation** - a comment naming the incident a guard prevents, a spec sentence no paraphrase improves. Attribute it to the file or the spec, not to the PR it landed in.
- **In How it got here**: the tickets, the PRs, the commits, the dates, the rejected alternatives, the order things happened. One line per event, newest or oldest first, consistently. This is where a quoted PR excerpt or review thread belongs.
- Keep it to the history that still changes a reader's decisions: why the split exists, which default was flipped and when, which fix is still called temporary. Cut the rest - a chronology of every PR is not history, it is `git log`.
- A subject with no recorded history gets no section. Say so once in **Sources** and move on.

The same split applies off code. For a concept: the rungs explain the idea, the history names who proposed it, what it replaced, and what the field rejected.

## Links

Links are half the value of the note. The reader closes it knowing the subject, and knowing exactly where to go for the parts you cut.

Every claim carries its source, right where the claim sits - but only sources that read as documentation: a file and line, a spec section, a config path. Change-trail links (PRs, commits, tickets) go to **How it got here**. A reader who wants to check a fact must never have to search for it.

**Sources** then collects everything worth opening next. Give each link one line on why the reader would open it - a bare URL list is a dead end. The change trail and the tracker are already in **How it got here**; do not list them twice.

- **The one best read**, first, and why it is the one: the spec section, the RFC, the reference implementation, the design doc, the Wikipedia article for a general concept. This is also the note's `source:` frontmatter.
- **The operational context**: the runbook, the dashboard, the alert, the postmortem the change came out of.
- **The parts this note skipped**, each with the link that covers it.
- **The open questions**, each with who to ask.

Skip a category you found nothing for. A padded link list costs the reader more than a short one.

## The slop pass

Run the drafted prose through the `no-ai-slop` skill in Edit mode before you write the file. It will ask who the piece is for - answer up front so it does not stall: a sharp reader new to this subject, who should close the note able to reason about it.

It catches what this note leaks most: throat-clearing, hedges, abstraction standing where a mechanism belongs, sentences that would survive unchanged on a note about something else. Cut rather than smooth. A shorter note is the right outcome.

Keep quoted commit messages, review comments, and spec passages verbatim - the voice to preserve is the sources'. Skip the pass over code, diffs, diagrams, and identifiers.

## After the note

The note is the deliverable. Open it and stop.

A follow-up question about one mechanism - "how does the retry loop work?", "what calls this?" - gets answered in the conversation, with the visual forms above. Regenerating the note for one question wastes both of you.

Some users need to own a topic rather than understand it once, because they will review, debug, and extend it for months. One note cannot build that. Say so plainly, and name what would: repeated sessions on the real code. Do not stretch the note to cover the gap.
