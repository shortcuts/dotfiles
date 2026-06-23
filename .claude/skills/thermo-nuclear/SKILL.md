---
name: thermo-nuclear-code-quality-review
description: Run an extremely strict maintainability review for abstraction quality, giant files, and spaghetti-condition growth. Use for a thermo-nuclear code quality review, thermonuclear review, deep code quality audit, or especially harsh maintainability review.
disable-model-invocation: true
---

# Thermo-Nuclear Code Quality Review

Use this skill for an unusually strict review focused on implementation quality, maintainability, abstraction quality, and codebase health.

Above all, this skill should push the reviewer to be **ambitious** about code structure. Do not merely identify local cleanup opportunities. Actively search for "code judo" moves: restructurings that preserve behavior while making the implementation dramatically simpler, smaller, more direct, and more elegant.

## Scope Resolution

This review can target three scopes. Determine scope from the user's invocation:

| Signal | Scope | What to review |
|--------|-------|----------------|
| User provides a file or directory path (e.g. `src/auth/`, `lib/utils.ts`) | **Path** | All source files under that path |
| User mentions a PR, branch, diff, or "changes" — or invokes with no argument while on a non-default branch | **PR** | Files changed on the current branch vs its merge base |
| User says "codebase", "everything", "all", "repo", or provides `.` or the project root | **Codebase** | All source files in the project |

### Gathering the review surface

**Path scope**: Read all source files under the given path. Ignore build artifacts, `node_modules`, generated files, lockfiles. If the path is a single file, review that file in full.

**PR scope**: Run `git diff --name-only $(git merge-base HEAD main)..HEAD` (adjust base branch as needed). Read the changed files. Use `git diff` to understand what changed vs what was already there.

**Codebase scope**: Identify all source directories. Review systematically — module by module, package by package. Prioritize by size and complexity (largest and most-imported files first). Skip vendored, generated, and config-only files.

### Framing

- **Path / Codebase scope**: You are reviewing **the current state of the code**. Ask "does this code have problem X?" — not "did a change introduce X?"
- **PR scope**: You are reviewing **a delta**. Ask "did this change introduce problem X?" and "did this change miss an opportunity to fix existing problem Y in code it touched?"

Use **"the code under review"** as the neutral term throughout. The quality bar is identical regardless of scope.

## Core Prompt

Start from this baseline, adapted to scope:

**PR scope:**
> Perform a deep code quality audit of the current branch's changes.
> Rethink how to structure / implement the changes to meaningfully improve code quality without impacting behavior.

**Path scope:**
> Perform a deep code quality audit of every source file under the given path.
> Identify structural problems, missed simplifications, and maintainability debt in the code as it stands today.

**Codebase scope:**
> Perform a deep code quality audit of the entire codebase.
> Identify the highest-impact structural problems, missed simplifications, and maintainability debt across the project.

**All scopes:**
> Work to improve abstractions, modularity, reduce spaghetti code, improve succinctness and legibility.
> Be ambitious — if there is a clear path to improving the implementation that involves restructuring, go for it.
> Be extremely thorough and rigorous. Measure twice, cut once.

## Non-Negotiable Additional Standards

Apply the baseline prompt above, plus these explicit review rules:

0. **Be ambitious about structural simplification.**
   - Do not stop at "this could be a bit cleaner."
   - Look for opportunities to reframe the code so that whole branches, helpers, modes, conditionals, or layers disappear entirely.
   - Prefer the solution that makes the code feel inevitable in hindsight.
   - Assume there is often a "code judo" move available: a re-organization that uses the existing architecture more effectively and makes the code dramatically simpler and more elegant.
   - If you see a path to delete complexity rather than rearrange it, push hard for that path.

1. **Do not accept files over 1,000 lines without a very strong reason.**
   - Treat this as a strong code-quality smell by default.
   - Prefer extracting helpers, subcomponents, modules, or local abstractions instead of letting a file sprawl past 1,000 lines.
   - **PR scope**: If the diff pushes a file across that threshold, explicitly call it out and ask whether the code should be decomposed first.
   - **Path / Codebase scope**: Flag every file over 1,000 lines. Recommend concrete decomposition.
   - Only waive this if there is a compelling structural reason and the resulting file is still clearly organized.

2. **Do not allow random spaghetti in the code.**
   - Be highly suspicious of ad-hoc conditionals, scattered special cases, or one-off branches inserted into unrelated flows.
   - If the code has "weird if statements in random places", treat that as a design problem, not a stylistic nit.
   - Prefer pushing the logic into a dedicated abstraction, helper, state machine, policy object, or separate module instead of tangling an existing path.
   - Call out code that makes the surrounding logic harder to reason about, even if it technically works.

3. **Bias toward cleaning the design, not just accepting working code.**
   - If behavior can stay the same while the structure becomes meaningfully cleaner, push for the cleaner version.
   - Do not rubber-stamp "it works" implementations that leave the codebase messier.
   - Strongly prefer simplifications that remove moving pieces altogether over refactors that merely spread the same complexity around.

4. **Prefer direct, boring, maintainable code over hacky or magical code.**
   - Treat brittle, ad-hoc, or "magic" behavior as a code-quality problem.
   - Be skeptical of generic mechanisms that hide simple data-shape assumptions.
   - Flag thin abstractions, identity wrappers, or pass-through helpers that add indirection without buying clarity.

5. **Push hard on type and boundary cleanliness when they affect maintainability.**
   - Question unnecessary optionality, `unknown`, `any`, or cast-heavy code when a clearer type boundary could exist.
   - Prefer explicit typed models or shared contracts over loosely-shaped ad-hoc objects.
   - If a branch relies on silent fallback to paper over an unclear invariant, ask whether the boundary should be made explicit instead.

6. **Keep logic in the canonical layer and reuse existing helpers.**
   - Call out feature logic leaking into shared paths or implementation details leaking through APIs.
   - Prefer existing canonical utilities/helpers over bespoke one-offs.
   - Push code toward the right package, service, or module instead of normalizing architectural drift.

7. **Treat unnecessary sequential orchestration and non-atomic updates as design smells when the cleaner structure is obvious.**
   - If independent work is serialized for no good reason, ask whether the flow should run in parallel instead.
   - If related updates can leave state half-applied, push for a more atomic structure.
   - Do not over-index on micro-optimizations, but do flag avoidable orchestration complexity that makes the implementation more brittle.

## Primary Review Questions

For every meaningful unit of code under review, ask:

- Is there a "code judo" move that would make this dramatically simpler?
- Can this code be reframed so fewer concepts, branches, or helper layers are needed?
- Does this improve or worsen the local architecture?
- Is there branching complexity where a better abstraction should exist?
- Has a previously cohesive module become more coupled, more stateful, or harder to scan?
- Is this logic living in the right file and layer?
- Has this file or component grown past a healthy size boundary?
- Are there repeated conditionals that signal a missing model or missing helper?
- Is the implementation direct and legible, or does it rely on special cases and incidental control flow?
- Is this abstraction actually earning its keep, or is it just a wrapper?
- Are there casts, optionality, or ad-hoc object shapes that obscure the real invariant?
- Is this logic living in the canonical layer, or are details leaking across a boundary?
- Is this orchestration more sequential or less atomic than it needs to be?

**PR scope — additionally ask:**
- Did this change introduce any of the above problems that were not there before?
- Did this change touch code with existing problems and miss the chance to fix them?

## What to Flag Aggressively

Escalate findings when you see:

- A complicated implementation where a cleaner reframing could delete whole categories of complexity.
- Refactors that move code around but fail to reduce the number of concepts a reader must hold in their head.
- Files over 1,000 lines — especially if parts could be split out. (**PR scope**: flag when the change pushed it across.)
- Conditionals bolted onto unrelated code paths.
- One-off booleans, nullable modes, or flags that complicate existing control flow.
- Feature-specific logic leaking into general-purpose modules.
- Generic "magic" handling that hides simple structure and makes the code harder to reason about.
- Thin wrappers or identity abstractions that add indirection without simplifying anything.
- Unnecessary casts, `any`, `unknown`, or optional params that muddy the real contract.
- Copy-pasted logic instead of extracted helpers.
- Narrow edge-case handling implemented in the middle of an already busy function.
- Refactors that technically pass tests but make the code less modular or less readable.
- "Temporary" branching that is likely to become permanent debt.
- Bespoke helpers where the codebase already has a canonical utility for the job.
- Logic added in the wrong layer/package when it should live somewhere more central.
- Sequential async flow where obviously independent work could stay simpler and clearer with parallel execution.
- Partial-update logic that leaves state less atomic than necessary.

## Preferred Remedies

When you identify a code-quality problem, prefer suggestions like:

- Delete a whole layer of indirection rather than polishing it.
- Reframe the state model so conditionals disappear instead of getting centralized.
- Change the ownership boundary so the feature becomes a natural extension of an existing abstraction.
- Turn special-case logic into a simpler default flow with fewer exceptions.
- Extract a helper or pure function.
- Split a large file into smaller focused modules.
- Move feature-specific logic behind a dedicated abstraction.
- Replace condition chains with a typed model or explicit dispatcher.
- Separate orchestration from business logic.
- Collapse duplicate branches into a single clearer flow.
- Delete wrappers that do not meaningfully clarify the API.
- Reuse the existing canonical helper instead of introducing a near-duplicate.
- Make type boundaries more explicit so the control flow gets simpler.
- Move the logic to the package/module/layer that already owns the concept.
- Parallelize independent work when that also simplifies the orchestration.
- Restructure related updates into a more atomic flow when partial state would be harder to reason about.

Do not be satisfied with "maybe rename this" feedback when the real issue is structural.
Do not be satisfied with a merely cleaner version of the same messy idea if there is a plausible path to a much simpler idea.

## Review Tone

Be direct, serious, and demanding about quality.
Do not be rude, but do not soften major maintainability issues into mild suggestions.
If the code is making the codebase messier, say so clearly.
If the implementation missed an opportunity for a dramatic simplification, say that clearly too.

Good phrases:

- `this file is past 1k lines. can we decompose before anything else?`
- `this adds another special-case branch into an already busy flow. can we move this behind its own abstraction?`
- `this works, but it makes the surrounding code more spaghetti. let's keep the behavior and restructure the implementation.`
- `this feels like feature logic leaking into a shared path. can we isolate it?`
- `this abstraction seems unnecessary. can we just keep the direct flow?`
- `why does this need a cast / optional here? can we make the boundary more explicit instead?`
- `this looks like a bespoke helper for something we already have elsewhere. can we reuse the canonical one?`
- `i think there's a code-judo move here that makes this much simpler. can we reframe this so these branches disappear?`
- `this refactor moves complexity around, but doesn't really delete it. is there a way to make the model itself simpler?`

## Output Expectations

Prioritize findings in this order:

1. Structural code-quality regressions (PR scope) or structural debt (path / codebase scope)
2. Missed opportunities for dramatic simplification / code-judo restructuring
3. Spaghetti / branching complexity
4. Boundary / abstraction / type-contract problems that make the code harder to reason about
5. File-size and decomposition concerns
6. Modularity and abstraction issues
7. Legibility and maintainability concerns

Do not flood the review with low-value nits if there are larger structural issues.
Prefer a smaller number of high-conviction comments over a long list of cosmetic notes.

## Approval Bar

Do not approve merely because behavior seems correct.
The bar for approval is:

- no clear structural regression (PR scope) or structural debt (path / codebase scope)
- no obvious missed opportunity to make the implementation dramatically simpler when such a path is visible
- no unjustified file-size explosion (any file over 1,000 lines without compelling reason)
- no obvious spaghetti from special-case branching
- no obviously hacky or magical abstraction that makes the code harder to reason about
- no unnecessary wrapper/cast/optionality churn obscuring the real design
- no clear architecture-boundary leak or avoidable canonical-helper duplication
- no missed opportunity for an obvious decomposition that would materially improve maintainability

Treat these as presumptive blockers unless clearly justified:

- the code under review preserves a lot of incidental complexity when there is a plausible code-judo move that would delete it
- a file is over 1,000 lines (PR scope: the change pushed it past; path / codebase scope: it exists today)
- ad-hoc branching that makes an existing flow more tangled
- a local problem solved by scattering feature checks across shared code
- an unnecessary abstraction, wrapper, or cast-heavy contract that makes the design more indirect
- a duplicated helper or logic in the wrong layer when there is a clear canonical home

If those conditions are not met, leave explicit, actionable feedback and push for a cleaner decomposition.
