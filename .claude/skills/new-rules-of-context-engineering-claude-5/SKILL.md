---
name: new-rules-of-context-engineering-claude-5
description: Audit and rewrite agentic context files (CLAUDE.md, AGENTS.md, SKILL.md files, agent instruction docs) to follow Anthropic's Claude 5 context engineering rules — replace rigid rules with judgment-enabling guidance, remove redundant constraints, deduplicate across files, and apply progressive disclosure. Use whenever the user wants to modernize, audit, slim down, "unhobble", or right-size CLAUDE.md files, skills, system prompts, or a docs/ directory of agent instructions — even if they just say "clean up my agent files", "my CLAUDE.md is bloated", or "apply the new context engineering rules".
---

# New Rules of Context Engineering (Claude 5)

Apply Anthropic's Claude 5 context engineering principles to a scope of
agentic files. The philosophy shift: from "constrain the model to prevent
failure" to "design context the model can intelligently navigate". Claude 5
models need fewer constraints — Anthropic cut over 80% of Claude Code's own
system prompt with no performance loss.

Read `references/principles.md` before editing anything. It contains the six
shifts, the per-file-type guidance, and the audit checklist you apply to each
file.

## Step 1: Resolve the scope

The user gives a scope: a single file, a directory, or a whole repo. Find the
agentic files in it — files written to instruct an AI agent, not humans:

- `CLAUDE.md`, `AGENTS.md`, `.cursorrules`, `.github/copilot-instructions.md`
- `SKILL.md` and skill reference files under `.claude/skills/` or `skills/`
- Agent/subagent definitions (`.claude/agents/*.md`)
- Files in a given `docs/` scope that are addressed to an agent (say "you",
  give the agent instructions). Leave human-facing docs (README,
  CONTRIBUTING, API docs) alone unless the user includes them explicitly.

List the files you found and their line counts before editing. If the scope
is ambiguous (e.g. a docs/ directory that mixes human and agent docs), state
which files you will treat as agentic and why, then proceed.

## Step 2: Audit and rewrite each file

For each file, one at a time:

1. Read the whole file.
2. Run the audit checklist from `references/principles.md` against it.
3. Rewrite with Edit — surgical changes, preserve the file's structure and
   voice where it isn't the problem.
4. Record what you changed and which principle drove each change.

Two rules that override everything else:

- **Preserve hard-won knowledge.** Gotchas, invariants, bug workarounds, and
  non-obvious constraints are exactly what these files exist for. When a rigid
  rule looks like it encodes a real lesson ("NEVER call X before Y" probably
  came from an outage), soften it into judgment guidance with the why — do
  not delete it. When you can't tell whether a rule is load-bearing, keep it
  and flag it in the report instead of guessing.
- **Cut only what the model can recover elsewhere.** Safe to remove: facts
  discoverable from file structure, restated tool documentation, duplicated
  instructions, generic best practices the model already knows. Not safe:
  anything project-specific with no other source.

## Step 3: Cross-file pass

After the per-file edits, look across the scope as a whole:

- Same instruction in two files → keep the single authoritative location
  (tool guidance in tool/skill descriptions, repo gotchas in CLAUDE.md),
  delete or link the other.
- Conflicting guidance between files → resolve to one, note the conflict in
  the report.
- Large monolithic files (>~300 lines of instructions) → split into a lean
  entry file plus referenced subfiles, with clear pointers on when to read
  each (progressive disclosure).

## Step 4: Report

End with a summary the user can review:

```
## Context engineering audit: <scope>

| File | Before | After | Main changes |
|------|--------|-------|--------------|
| CLAUDE.md | 210 lines | 85 lines | rules→judgment (3), removed obvious repo facts, split verify steps to skill |

### Flagged for your review
- <rule kept because it may be load-bearing, with file:line>

### Conflicts resolved
- <what conflicted, what won>
```

Line counts approximate token savings well enough; don't compute exact
tokens. The "Flagged" section matters most — it is where you hand judgment
calls back to the user instead of silently deleting their guardrails.
