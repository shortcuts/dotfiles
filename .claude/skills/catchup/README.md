# catchup

A fork of Cursor's [`ketchup`](https://github.com/cursor/plugins/blob/main/pstack/skills/ketchup/SKILL.md)
(`pstack/skills/ketchup/SKILL.md`, copied 2026-11-03). Ketchup catches the user up on one
chat. Catchup catches the user up on a repository.

The reply rules are unchanged: voice, word budgets, action items, visuals. Only the source
of the facts differs.

## Differences from ketchup

| Part | ketchup | catchup |
|------|---------|---------|
| Source | The chat since the user's last message | `git` and `gh` on the default branch |
| Input | None | A time range, a scope, or both (`## Resolve the request`) |
| Grouping | By thing the user asked for | By feature, ordered by impact, never by date |
| What counts | What happened | The final state on the default branch only |
| `## Gather` | Chat, subagents, PR and CI state | Fetch, `git log`, `gh pr list`, `gh pr view`, read code on the base branch |
| Action items | Calls waiting on the user in the chat | Same, plus open PRs on the range that wait on the user |
| Summary bullet | One per thing the user asked for | One per feature |
| Word budget | 100 words for "what happened" | About 60 words per feature, no cap on the total |

## Removed from ketchup

- The link to `/bro` and its voice rules ("plain words, short sentences"). The STE output
  style (`.claude/output-styles/ste.md`) sets the voice. The rules about content stay.
- The `/visualize` reference. `clidraw` draws the charts and diagrams instead.
- The "notifications and subagent results are not their messages" rule. It applies to chats only.

## Keep in sync

Compare against upstream when ketchup changes. Port a change into the sections that
upstream and catchup share (`## Write the reply`, `## Visuals`). Leave `## Resolve the
request` and `## Gather what changed` as they are.
