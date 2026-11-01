---
name: maintain-design
description: Create, audit and maintain a repository's design system (UI vertical) and its layout, navigation and UX-copy quality (UX vertical). Anchors the look on a well-known product from VoltAgent/awesome-design-md, aligns colors and font with the user, stores the result in the repo, and logs every finding to the radin backlog without changing product code. Use whenever the user mentions design system, DESIGN.md, palette, brand colors, font choice, "make it look like Uber/Airbnb/Linear", UI or UX audit, navigation or layout problems, onboarding flow quality, wiki or docs readability, hero or feature-card illustrations and mocked product UI, previews of a proposed design, or TUI/Android/web look and feel, even when they never say "design system".
---

# Maintain design

Keep a repository's look and usability coherent across sessions. The repo, not the chat, holds the design memory. Two verticals share one rule: this skill writes design documents, stageshow previews (`references/illustrations.md`) and radin entries, never product code.

**Why no product code:** design work spreads across many files and screens. Logging it as radin entries lets the user pick what to run and when (`/radin-batch`). The skill never proposes or starts that run.

## Step 0: Orient (always)

1. **Platform.** Detect every surface the repo ships: Android Compose, static HTML wiki, terminal UI, CLI output, embedded display. Read `references/platforms.md` for how to inspect each.
2. **Existing design system.** Look for `DESIGN.md`, `docs/design-system.md`, a tokens module (for example `core/designsystem`), a `:root` block in a stylesheet. Read what you find, and read the repo's `AGENTS.md` for its doc policy.
3. **radin.** Run `radin backlog env`. No output or an error means radin is missing: say so and stop before Step 1. Run `radin backlog show` so you do not log what exists.
4. **Existing system: ask now.** A design system found in step 2 means the user must settle the job before any audit. Ask once with `AskUserQuestion`, in full sentences: improve the existing system, or change something in particular (colors, density, font, feel, layout, other). Options and what each does: `references/design-system.md`, "Existing system: the three jobs". Skip it when the request already names the job. **Why:** an audit of the wrong job wastes the run and logs entries the user does not want.
5. **Pick the vertical** from the request:
   - Look and feel, palette, font, "design system", brand match: **Vertical 1**.
   - Layout, navigation, flows, copy, docs readability, "UX": **Vertical 2**.
   - Both, or unclear: ask with `AskUserQuestion`, and run Vertical 1 first. UX findings are cheaper to fix once tokens exist.

A user present means `AskUserQuestion` works. A sub-agent or batch run has no user: take every "(Recommended)" default and log each skipped question as a `**Open decision:**` line (see `references/radin-logging.md`).

## Vertical 1: UI design system

Read `references/design-system.md` before starting. It holds the full procedure. Outline:

1. **Existing system?** If one exists, Step 0 already asked which job the user wants. Do not ask again. The jobs:
   - *Maintenance*: audit drift (raw values, off-token literals, contrast, missing states) and log fixes.
   - *Suggestions*: audit, then propose improvements and let the user choose which to log. Show each layout or look proposal as a `/stageshow` preview (`references/illustrations.md`, "Recommend").
   - *Change something in particular*: re-run the match (Operation 1) and alignment (Operation 2) for the named aspects only, to evolve the system.
   No system: run Operation 1, then 2, then write.
2. **Operation 1, find the reference.** Characterise the product (what it is, who uses it, where, how: one-handed outdoors, long sessions at a desk). Shortlist 2-3 brands with `scripts/awesome-design.sh`. Read their DESIGN.md. Borrow principles (density, restraint, shape language, hierarchy), never marks, proprietary fonts or layouts.
3. **Operation 2, align colors and font.** Build 2-3 candidates with `/interfaces:better-colors` (palette, semantic roles, light and dark) and `/interfaces:better-typography` (a font the platform can ship, licence-safe). Measure every pair with `scripts/contrast.py`; never quote an estimate. Show the candidates in one `AskUserQuestion` using the `preview` field for swatches. This is the one required user decision.
4. **Autonomous write.** After the pick, ask nothing more. Apply `/frontend-design:frontend-design` for direction, `/interfaces:better-ui` for shape, depth and hit areas, `/interfaces:better-accessibility` for contrast and targets. Write `docs/DESIGN.md` (or the existing path) and add the binding rule to `AGENTS.md`/`CLAUDE.md` (see `references/design-system.md`, "Output").
5. **Log every finding.** The document and the one instruction-file line are the only files you write. Log the complete list of gaps, wiring and migrations as radin entries. This list is the end goal.

## Vertical 2: layout, navigation, UX

Read `references/ux-audit.md` before starting. Outline:

1. Capture evidence first: screenshots or the rendered page or the running TUI. Read the design system so you judge against the repo's own rules.
2. Audit with these lenses: `/interfaces:better-layout` (grouping, alignment, reading order, progressive disclosure), `/interfaces:better-typography` (hierarchy and wrapping), navigation (depth, back paths, discoverability, state after return), copy and docs (`/documentation` for structure, `/technical-writing` for sentences), `/interfaces:better-accessibility` as a cross-check, and the repo's mocked-UI illustrations against `/stageshow` (`references/illustrations.md`, "Audit").
3. **Change nothing.** Log each finding as a radin entry. Do not offer to execute them. The user decides.

## Logging to radin

Read `references/radin-logging.md` before the first `radin backlog add`. Short version: one epic per vertical run or screen, one vertical-slice entry per finding, each with every skill that should run it (`--skill`, repeatable; omit only when none applies), acceptance criteria, category, priority and dependencies. Token work goes first and every screen entry depends on it. All writes go through the `radin backlog` CLI, never by editing `.claude/.radin/`.

## Final report

Keep it short and in this order:

1. What you decided and wrote (path of the design document, brand matched, palette and font picked).
2. The entries logged: count, titles, categories, epics, priorities.
3. Open decisions left for the user.
4. What you did not check (for example "no device attached, so Compose screens were audited from source only").

End there. Do not suggest running the backlog.
