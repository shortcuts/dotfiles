---
name: explain
description: Explain any topic as one terse HTML page - enough to hold the subject, plus the links to go deeper.
disable-model-invocation: true
argument-hint: "A topic, concept, commit hash, PR/commit URL, file, or directory"
---

The user asked you to explain something. Produce one self-contained HTML page a technical reader absorbs in a few minutes:

- **Why** it exists: the motivation, the decisions, the rejected alternatives.
- **How** it works: the architecture, the key mechanisms, the non-obvious parts.

## What the page is for

Three ideas decide everything else.

**It serves a mission.** The user asked for a reason - to review a change in that area, to debug something, to stop nodding along in a meeting. Infer the reason from how they asked. The mission decides what goes on the page, and what stays off it. Without a mission the page drifts into a generic overview of the subject, which is this skill's main failure mode.

**It builds fluency, not retention.** The reader needs to hold the subject now. One read cannot build long-term recall. Do not pad the page with exercises to fake it.

**It starts from what the reader knows.** Working memory is small. Anchor each mechanism to something already on the page, or already in the reader's hands: a familiar pattern, the layer above it, the thing it replaced. Then extend by one step. Five unanchored concepts explain nothing.

## Depth

ELI5 in tone. Far past ELI5 in substance. Deliberately short of exhaustive.

Calibrate to this: the reader can hold the subject, follow a conversation about it, and ask a sharp question. Not this: the reader can implement or maintain it.

Give one concrete win the reader gets immediately. They can review a change here, name the moving parts, or know where to look when it breaks. Name that win in the TL;DR.

The cut is the point. Name what you left out instead of covering it. Each skipped mechanism becomes a linked line in **Sources**.

One page is the cap, not the target. Too big a topic means you narrow the topic and say which parts you dropped. A second page defeats the format.

## Resolving the input

| Input | Meaning |
|---|---|
| Bare commit hash | A commit of the repo in the current directory |
| GitHub commit URL | A commit of that remote repo |
| GitHub PR URL | The full PR: commits, body, review discussion |
| A path | That code as it stands, not a change to it |
| Anything else | A concept, subsystem, tool, protocol, or idea |

A bare word can be a concept or a directory. Ask which. Keep questions to that one - the user wants a page, not an interview.

## Gathering the source material

Use `git` and `gh` read operations only. Any write - push, comment, review, label - makes you a participant in a history you are here to read.

The artifact is half the story. Commit messages, PR bodies, and review discussions hold the decisions: why this approach, what reviewers pushed back on, what the author deferred. Gather them every time.

The non-obvious calls:

```bash
gh api repos/OWNER/REPO/commits/SHA/pulls   # the PR a commit landed through
gh api repos/OWNER/REPO/pulls/N/comments    # inline review threads - decision gold
gh api repos/OWNER/REPO/issues/N/comments   # top-level PR discussion, a separate endpoint
git log -S<symbol>                          # when a mechanism first appeared
```

Chase every reference while you gather, because each one becomes a link on the page. Issues named in the PR body (`Fixes #123`). Tracker keys hiding in branch names, PR titles, and commit subjects (`PROJ-1234` for Jira, `ENG-456` for Linear) - `gh pr view --json title,body,headRefName,commits` surfaces all three at once. Design docs, runbooks, dashboards, and earlier PRs the discussion names.

For code as it stands, read the code, then recover what it cannot state. `git log --follow <path>` gives the commits that shaped it. `gh pr list --search <path>` gives the discussions behind it.

For a concept, tool, or protocol, find the primary source: the spec, the RFC, the reference implementation, the maintainers' own docs. When the topic also lives in the current repo, explain the general shape from the primary source and the local shape from the local code. Mark which is which.

### Repository conventions

Read `AGENTS.md` and `CLAUDE.md` - the root ones, and any in the directories the topic touches. Use `gh api repos/OWNER/REPO/contents/...` for a remote topic. They explain choices the code cannot: why this layer, why this naming, why this test shape. Cite them when they explain a decision.

### Changes the user's own agent wrote

Compare the commit author against `git config user.email`, and the PR author against `gh api user --jq .login`. A match means a coding agent probably did the work for the user, even with no `Co-Authored-By` trailer. Authorship on record does not mean the user knows the change.

- Never compress material because "the user wrote this". They did not. Explaining what their agent did is the whole job.
- The agent also wrote the commit messages and the PR body. Those record what the agent decided, not what the user asked for. Flag on the page where the two might diverge.
- "Ask the author" is a dead end here. Point open questions at reviewers and the owning team.

## Grounding

Never explain from parametric knowledge. It produces confident, plausible, wrong pages, and the reader cannot tell. Ground every claim in the code, the messages, the discussion, the primary source, or the conventions files. Cite each one: link the commit, the PR, the specific review thread, the spec section.

Establish the motivation before you walk the mechanism. A mechanism without its why is noise. Best "why" sources, in order: the linked issue, the PR body, the commit messages, then the review discussion - which often records the rejected alternatives, the sharpest form of why.

When the sources hold no motivation, say so on the page. Name who would know: a reviewer, the owning team, the spec authors. An invented motivation is worse than an admitted gap.

## Carrying the idea visually

Prose is the slowest way to convey a shape. Per mechanism, pick the form that carries it fastest:

- **Pseudocode** for logic and algorithms - the decision, not the syntax.
- **A call tree** for runtime control flow.
- **A shallow file tree** for responsibility and layering, one comment per entry.
- **A component tree** for UI structure, with the state and module boundaries that matter.
- **A Mermaid sequence or flow diagram** for interaction across components or services.
- **A diff** when the point is what changed and the surrounding shape exists already. Match the diff to the topic: diff the file tree for a layout change, the call tree for a flow change, the pseudocode for a logic change.
- **A real code block** when most of it is new, or when the missing context would hide ownership or order.

Keep only the calls, files, props, states, and boundaries that answer the question at hand. A complete diagram is a failed diagram. Put each visual next to the short text it supports, never in a gallery at the end. One or two forms carry most pages.

## The page

Structure:

- **Header**: title, linked ref (commit, PR, path, or primary source). For a change, add author, date, merge state.
- **TL;DR**: two or three sentences, and the reader's win. The whole page in miniature.
- **Why**: the motivation and the decisions. Quote the exact commit line, PR excerpt, review comment, or spec passage behind each claim, linked to its source. Include the rejected alternatives the sources record.
- **How**: the shape first - the file tree, the `--stat`, the top-level flow. Then the mechanisms, in the order a reader needs them. Each gets its visual form and a line of prose. Call out the non-obvious parts, and how repo conventions shaped them.
- **Sources**: every link worth opening next. See [Links](#links).

Past three mechanisms, add a jump list of internal anchors. A one-pager still has to be navigable on the second visit.

Close the page with a line inviting the reader back with questions. You answer faster than the page, and the page cannot answer at all.

One self-contained HTML file: all CSS inline, no external assets. Write it to `~/.claude/.explain/<slug>.html` (`data-ingestion-pr7959.html`, `metis-metricsreporter.html`, `oauth-pkce.html`). Keep it out of the user's repository and working directory - an explanation is not a project artifact. Open it for the user when done (`open` on macOS).

Make it beautiful: clean typography, prints well. Think Tufte. A small topic still deserves a short page.

## Links

Links are half the value of the page. The reader closes it knowing the subject, and knowing exactly where to go for the parts you cut.

Every claim carries its source as an inline link, right where the claim sits. A reader who wants to check a fact must never have to search for it.

**Sources** then collects everything worth opening next. Give each link one line on why the reader would open it - a bare URL list is a dead end.

- **The one best read**, first, and why it is the one: the spec section, the RFC, the reference implementation, the design doc, the Wikipedia article for a general concept.
- **The change trail**: the commits, the PR, the sharpest review threads, earlier PRs the discussion names.
- **The tracker**: the Jira ticket, the Linear issue, the GitHub issue - wherever the original request lives. That is where the "why" started, and it usually outlives the PR.
- **The operational context**: the runbook, the dashboard, the alert, the postmortem the change came out of.
- **The parts this page skipped**, each with the link that covers it.
- **The open questions**, each with who to ask.

Skip a category you found nothing for. A padded link list costs the reader more than a short one.

## The slop pass

Run the drafted prose through the `no-ai-slop` skill in Edit mode before you write the file. That skill asks the writer who the piece is for; answer up front so it does not stall. The audience is a technical reader fluent in code. The format is this one-pager. The reader should close it able to reason about the subject.

It catches what this page leaks most: throat-clearing, hedges, abstraction standing where a mechanism belongs, sentences that would survive unchanged on a page about something else. Cut rather than smooth. A shorter page is the right outcome.

Keep quoted commit messages, review comments, and spec passages verbatim - the voice to preserve is the sources'. Skip the pass over code, diffs, diagrams, and identifiers.

## After the page

The page is the deliverable. Open it and stop.

A follow-up question about one mechanism - "how does the retry loop work?", "what calls this?" - gets answered in the conversation, with the visual forms above. Regenerating the page for one question wastes both of you.

Some users need to own a topic rather than understand it once, because they will review, debug, and extend it for months. One page cannot build that. Say so plainly, and name what would: repeated sessions on the real code. Do not stretch the page to cover the gap.
