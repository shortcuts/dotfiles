# Vertical 1: design system procedure

## Contents

- Existing system: the three jobs
- Operation 1: find the reference
- Operation 2: align colors and font
- Output: what to write and where
- Audit checklist (maintenance and suggestions)

## Existing system: the three jobs

`SKILL.md` Step 0 asks this question as soon as it finds a system, for both verticals. Read the system first. Then ask one `AskUserQuestion` with these options (put the job you recommend first):

| Option | What the skill does |
|---|---|
| Maintenance | Audit drift against the system's own rules. Log fixes. Change no direction. |
| Suggestions | Audit, then list improvement ideas as options, each with a stageshow preview when it changes a layout or look (`illustrations.md`). Log only the ones the user picks. |
| Change something in particular | Run Operations 1 and 2 for the named aspects only, then diff the result against the old system. Name the aspects in the question: colors, density, font, feel, layout. |

"Maintenance" and "Suggestions" together mean "improve the existing one". The user's wish to change something is a signal, not a spec. Ask what they want changed in the same question as a multi-select follow-up, so Operation 1 searches for the right thing. Leave untouched what they did not name.

## Operation 1: find the reference

1. **Characterise the product** in four lines: what it is, who uses it, the usage context (hands, light, session length), the platform. Read the README and `AGENTS.md`; do not ask what the repo already says.
2. **List and shortlist.**
   ```bash
   scripts/awesome-design.sh list
   scripts/awesome-design.sh summary <brand>
   ```
   Pick 2-3 brands whose job resembles the product's job, not its industry. A map-based mock-GPS tool resembles Uber and Airbnb (map plus sheets, one dominant action); a Rust TUI resembles Warp, Raycast or Linear (dense, keyboard-first, dark).
3. **Read the winner in full** with `scripts/awesome-design.sh fetch <brand>`. Extract:
   - hierarchy rules (how many type sizes, how many accent uses per screen)
   - shape language (radius, borders versus shadows)
   - density and spacing rhythm
   - what the brand avoids
4. **Record the borrow list**, one line each, with the reason it fits. A principle that does not fit the usage context stays out.
5. **Legal line.** Take no logo, wordmark, proprietary typeface or copied layout. The DESIGN.md files are "inspired interpretations"; treat them as inspiration.

## Operation 2: align colors and font

1. Build 2-3 candidates. Each candidate has:
   - a one-line mood and why it follows from Operation 1
   - brand/accent, surface, text, and status colors (success, warning, error), in light and dark
   - a font pair or single family with weights, plus the fallback the platform ships
2. Use `/interfaces:better-colors` for the roles and `/interfaces:better-typography` for the type scale.
3. Measure with the script. Test text on surface, accent on surface, text on accent:
   ```bash
   scripts/contrast.py FFFFFF:111111 FF7A00:111111
   ```
   Drop a candidate where body text is under 4.5:1 or UI parts are under 3:1.
4. Font rules:
   - Android: bundle only open-licence fonts (OFL, Apache) or use the system font. State the licence.
   - Static wiki: the repo may forbid web fonts (check its docs). Default to a system stack.
   - TUI: the terminal owns the font. Design for glyph set and width, not family. Say so, and spend the effort on color and box-drawing.
5. Ask once with `AskUserQuestion`, one option per candidate. Put a swatch block and a type sample in each `preview`. Mark your pick "(Recommended)" and say why in the description.
6. After the answer, stop asking.

No user present: take the recommended candidate and log an `**Open decision:**` entry so the user can reverse it.

## Output: what to write and where

**Location.** Reuse the existing path. With none: `docs/DESIGN.md`.

**Binding pointer.** Add one rule to the repo's agent instructions (`AGENTS.md`, or `CLAUDE.md` when no `AGENTS.md` exists; if `CLAUDE.md` only imports `AGENTS.md`, edit `AGENTS.md`). Skip it if the rule is already there. Wording: `Any UI or UX change must respect docs/DESIGN.md. Run /maintain-design to change the design system itself.` Use the real path. **Why:** a design system nobody reads drifts; the instruction file is what every later session loads.

**Respect the repo's doc policy.** If `AGENTS.md` says code holds token values and docs hold rationale (locationjoystick does), the document carries direction, rules, judgement calls and a pointer to the token files, and repeats no hex or dp values. If the repo has no token code (a TUI, a plain stylesheet), the YAML front matter carries the tokens, in the format of the awesome-design-md files.

**Sections**, in this order:

1. Direction and why (one name for the direction, the usage context, the borrowed principles with their reasons)
2. Provenance (reference brand, what was borrowed, date, who picked what)
3. Color roles and font (values or pointer, per the policy above; contrast results)
4. Rules (numbered, each testable: "no raw hex outside the theme")
5. Component choice (use-when judgements)
6. Accessibility floor
7. Platform notes (one short block per surface)
8. Maintenance (when to update this file, which skill to run: `maintain-design`)

Write with `/technical-writing`: short sentences, the real symbol names, no filler.

**Do not write product code.** The design document, the one instruction-file line and any stageshow previews (`illustrations.md`) are the only files you write. Token files, theme changes and component migrations become radin entries.

**The end goal is the backlog.** The document is the reference. The deliverable is the full list of findings logged to radin: every gap between the repo and the document, complete, not a sample. No findings is a valid result; say so.

## Audit checklist (maintenance and suggestions)

Scan the code with the graph or grep, and cite `path:line` in each entry.

- Raw color or size literals outside the token files
- Components bypassing the shared ones
- Contrast failures in either theme (measure with the script)
- Touch targets under 48 dp (Android) or hit areas under 44 px (web)
- State conveyed by color alone
- Missing content descriptions or accessible names
- Fonts set inline
- Wiki or TUI palette drifting from the app palette
- Rules in the document that code no longer follows (the code wins: fix the document, and log it)
- Mocked-UI illustrations (hero demos, feature cards) that drift from the design document: run the audit table in `illustrations.md`

Group findings by cause, not by file. One cause with 30 call sites is one entry sized as one slice or batched per module.
