# When the subject is code, a commit, a PR, or a path

Use `git` and `gh` read operations only. Any write - push, comment, review, label - makes
you a participant in a history you are here to read.

The artifact is half the story. Commit messages, PR bodies, and review discussions hold
the decisions: why this approach, what reviewers pushed back on, what the author
deferred. Gather them every time.

The non-obvious calls:

```bash
gh api repos/OWNER/REPO/commits/SHA/pulls   # the PR a commit landed through
gh api repos/OWNER/REPO/pulls/N/comments    # inline review threads - decision gold
gh api repos/OWNER/REPO/issues/N/comments   # top-level PR discussion, a separate endpoint
git log -S<symbol>                          # when a mechanism first appeared
```

Chase every reference while you gather - each one becomes a link on the note. Issues
named in the PR body (`Fixes #123`). Tracker keys hiding in branch names, PR titles, and
commit subjects (`PROJ-1234` for Jira, `ENG-456` for Linear) -
`gh pr view --json title,body,headRefName,commits` surfaces all three at once. Design
docs, runbooks, dashboards, and earlier PRs the discussion names.

For code as it stands, read the code, then recover what it cannot state.
`git log --follow <path>` gives the commits that shaped it. Map the commits that matter
to their PRs with the `commits/SHA/pulls` call above: PR search matches text, not the
files a PR changed.

## Repository conventions

Read `AGENTS.md` and `CLAUDE.md` - the root ones, and any in the directories the topic
touches. Use `gh api repos/OWNER/REPO/contents/...` for a remote topic. They explain
choices the code cannot: why this layer, why this naming, why this test shape. Cite them
when they explain a decision.

## Changes the user's own agent wrote

Compare the commit author against `git config user.email`, and the PR author against
`gh api user --jq .login`. A match means a coding agent probably did the work for the
user, even with no `Co-Authored-By` trailer. Authorship on record does not mean the user
knows the change.

- Explain the change at full depth. "The user wrote this" is false here - explaining what
  their agent did is the whole job.
- The agent also wrote the commit messages and the PR body. Those record what the agent
  decided, not what the user asked for. Flag on the note where the two might diverge.
- Point open questions at reviewers and the owning team. "Ask the author" is a dead end.
