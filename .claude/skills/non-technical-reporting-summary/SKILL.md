---
name: non-technical-reporting-summary
description: Summarize a PR or branch into a concise, non-technical notebook entry with "What we did" and "Expected outcome" sections. Aimed at engineering managers and executives. Use when the user wants a PR summary, branch summary, notebook entry, exec summary, or non-technical report.
---

# Non-Technical Reporting Summary

Produce a concise summary of the current branch or PR suitable for engineering managers and senior leadership. The audience is non-technical — they care about *what changed and why it matters*, not how it was implemented.

## Gathering Context

1. Run `git branch --show-current` to identify the branch.
2. Run `gh pr view --json title,body,url` to get the PR description and link.
3. Run `git merge-base HEAD main` then `git log --oneline <base>..HEAD` and `git diff --stat <base>..HEAD` to understand the scope of changes.
4. Read the changed files only if the PR description and diff stat are not enough to understand intent.

## Output Format

Produce exactly this structure:

```
**PR**: [<PR title>](<PR URL>)

**What we did**: <1-3 sentences. Plain language. Describe the change in terms of what it does for the team, the product, or the process — not how it works internally. No file names, no tool names, no technical jargon unless the audience would know the term.>

**Expected outcome**: <1-3 sentences. What improves, what risk is reduced, what becomes possible next. Concrete when possible (e.g. "cutting CI time by ~X%") but honest when speculative (e.g. "once validated, will allow us to...").>
```

## Rules

- **No technical jargon**: no file paths, no framework names, no CLI commands, no code concepts. If a technical term is unavoidable (e.g. "CI"), it must be one the audience already knows.
- **No implementation details**: don't explain *how* it works. Explain *what* it achieves.
- **Concise**: each section is 1-3 sentences. Brevity is a feature.
- **Honest about certainty**: distinguish between "this does X" and "this will enable X once validated".
- **One entry per PR**: don't split into multiple summaries.
- **Match the user's voice**: if the user's prior entries use a specific tone or phrasing style, mirror it.
