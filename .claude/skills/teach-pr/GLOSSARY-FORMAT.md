# GLOSSARY.md Format

`GLOSSARY.md` is the canonical language for this teaching workspace: the nomenclature of the change and the subsystem it touches. All lessons, exercises, and learning records should adhere to its terminology. Building it is itself part of learning: compressing a concept into a tight definition is evidence the user understands it. Prefer the codebase's own names for things — the glossary should let the user read the diff and the review threads without translation.

## Structure

```md
# {Change / Subsystem} Glossary

{One or two sentence description of the change or subsystem this glossary covers.}

## Terms

**Backpressure**:
A mechanism by which a consumer signals a producer to slow down when it cannot keep up.
_Avoid_: Throttling, rate limiting

**Task record**:
The row in `tasks` representing one unit of ingestion work, as defined in `models/task.go`.
_Avoid_: Job, event, message

**Drain**:
Completing all in-flight tasks before shutdown without accepting new ones (introduced in commit `d208b89`).
_Avoid_: Flush, graceful stop
```

## Rules

- **Add a term only when the user understands it.** The glossary is a record of compressed knowledge, not a dictionary the user reads to learn. If the user has just been introduced to a concept, wait until they can use it correctly before promoting it here.
- **Be opinionated — but defer to the codebase.** When several words exist for the same concept, pick the one the code and the PR discussion actually use, and list the rest as aliases to avoid. This is how language compresses.
- **Keep definitions tight.** One or two sentences. Define what the term IS, not what it does or how to do it.
- **Use the glossary's own terms inside definitions.** Once a term is in the glossary, prefer it everywhere — including inside other definitions. This is what makes complex terms easier to grasp later.
- **Group under subheadings** when natural clusters emerge (e.g. `## Anatomy`, `## Programming`). A flat list is fine when terms cohere.
- **Flag ambiguities explicitly.** If a term is used loosely in the codebase or discussion, note the resolution: "In this workspace, 'task' always means a task record — the Go routine is called a 'worker'."
- **Revise as understanding deepens.** A definition the user wrote in week one may be wrong by week six. Update in place; do not leave stale entries.
