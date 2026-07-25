# Claude 5 Context Engineering Principles

Source: Anthropic, "The New Rules of Context Engineering for Claude 5
Generation Models" (claude.com/blog).

Core insight: Claude 5 generation models (Fable 5, Opus 5) need fewer
constraints and apply judgment from surrounding context. Anthropic removed
over 80% of Claude Code's system prompt for these models without performance
degradation. Old-style prompts also tend to accumulate *conflicting*
directives ("leave documentation as appropriate" next to "DO NOT add
comments") — older models needed the redundancy, Claude 5 models are hurt by
the noise.

## The six shifts

### 1. Rules → Judgment

Rigid prescriptive rules become contextual guidance that explains intent.

- Before: "In code: default to writing no comments. Never write
  multi-paragraph docstrings — one short line max."
- After: "Write code that reads like the surrounding code: match its comment
  density, naming, and idiom."

Rewrite pattern: when you see ALWAYS/NEVER/MUST in caps, or a rule with no
stated reason, either (a) replace with guidance that states the goal and lets
the model judge, or (b) if the rule encodes a real constraint, keep the
constraint but add the why. A rule with its reason attached survives edge
cases; a bare rule gets misapplied.

### 2. Examples → Interface design

Usage examples for tools constrain exploration. Well-designed interfaces
(descriptive parameter names, enums that show valid states like
`pending | in_progress | completed`) guide usage naturally.

Rewrite pattern: in tool/skill definitions, cut walls of example calls when
the parameter schema already communicates the same thing. Keep examples only
where the interface genuinely can't express the subtlety (output format
conventions, tricky edge cases).

### 3. Upfront context → Progressive disclosure

Don't load everything into the primary file. Load context when needed:

- Move detailed procedures out of CLAUDE.md into skills that trigger when
  relevant.
- Split long skills into a lean SKILL.md plus reference files, with clear
  pointers on when to read each.
- Keep the always-loaded layer (CLAUDE.md, skill descriptions) small; let
  the model pull depth on demand.

### 4. Repetition → Single-source tool descriptions

Instructions repeated in both a system prompt/CLAUDE.md and a tool or skill
description should live in exactly one place — the tool description. Claude 5
models retain and apply information reliably from its specific location;
duplication adds tokens and drift risk, not reliability.

Rewrite pattern: when CLAUDE.md re-explains how to use a tool, MCP server, or
skill that already documents itself, delete the CLAUDE.md copy (keep at most
a one-line pointer).

### 5. Manual memory → Automatic memory

Claude 5 saves contextually relevant memories itself. Instructions telling
the model (or user) to manually maintain memory files via hotkeys or rituals
are obsolete — remove them unless the project has a bespoke memory system the
model can't discover.

### 6. Plain specs → Rich references

Plain-markdown requirement descriptions are the weakest reference format.
Prefer, and recommend converting to:

- Actual code implementations to port or match
- HTML mockups/artifacts instead of prose UI descriptions
- Test suites that define expected behavior
- Rubrics encoding taste/standards (usable by verification agents)

Rewrite pattern: when an agent doc describes behavior that a test, mockup, or
reference implementation in the repo already defines, replace the prose with
a pointer to the artifact.

## Per-file-type guidance

**CLAUDE.md / AGENTS.md**: lightweight and brief about repo purpose. Spend
the token budget on gotchas and non-obvious constraints ("types live only in
monolithic file X"). Remove anything discoverable from file structure or
obviously true. Reference skills for procedures instead of embedding them.

**Skills (SKILL.md)**: lightweight guides that trigger when relevant. Avoid
over-constraining except in genuinely critical domains. Encode team/product
opinions. Split long skills across files with cross-references.

**System prompts (custom harnesses)**: tie to the product environment and the
agent's role — what product it operates in, what its responsibilities are.
This is the main investment area for custom agents; for standard Claude Code
use, leave it alone.

**References/@mentions**: prefer code-based references — mockups over
descriptions, implementations over screenshots.

## Audit checklist (run per file)

1. **Conflicts**: directives that contradict each other in this file or
   across the scope. Resolve to one.
2. **Bare rigid rules**: ALWAYS/NEVER/MUST without a reason. Convert to
   judgment guidance or attach the why (shift 1).
3. **Redundant tool instructions**: guidance duplicating what a tool, MCP
   server, or skill already says about itself (shift 4). Delete, leave a
   pointer at most.
4. **Obvious statements**: facts the model can discover from the repo
   (directory layout, language, framework) or already knows (generic best
   practices). Delete (per-file guidance above).
5. **Embedded procedures**: multi-step workflows inlined in an always-loaded
   file. Move to a skill or reference file (shift 3).
6. **Oversized files**: >~300 instruction lines. Split with progressive
   disclosure (shift 3).
7. **Manual memory rituals**: instructions to hand-maintain memory files
   (shift 5). Remove.
8. **Prose specs with better artifacts available**: behavior described in
   prose that a test/mockup/implementation already defines (shift 6). Point
   to the artifact.
9. **Example walls**: long example lists where an interface or schema already
   communicates the pattern (shift 2). Trim to the non-obvious cases.

For every cut, apply the two override rules from SKILL.md: preserve hard-won
knowledge, and cut only what the model can recover elsewhere.
