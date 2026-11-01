# Vertical 2: layout, navigation, UX audit

This vertical reads, measures and logs. It changes nothing.

## Contents

- Evidence first
- Lenses
- Severity and priority
- Finding format

## Evidence first

A finding without evidence is an opinion. Capture before judging (details per surface in `platforms.md`):

- Android: screenshots over adb. Follow the repo's testing doc for driving the app. No device: audit from the composables and string resources, and say so in the report.
- Wiki or web: serve it and read the rendered pages, at phone width and desktop width.
- TUI: run it in a pane and read the screen output at 80x24 and a wide size.

Read the design system document first. Judge against the repo's own rules before outside taste.

## Lenses

Run each lens over every screen or page in scope. Skip a lens that cannot apply and say so.

1. **Layout** (`/interfaces:better-layout`): grouping by proximity, alignment, one dominant action per screen, reading order, progressive disclosure, empty and error states.
2. **Typography** (`/interfaces:better-typography`): number of sizes in play, hierarchy, line length, truncation and wrapping, numeric alignment.
3. **Navigation**: how many taps to the main tasks, whether back always goes where the user expects, whether state survives a return, whether a feature is discoverable without a manual, whether the same thing has the same name everywhere.
4. **Copy**: button verbs, error messages that say what happened and what to do, one term per concept, sentence case. Judge with `/technical-writing`.
5. **Docs and onboarding** (`/documentation`): does each doc page fit one Diátaxis mode (tutorial, how-to, reference, explanation)? Does a first-time user reach their first success without leaving the flow? Does the wiki use the words the app uses?
6. **Accessibility cross-check** (`/interfaces:better-accessibility`): focus order, names, targets, contrast, motion. Log structural problems here; leave token-level contrast to Vertical 1.

7. **Illustrations** (`/stageshow`): the mocked UI in heroes, feature cards and docs. Use the audit table in `illustrations.md`. Skip when the repo ships none.

When a finding changes a layout, build a stageshow preview of the fix (`illustrations.md`, "Recommend") if a user is present to choose.

## Severity and priority

Map severity to radin priority (higher runs first):

| Severity | Meaning | Priority |
|---|---|---|
| Blocks a task or excludes users | cannot finish the flow, fails accessibility | 13 |
| Slows or confuses | extra taps, unclear label, hidden feature | 8 |
| Polish | alignment, rhythm, wording | 3 |

A change that every other entry depends on (a shared layout scaffold, a navigation restructure) gets a priority one step higher and becomes a dependency of the entries it unblocks.

## Finding format

Each finding becomes one radin entry (see `radin-logging.md`). The body contains:

- **What the user sees**: one or two sentences with the screen name.
- **Evidence**: the screenshot path, `path:line`, or the string.
- **Why it hurts**: the user's cost, in one sentence.
- **Direction**: the smallest change that would fix it, stated as intent. Not a diff.
- **Skill to apply**: every skill that fits, one `--skill` each (for example `interfaces:better-layout`, or `stageshow` for an illustration). Omit the flag only when none applies.
- **Acceptance**: one observable criterion per `--acceptance`.

Do not write "would you like me to fix these". The report ends after the list.
