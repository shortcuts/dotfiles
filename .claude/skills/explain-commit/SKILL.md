---
name: explain-commit
description: Explain the why and how of a git commit or pull request as a single, terse HTML page.
disable-model-invocation: true
argument-hint: "Commit hash, or GitHub commit/PR URL"
---

The user has asked you to explain a specific code change - a commit or a pull request. Produce **one self-contained HTML page** that a technical reader can absorb in a few minutes:

- **Why** the change was made: the motivation, the decisions taken, the alternatives rejected.
- **How** it was implemented: the architecture of the diff, the key mechanisms, the non-obvious parts.

This is a stateless, one-shot request. No workspace, no lessons, no quizzes, no follow-up questions embedded in the page. Gather, explain, write the page, open it, done.

## Resolving the Input

The user provides one of three forms:

1. **A bare commit hash** (e.g. `6cffe7f91690e53b634efc260be829cad47b5de9`) - a commit of the repository in the current directory.
2. **A GitHub commit URL** (e.g. `https://github.com/algolia/data-ingestion/commit/d208b89...`) - a commit of that remote repository.
3. **A GitHub PR URL** (e.g. `https://github.com/algolia/data-ingestion/pull/7959`) - the full pull request: all commits, the PR body, and the review discussion.

If the input matches none of these, ask the user for one before doing anything else. That is the only question you may ask.

## Gathering the Source Material

You may use `git` and `gh` **read operations only**. Never perform any write operation (no push, no comments, no reviews, no labels) - you are a reader of this history, not a participant.

The diff alone is half the story. Commit messages, the PR body, and review discussions are where the *decisions* live - why this approach, what was pushed back on, what was deferred. Always gather them.

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

Also chase references: linked issues in the PR body (`Fixes #123`), design docs, earlier PRs mentioned in discussion. Fetch them with `gh api` / `gh issue view` when they carry motivation. When the change touches code you can read locally, read the surrounding files - a diff only makes sense against the code it lands in.

### Repository conventions

Read the repository's `AGENTS.md` and `CLAUDE.md` (root and any in the directories the diff touches) when they exist - locally, or via `gh api repos/OWNER/REPO/contents/...` for remote changes. They encode the conventions and architecture the change was written against, and often explain choices the diff can't: why this layer, why this naming, why this test shape. Use them to interpret the change; cite them when they explain a decision.

### Agent-authored changes

While gathering, check whether the change's author is the current user: compare the commit author against `git config user.email`, and the PR author against `gh api user --jq .login`. If they match, assume the work was done by a coding agent on the user's behalf - even without a `Co-Authored-By` trailer or any other sign of agentic coding. Authorship on record does not mean the user knows the change.

- Never skip or compress material because "the user wrote this" - they didn't. The whole point is explaining what their agent did.
- Commit messages and the PR body were written by the agent. They record what the agent *decided*, not necessarily what the user *asked for*. Where the two might diverge, flag it on the page.
- "Ask the author" is a dead end for implementation decisions - point wisdom questions at reviewers and the owning team instead.

## Grounding

Never trust your parametric knowledge about what the change does. Ground every claim in the diff, the messages, the discussion, or the repo's conventions files - and cite them (link to the commit, the PR, the specific review thread).

Always establish the motivation before walking the implementation - a diff without its "why" is noise. The order of primary sources for "why": linked issue → PR body → commit messages → review discussion (which often reveals the *rejected* alternatives, the sharpest form of "why").

Never fabricate motivation the sources don't contain - say plainly on the page when the "why" is undocumented, and name who would know (a reviewer, the owning team).

## The Page

One self-contained HTML file - all CSS inline, no external assets, no links to other generated pages. Write it to `~/.claude/.explain-commit/`, named `<repo>-<short-ref>.html` (e.g. `data-ingestion-pr7959.html`). Never write anything to the user's repository or current working directory. Open the file for the user with a CLI command (`open` on macOS).

The reader is a technical person fluent in reading code. Be terse: no pedagogy, no exercises, no padding, no restating what a competent engineer sees in the diff. Spend the words on what the diff *doesn't* say - motivation, rejected alternatives, non-obvious mechanisms, convention context.

Structure:

- **Header**: title, linked ref (commit/PR), author, date, merge state.
- **TL;DR**: two or three sentences - what changed and why, the whole page in miniature.
- **Why**: the motivation and the decisions, quoting the exact commit message lines, PR body excerpts, or review comments that back each claim, linked to their source. Include rejected alternatives when the discussion records them.
- **How**: the shape of the change (from `--stat`), then the key mechanisms. Slice the diff - show only the hunks that carry the idea, rendered as diffs (added/removed styling), never the full patch. Call out the non-obvious parts and how repo conventions (AGENTS.md / CLAUDE.md) shaped them.
- **Sources**: the commit(s), the PR, the sharpest review threads, linked issues - and any open questions with who to ask.

The page should be **beautiful** - clean, readable typography, prints well. Think Tufte. But brevity beats completeness: a small commit deserves a short page. Never pad.
