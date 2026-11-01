# Logging to radin

The backlog outlives the session. This skill records design work there and stops. A later session, chosen by the user, runs it.

Before the first write, read `/radin-record` (`~/.config/.claude/skills/radin-record/SKILL.md`). Its entry rules apply here. This file adds the design-specific parts.

## Rules

- Write only through `radin backlog`. Never edit `.claude/.radin/`.
- Run `radin backlog help add` once to confirm flag names on the installed version.
- Run `radin backlog show` first. If an entry already covers a finding, skip it and say so in the report.
- Log; do not execute. Do not run `/radin-batch`, `/radin-do` or `/radin-plan`. Do not suggest them in the report.

## Shape

**One epic per run and surface.** Examples: `design-system-android`, `ux-audit-routes-flow`. Reuse an epic from `radin backlog epics` when it fits.

```bash
radin backlog epic-add design-system-android <<'EOF'
Align the Android app with the new design system.
**Raised as:** <the user's request, verbatim>
**Decision:** Reference brand: <brand>. Palette: <name>. Font: <name>.
EOF
```

The epic body holds what every child shares: the request, the decisions, the document path. Children keep only what is specific.

**One entry per vertical slice.** A slice is demoable alone and fits one fresh context. One cause across many files is one entry, or one entry per module with a final entry that confirms the whole tree.

```bash
id=$(radin backlog add <category> "<short title>" \
  --skill interfaces:better-colors \
  --acceptance "<observable criterion>" \
  --complexity low <<'EOF'
<what the user sees, evidence, why it hurts, direction>
EOF
)
radin backlog epic-move "$id" design-system-android
radin backlog set-priority "$id" 8
```

## Fields

| Field | Rule for design work |
|---|---|
| category | `feat` new capability or screen; `fix` broken contrast, target or flow; `refactor` token or component migration with no visible change; `chore` doc updates |
| `--skill` | Every skill that should run the entry, one flag each. Set it on every entry where a skill applies, and omit it only when none does. A cold start never picks a skill by itself, so a missing flag means the skill goes unused. Choices: `frontend-design:frontend-design`, `interfaces:better-ui`, `interfaces:better-colors`, `interfaces:better-accessibility`, `interfaces:better-layout`, `interfaces:better-typography`, `interfaces:better-writing`, `interfaces:build-design`, `stageshow` (mocked-UI illustrations only), `documentation`, `technical-writing`. The CLI writes the instruction sentence; do not hand-write it |
| `--acceptance` | Observable and measurable: "body text on surface measures at least 4.5:1 in both themes". Never invent a criterion the audit did not produce |
| `--planning needed` | Use for a navigation restructure or a change that crosses several screens |
| `--complexity` | `low` for a single-file token or copy change; `high` otherwise |
| priority | Vertical 1: tokens first (13), component migrations (8), polish (3). Vertical 2: see `ux-audit.md` |
| deps | Every screen entry depends on the token entry it needs. Record with `set-deps` after all adds |

## Decisions that stay open

No user present, or the user said "later": add one body line per question.

```
**Open decision:** <question>, <options>, <your recommendation>
```

## Check your work

After logging, run `radin backlog show` and confirm each entry sits in the right epic with the right dependencies, and carries its `--skill` line wherever a skill applies. Report the count and titles.
