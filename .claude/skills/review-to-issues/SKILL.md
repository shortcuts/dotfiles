---
name: review-to-issues
description: |
  Run a thermo-nuclear code quality review over a given scope (commit hash, PR,
  directory, or a natural-language range like "last commits since yesterday") and
  log every finding as a structured entry in ISSUES.md. Use whenever the user invokes
  /review-to-issues, or asks to "review and log to issues", "audit this commit/PR/
  directory and file issues", "turn this review into a backlog", or wants thermo-nuclear
  findings persisted instead of just printed to the terminal.
---

# Review to Issues

Run the `/thermo-nuclear` code quality review against a caller-specified scope, then
persist every finding as a structured entry in `ISSUES.md` instead of only printing it
to the terminal. This turns a one-off strict review into a durable backlog that
`issues-orchestrator` (or a human) can work through later.

## Step 1: Resolve the scope argument

The user passes one argument, which can be any of:

- **A commit hash** (e.g. `a1b2c3d`) — review that single commit's changes:
  `git show <hash>` / `git diff <hash>^..<hash>`.
- **A PR reference** (e.g. `#123`, `123`, or a GitHub PR URL) — resolve via
  `gh pr diff <number>` (add `--repo <owner>/<repo>` if the URL points elsewhere than
  the current repo's remote).
- **A directory path** — review the current state of everything under that path (not a
  diff — read the files as they stand today).
- **A natural-language range** (e.g. `"last commits since yesterday"`,
  `"commits since Monday"`, `"the last 5 commits"`) — translate into a concrete
  `git log` / `git diff` invocation, e.g. `git log --since=yesterday --oneline` then
  `git diff <oldest-of-those>^..HEAD`.
- **No argument** — default to the working branch's diff against its base
  (`git merge-base main HEAD` or `master`, whichever exists), same default `/code-review`
  would use.

If the argument is ambiguous (e.g. it could be a commit hash or could be a directory
name, or a PR number doesn't resolve via `gh`), ask the user rather than guessing.

State the resolved scope back in one line before proceeding, e.g.:
`Scope: commit a1b2c3d` or `Scope: PR #123 (algolia/foo)` or `Scope: directory src/auth/`.

## Step 2: Determine where ISSUES.md lives

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ -n "$REPO_ROOT" ] && [ -d "$REPO_ROOT/.claude" ]; then
  ISSUES_FILE="$REPO_ROOT/.claude/ISSUES.md"
else
  ISSUES_FILE="$HOME/.claude/ISSUES.md"
fi
```

- Prefer `<repo-root>/.claude/ISSUES.md` when the current repo has a `.claude` directory.
- Fall back to `~/.claude/ISSUES.md` when there's no repo, or the repo has no `.claude`
  directory (don't create one — that's a project-structure decision, not this skill's
  call).
- Record the baseline line count (`wc -l "$ISSUES_FILE" 2>/dev/null || echo 0`) so you
  can report how many findings were net-new at the end.

## Step 3: Run the thermo-nuclear review

Invoke the `/thermo-nuclear` skill against the resolved scope from Step 1. Apply its
full standards: ambitious code-judo restructuring, 1k-line file smell, spaghetti
branching, boundary/type cleanliness, canonical-layer leaks, orchestration atomicity —
see that skill for the complete rubric. Don't water it down for this skill.

## Step 4: Log every finding to ISSUES.md

For each finding the review surfaces, append an entry in this format (create the file
with a `# Issues` heading first if it doesn't exist yet):

```
## [Thermo-Nuclear Review] <short title>

**Scope:** <what was reviewed — commit hash / PR / directory / range from Step 1>
**Location:** <file path(s) and function/line if applicable>
**Finding:**
<the structural problem, stated the way the thermo-nuclear skill states it — direct,
specific, no hedging>
**Preferred remedy:**
<the concrete restructuring suggested — extract helper, delete wrapper, split file,
reframe state model, etc.>
```

Log every finding that clears the thermo-nuclear approval bar — don't filter down to
only the scariest one, but also don't pad the file with cosmetic nits the skill itself
wouldn't have raised. One entry per finding, appended in the order the review produced
them.

## Step 5: Report back

Tell the user:

- The resolved scope reviewed.
- How many findings were logged (net-new lines/entries vs. the Step 2 baseline).
- The path to `ISSUES.md` that was written.
- If zero findings: say clearly that the review passed the thermo-nuclear approval bar
  with no logged issues — don't write an empty entry just to prove the skill ran.
