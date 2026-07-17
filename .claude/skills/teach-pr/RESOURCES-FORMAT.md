# RESOURCES.md Format

`RESOURCES.md` is the curated set of primary sources for this change. Knowledge for lessons should be drawn from here, not from parametric guesses. Wisdom comes from the people listed here.

## Structure

```md
# {Change} Resources

## Primary sources

- [PR #7959: Add backpressure to task queue](https://github.com/algolia/data-ingestion/pull/7959)
  The change itself. Body explains the incident that motivated it. Use for: motivation, scope.
- [Review thread: batch size discussion](https://github.com/algolia/data-ingestion/pull/7959#discussion_r123456)
  Reviewer pushed back on unbounded batches; author explains the 512 limit. Use for: the "why" of the batching decision.
- Commit `d208b89` — "fix: drain queue before shutdown"
  Message documents the shutdown race. Use for: the drain logic lesson.
- [Issue #7801: ingestion OOM under burst load](https://github.com/algolia/data-ingestion/issues/7801)
  The incident that triggered this work. Use for: grounding the motivation lesson.

## Context

- [Design doc: ingestion pipeline v2](https://example.com)
  Broader architecture this change fits into. Use for: situating the change.
- `services/queue/worker.go` (local checkout)
  The code the diff lands in. Use for: reading changes in context.

## Wisdom (People)

- @author-handle — wrote the PR. Ask about: alternatives considered before the queue approach.
- @reviewer-handle — raised the sharpest review thread. Ask about: operational history of the old poller.
- #team-ingestion (Slack) — owns the subsystem. Ask about: conventions the diff follows silently.
```

## Rules

- **Primary sources first.** The diff, commit messages, PR body, review threads, and linked issues outrank any secondary material. If a claim can't be traced to one of these, mark it as inference.
- **Annotate every entry.** A bare link is useless in three months. Add one line: what it covers and when to reach for it.
- **Link to the exact thread**, not just the PR. Review discussions are long; the entry should land the reader on the decision, not the haystack.
- **Surface gaps explicitly.** If a decision has no documented "why" — no issue, silent commit message, no discussion — write a `## Gaps` section naming it. Gaps drive questions to the people in Wisdom, never fabricated answers.
- **Prune ruthlessly.** A source that turned out to be off-mission should be removed, not buried. Better five sharp sources than thirty mediocre ones.
- **Record contact preferences.** If the user has opted out of contacting authors/reviewers, note it here so future sessions don't keep proposing it.
