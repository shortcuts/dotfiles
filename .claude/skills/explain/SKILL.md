---
name: explain
description: Explain any topic as a single, terse HTML one-pager - enough to understand the subject, a summary, and the links to go deeper.
disable-model-invocation: true
argument-hint: "A topic, concept, commit hash, PR/commit URL, file, or directory"
---

The user has asked you to explain something. Produce **one self-contained HTML page** that a technical reader absorbs in a few minutes:

- **Why** it exists: the motivation, the decisions taken, the alternatives rejected.
- **How** it works: the architecture, the key mechanisms, the non-obvious parts.

Think **course, not lesson**. This page walks the whole topic end to end in reading order, so the reader closes it with the shape of the thing in their head.

## Wrapping `teach`

This skill is a constrained one-shot run of `mattpocock-skills:teach`. **Invoke that skill first**, before gathering anything - it carries the teaching craft this page depends on. Then apply the overrides below; where they conflict with `teach`, the overrides win.

Keep from `teach`:

- Teach from high-quality, high-trust sources only (see [Grounding](#grounding)).
- Ground everything in the mission - the reason this user wants to understand this topic.
- Recommend the single best primary source for the reader to go read next.
- A beautiful, Tufte-clean HTML page that prints well.
- A reminder on the page that you are available for follow-up questions.
- Open the file for the user when done.

Override:

| `teach` | `explain` |
|---|---|
| Stateful across sessions | One shot. Gather, write the page, open it, done. |
| Workspace in the current directory | One file in `~/.claude/.explain/`. No workspace, no `learning-records/`, no `NOTES.md`. |
| A series of lessons, one scoped win each | One page, the whole topic in reading order. |
| Question the user until the mission is clear | Infer the mission from how they asked. At most one question, and only when the input is genuinely ambiguous. |
| Quizzes, retrieval practice, spacing, interleaving | None. No exercises, no embedded questions. |
| Builds storage strength (long-term retention) | Builds fluency (understand it now). This is why `teach` is the escalation, not the competitor. |
| Reusable components in `./assets/` | Self-contained page, all CSS inline. |

## Depth

ELI5 in tone, far past ELI5 in substance, and deliberately short of exhaustive. Calibrate to this: the reader can now hold the subject in their head, follow a conversation about it, and ask a sharp question. Not this: the reader can now implement or maintain it.

That cut is the point - name what you left out instead of covering it. Every mechanism the page skips becomes a line in **Sources** with a link, so the reader can go deeper alone.

**One page maximum.** A hard cap, not a target. When the topic is too big, narrow the topic and say which parts you cut - never spill onto a second page.

## Resolving the Input

Classify the input, then gather accordingly:

| Input | Meaning |
|---|---|
| Bare commit hash | A commit of the repo in the current directory |
| GitHub commit URL | A commit of that remote repo |
| GitHub PR URL | The full PR: commits, body, review discussion |
| A path (file or directory) | That code, as it stands - not a change to it |
| Anything else | A concept, subsystem, tool, protocol, or idea |

When the input is ambiguous - a bare word that could be a concept or a directory - ask which. That is the only question you may ask.

## Gathering the Source Material

You may use `git` and `gh` **read operations only**. Never perform any write operation (no push, no comments, no reviews, no labels) - you are a reader of this history, not a participant.

For anything with a history, the artifact alone is half the story. Commit messages, PR bodies, and review discussions are where the *decisions* live - why this approach, what was pushed back on, what was deferred. Always gather them.

### For a local commit

```bash
git log -1 --format=full <sha>          # full commit message - primary "why" source
git show --stat <sha>                   # shape of the change
git show <sha>                          # the diff itself
git log --oneline <sha>~5..<sha>        # surrounding history for context
gh api repos/{owner}/{repo}/commits/<sha>/pulls   # PR this commit landed through, if any
```

If the commit came from a PR, follow the PR too - the discussion there usually explains more than the message.

### For a remote commit URL

```bash
gh api repos/OWNER/REPO/commits/SHA                # message, author, files, patches
gh api repos/OWNER/REPO/commits/SHA/pulls          # associated PR(s)
```

### For a PR URL

```bash
gh pr view <url> --json title,body,author,url,state,mergedAt,baseRefName,commits,files
gh pr diff <url>                                   # the full diff
gh api repos/OWNER/REPO/pulls/N/reviews            # review verdicts and summaries
gh api repos/OWNER/REPO/pulls/N/comments           # inline review threads - decision gold
gh api repos/OWNER/REPO/issues/N/comments          # top-level discussion
```

Also chase references: linked issues in the PR body (`Fixes #123`), design docs, earlier PRs mentioned in discussion. Fetch them with `gh api` / `gh issue view` when they carry motivation.

### For code as it stands

Read the code. Then recover the *why* the code cannot state: `git log --follow <path>` for the commits that shaped it, `git log -S<symbol>` for when a mechanism appeared, `gh pr list --search <path>` for the discussions behind it. Code explains itself; only its history explains its decisions.

### For a concept, tool, or protocol

Never explain from parametric knowledge alone. Find the primary source - the spec, the RFC, the reference implementation, the maintainers' own docs - and explain from it. When the topic also lives in the current repo, explain the general shape from the primary source and the local shape from the local code, and mark which is which.

### Repository conventions

Read the repository's `AGENTS.md` and `CLAUDE.md` (root and any in the directories the topic touches) when they exist - locally, or via `gh api repos/OWNER/REPO/contents/...` for remote topics. They encode the conventions and architecture the code was written against, and often explain choices the code can't: why this layer, why this naming, why this test shape. Use them to interpret the topic; cite them when they explain a decision.

### Agent-authored changes

When the topic is a change, check whether its author is the current user: compare the commit author against `git config user.email`, and the PR author against `gh api user --jq .login`. If they match, assume the work was done by a coding agent on the user's behalf - even without a `Co-Authored-By` trailer or any other sign of agentic coding. Authorship on record does not mean the user knows the change.

- Never skip or compress material because "the user wrote this" - they didn't. The whole point is explaining what their agent did.
- Commit messages and the PR body were written by the agent. They record what the agent *decided*, not necessarily what the user *asked for*. Where the two might diverge, flag it on the page.
- "Ask the author" is a dead end for implementation decisions - point wisdom questions at reviewers and the owning team instead.

## Grounding

Never trust your parametric knowledge about the topic. Ground every claim in the code, the messages, the discussion, the primary source, or the repo's conventions files - and cite it (link to the commit, the PR, the specific review thread, the spec section).

Always establish the motivation before walking the mechanism - a mechanism without its "why" is noise. The order of primary sources for "why": linked issue → PR body → commit messages → review discussion (which often reveals the *rejected* alternatives, the sharpest form of "why").

Never fabricate motivation the sources don't contain - say plainly on the page when the "why" is undocumented, and name who would know (a reviewer, the owning team, the spec authors).

## Carrying the Idea Visually

Prose is the slowest way to convey a shape. For each mechanism, ask which form carries it fastest, then use that form:

- **Pseudocode** for logic and algorithms - the decision, not the syntax.
- **A call tree** for runtime control flow.
- **A shallow file tree** for responsibility and layering, one comment per entry.
- **A component tree** for UI structure, including the state and module boundaries that matter.
- **A Mermaid sequence or flow diagram** for interaction across components or services.
- **A diff** when the point is what changed and the surrounding shape already exists. Match the diff's shape to the topic: diff the file tree for a layout change, the call tree for a flow change, the pseudocode for a logic change.
- **A real code block** only when most of it is new, or when omitting the context would hide ownership or order.

Two rules govern all of them. Keep only the calls, files, props, states, and boundaries that answer the question at hand - a complete diagram is a failed diagram. And place each visual next to the short text it supports, never in a gallery at the end.

You will use one or two of these forms. You will not use all of them.

## The Page

One self-contained HTML file - all CSS inline, no external assets, no links to other generated pages. Write it to `~/.claude/.explain/`, named `<slug>.html`, where the slug identifies the topic (`data-ingestion-pr7959.html`, `metis-metricsreporter.html`, `oauth-pkce.html`). Never write anything to the user's repository or current working directory. Open the file for the user with a CLI command (`open` on macOS).

The reader is a technical person fluent in reading code. Be terse: no pedagogy, no exercises, no padding, no restating what a competent engineer sees in the code. Spend the words on what the code *doesn't* say - motivation, rejected alternatives, non-obvious mechanisms, convention context.

Structure:

- **Header**: title, linked ref (commit, PR, path, or primary source), and for a change: author, date, merge state.
- **TL;DR**: two or three sentences - the whole page in miniature.
- **Why**: the motivation and the decisions, quoting the exact commit message lines, PR body excerpts, review comments, or spec passages that back each claim, linked to their source. Include rejected alternatives when the sources record them.
- **How**: the shape first (the file tree, the `--stat`, the top-level flow), then the key mechanisms in the order a reader needs them. Each mechanism gets the visual form that carries it and a line of prose. Call out the non-obvious parts and how repo conventions shaped them.
- **Sources**: the primary source, the commit(s), the PR, the sharpest review threads, linked issues - and any open questions with who to ask.

The page should be **beautiful** - clean, readable typography, prints well. Think Tufte. But brevity beats completeness: a small topic deserves a short page. Never pad.

## The Slop Pass

Before you write the file, run the drafted prose through the `no-ai-slop` skill in its Edit mode. It normally asks the writer who the piece is for - answer up front so it does not stall: the audience is a technical reader fluent in code, the format is this one-pager, and the reader should close it able to reason about the subject.

It catches what this page leaks most: throat-clearing, hedges, abstraction standing where a mechanism belongs, and sentences that would survive unchanged on a page about a different subject. Cut rather than smooth - a shorter page is the correct outcome.

The voice to preserve is the sources' own. Keep every quoted commit message, review comment, and spec passage verbatim. Never run the pass over code, diffs, diagrams, or identifiers.

## After the Page

The page is the deliverable. Stop there unless one of these applies.

**A follow-up question about one mechanism** - "how does the retry loop work?", "what calls this?" Answer in the conversation with the visual forms above. Never regenerate the page for a single question.

**The user needs to own the topic**, not understand it once - they will review, debug, or extend it repeatedly, and one page cannot build retention. This is the case `explain` deliberately does not serve. Say so in one line and offer the full `teach` skill. Do not start teaching in this session.

Seed the workspace before handing over, in the formats `teach` defines: write `~/.claude/teaching/<slug>/MISSION.md` and `RESOURCES.md` from what the gathering pass already found - the real goal, the canonical files, the repo conventions, the primary sources. Then tell the user the directory to `cd` into, since `teach` treats the current directory as its workspace.

If a workspace for that topic already exists, add to its `RESOURCES.md` instead of creating a second one.
