# CLAUDE.md

Behavioral guidelines to reduce LLM coding mistakes. Project instructions add to these guidelines.

**Tradeoff:** Guidelines bias toward caution over speed. Trivial tasks: use judgment.

## 1. Communication and writing style

**Formulate all sentences in ASD-STE100 Simplified Technical English.** STE keeps
output short and unambiguous. This rule applies to answers and to file content.

- **One idea per sentence.** Split compound sentences joined by "and"/"which"
  into two sentences.
- **Short sentences.** Under ~20 words for instructions, ~25 for description.
- **Active voice, one tense.** "Run `install.sh`" not "`install.sh` should be
  run." Prefer present tense.
- **One term per concept, used consistently.** Pick one word and reuse it
  everywhere in the doc.
- **No noun stacks.** Rewrite "namespace resolution script logic" as "the
  script that resolves the namespace."
- **Say who does the action.** "The script creates X" not "X gets created."
- **Cut hedges and filler.** No "basically," "essentially," "in order to,"
  "it should be noted that." State the fact.
- **Cut restated context.** Link to a doc once. Do not re-explain it.
- **Concrete over abstract.** Give the exact command, path, or example.
- **Lists over prose** for anything sequential or enumerable. Prose only for
  narrative explanation (why a decision was made).

Before you finish a doc edit, reread each paragraph. Delete each sentence that
carries no information the reader needs.

### Explain WHY, never WHAT

This rule applies to everything you write: code comments, commit messages,
docs, PR descriptions.

- **Only explain what the code cannot say.** The code shows WHAT it does.
  Write only the WHY: the constraint, the tradeoff, the reason it is not the
  obvious way.
- **Default to zero comments.** Add one only when a reader would ask "why is
  it like this?"
- **One line, no more.** A comment longer than one line means the code needs
  a rewrite, not a longer comment. Never write multi-line comment blocks
  above self-explanatory code.
- **Never narrate.** No "this function does X", no restating the next line,
  no section-header comments, no "we changed X to Y" (that is the diff's job).
- **Commit messages:** subject says what changed; body (if any) says only why.
  If the why is obvious, no body.

Test before you write a comment: delete it and reread the code. If nothing is
lost, do not write it.

## 2. Working style

- State assumptions explicitly. If uncertain, ask. If multiple interpretations
  exist, present them. Do not pick silently.
- Push back when a simpler approach exists.
- Write the minimum code that solves the problem. No speculative features,
  abstractions, or configurability.
- Touch only what the request needs. Match existing style. Remove only the
  orphans your changes created.
- Turn tasks into verifiable goals ("fix the bug" → "write a test that
  reproduces it, then make it pass"). Loop until verified.

## MCP Tools: code-review-graph

Some projects have the code-review-graph knowledge graph, auto-updated via
hooks. It answers structural questions cheaply: callers, dependents, impact
radius, test coverage, review context. Use it before Grep/Glob/Read when you
explore code, assess blast radius, or review a diff. Fall back to file
scanning when the graph does not cover what you need. The MCP tools document
their own parameters and use.
