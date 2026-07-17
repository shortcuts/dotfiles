# MISSION.md Format

`MISSION.md` lives at the workspace root. It captures the _reason_ the user wants to understand this change. Every teaching decision — which part of the diff to teach next, which discussion threads to surface, which exercises to design — should trace back to this document.

## Template

```md
# Mission: {Change — e.g. "PR #7959: task queue backpressure"}

## The change
{The commit hash or PR URL, plus a one-line statement of what it claims to do.}

## Why the user cares
{1-3 sentences. The concrete real-world goal. Reviewing it? Onboarding onto the subsystem? Building on top of it? Avoid abstract framings like "to understand the PR" — push for the underlying outcome.}

## Success looks like
- {A specific, observable thing — e.g. "Can explain to the team why the queue replaced polling"}
- {Another — e.g. "Can review the follow-up PR without asking the author basics"}
- {…}

## Constraints
- {Time before the review deadline, unfamiliarity with the language/subsystem, anything that bounds the approach}

## Out of scope
- {Parts of the change or codebase the user explicitly does not need right now — protects the zone of proximal development}
```

## Rules

- **One mission per workspace.** If the user wants to understand two unrelated changes for unrelated reasons, that is two workspaces. Multiple changes serving one goal (e.g. onboarding onto one subsystem) share a mission.
- **Concrete over abstract.** "Review PR #7959 well enough to approve or block it by Friday" beats "understand the PR." "Explain the ingestion pipeline change to my team" beats "learn the codebase."
- **Push back on vagueness.** If the user cannot articulate why, interview them before writing anything. A bad mission is worse than no mission.
- **Revise when reality shifts.** A user who came to review may discover they need the whole subsystem. When the goal moves, update this file — don't leave a stale mission steering future sessions.
- **Keep it short.** If `MISSION.md` runs past a screen, it has stopped being a compass and started being a plan.
