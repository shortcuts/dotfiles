<!-- User customizations (migrated from previous CLAUDE.md) -->
@RTK.md

# CLAUDE.md

Behavioral guidelines to reduce LLM coding mistakes. Merge with project-specific instructions as needed.

**Tradeoff:** Guidelines bias toward caution over speed. Trivial tasks: use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State assumptions explicitly. Uncertain: ask.
- Multiple interpretations exist: present them, don't pick silently.
- Simpler approach exists: say so. Push back when warranted.
- Unclear: stop. Name what's confusing. Ask.

## 2. Simplicity First

**Minimum code that solves problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No unrequested "flexibility" or "configurability".
- No error handling for impossible scenarios.
- 200 lines when 50 works: rewrite.

Ask: "Would senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

Editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- Unrelated dead code: mention it, don't delete.

Your changes create orphans:
- Remove imports/variables/functions YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

Test: every changed line traces directly to user's request.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

Multi-step tasks, state brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria: loop independently. Weak criteria ("make it work"): constant clarification.

---

<!-- code-review-graph MCP tools -->
## MCP Tools: code-review-graph

**IMPORTANT: Project has knowledge graph. ALWAYS use code-review-graph MCP tools BEFORE Grep/Glob/Read.** Graph faster, cheaper (fewer tokens), gives structural context (callers, dependents, test coverage) file scanning can't.

### When to use graph tools FIRST

- **Exploring code**: `semantic_search_nodes` or `query_graph` instead of Grep
- **Understanding impact**: `get_impact_radius` instead of manually tracing imports
- **Code review**: `detect_changes` + `get_review_context` instead of reading entire files
- **Finding relationships**: `query_graph` with callers_of/callees_of/imports_of/tests_for
- **Architecture questions**: `get_architecture_overview` + `list_communities`

Fall back to Grep/Glob/Read **only** when graph doesn't cover what you need.

### Key Tools

| Tool | Use when |
|------|----------|
| `detect_changes` | Reviewing code changes — gives risk-scored analysis |
| `get_review_context` | Need source snippets for review — token-efficient |
| `get_impact_radius` | Understanding blast radius of a change |
| `get_affected_flows` | Finding which execution paths are impacted |
| `query_graph` | Tracing callers, callees, imports, tests, dependencies |
| `semantic_search_nodes` | Finding functions/classes by name or keyword |
| `get_architecture_overview` | Understanding high-level codebase structure |
| `refactor_tool` | Planning renames, finding dead code |

### Workflow

1. Graph auto-updates on file changes (via hooks).
2. Use `detect_changes` for code review.
3. Use `get_affected_flows` to understand impact.
4. Use `query_graph` pattern="tests_for" to check coverage.

---

## Writing Docs: ASD-STE100 Simplified Technical English

**Applies to:** README, CONTRIBUTING, CHANGELOG, architecture docs, agent/skill
instruction files — any `*.md` meant to be read or followed. Not code comments
(see below) and not this file's own style.

STE100 is controlled English, not telegraphic shorthand. Keep full grammar
(articles, verb endings) — cut length and ambiguity, not words.

- **One idea per sentence.** Split compound sentences joined by "and"/"which"
  into two sentences.
- **Short sentences.** Under ~20 words for instructions, ~25 for description.
- **Active voice, one tense.** "Run `install.sh`" not "`install.sh` should be
  run." Prefer present tense.
- **One term per concept, used consistently.** Don't alternate between
  "backlog" and "issue list" and "task queue" for the same thing. Pick one
  word and reuse it everywhere in the doc.
- **No noun stacks.** Rewrite "namespace resolution script logic" as "the
  script that resolves the namespace."
- **Say who does the action.** "The script creates X" not "X gets created."
- **Cut hedges and filler.** No "basically," "essentially," "in order to,"
  "it should be noted that." State the fact.
- **Cut restated context.** Don't re-explain what a linked doc already covers
  — link to it once.
- **Concrete over abstract.** Give the exact command, path, or example instead
  of a general description of one.
- **Lists over prose** for anything sequential or enumerable. Prose only for
  narrative explanation (why a decision was made).

Before finishing a doc edit, reread each paragraph and ask: does every
sentence carry information the reader needs? Delete the ones that don't.

## Code Comments

- Default: no comment. Names and structure should carry the meaning.
- Add a comment only for the **why** — a constraint, a bug workaround, a
  non-obvious invariant — never the **what** (that's what the code already
  shows).
- One line. If it needs a paragraph, the code is the problem, not the
  comment.

