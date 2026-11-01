# Product illustrations and previews (stageshow)

`/stageshow` builds faux product UI: a still or a short animation of a believable interface. This skill uses it in two ways:

- **Audit:** judge the illustrations the repo already ships (hero demos, feature cards, wiki or README screenshots, mocked UI).
- **Recommend:** show a proposed look or layout as a preview, so the user judges it before choosing.

stageshow draws pictures of a product. It never changes the product. Entries that change real UI use the `better-*` skills, not `stageshow`.

## Contents

- When it applies
- Audit: illustrations the repo ships
- Recommend: previews of a proposal
- Logging

## When it applies

Read `/stageshow` (its `SKILL.md`, then `references/craft.md` and `references/framing.md`) before you judge or build anything here. Skip this file when the repo ships no mocked UI and the user asked for no preview.

Find illustrations by their trace: a `kit/` import from stageshow, `Stage` or `Window` components, `?capture=` URLs, hero or feature-card images under `docs/`, `site/` or `assets/`, a `REHEARSAL.md`.

## Audit: illustrations the repo ships

Judge each illustration against the repo's own `DESIGN.md` first, then against stageshow's rules. Cite `path:line` or the image path in each entry.

| Check | Fails when |
|---|---|
| Fidelity | Real text in every row (too much), or two gray blobs and a button (wireframe) |
| Look | Tokens differ from `DESIGN.md`, or the product's own icons and chrome are missing (`stageshow/references/looks.md`) |
| Framing | A whole window with even margins (boxed), a plate under a hero, a dead corner, a cut control |
| Hierarchy | Every object has the same weight (flat), or filler sits where the eye lands |
| Chrome | A window, phone, bubble, status bar or home indicator drawn by hand instead of the kit part |
| Marks | Stock AI sparkles, purple, or a made-up logo (a letter in a colored square) |
| Copy | A real string that the story does not need, or a term the app does not use |
| Small formats | A demo in a phone column with no `compact` design at 358 px |
| Motion | A cursor move with no cause, content that swaps instead of moving, a long hold, a loop that resets with no cause, no `poster` frame that tells the story alone |
| Handover | No `REHEARSAL.md` beside the component |

Film the illustration before you judge it (`stageshow/references/rehearse.md`). A still hides motion faults. No browser available: audit from source and say so in the report.

Group findings by cause. One cause across ten illustrations is one entry, or one entry per illustration family.

## Recommend: previews of a proposal

Use this in the *Suggestions* and *Change something in particular* jobs, and when a Vertical 2 finding changes a layout. A palette swatch does not show whether a layout works. A preview does.

1. Build a preview only for a proposal the user may pick. Build one per candidate, at most three. Skip it for a token fix.
2. Follow `/stageshow` Workflow: plan, closest gold example, the screen, then rehearse. Use a still unless the proposal is about motion. Map the candidate's tokens with `stageshow/references/looks.md`.
3. Save each preview under `docs/design/previews/<slug>/` (or beside the existing design document), never in product source. Add the `REHEARSAL.md` that stageshow asks for.
4. Show the preview in the `AskUserQuestion` that asks for the pick. Name the file path in the option description.
5. Log the preview folder as an artifact of the epic. A chosen preview becomes the acceptance reference: "the screen matches `docs/design/previews/<slug>/` in layout and hierarchy".

**Why previews live outside product code:** they use React and the stageshow kit, which the product may not ship. The user can delete the folder without touching the app.

No user present: build no preview. Log an `**Open decision:**` line instead.

## Logging

- An entry that fixes an illustration uses `--skill stageshow`. Add `--skill interfaces:better-ui` or `--skill interfaces:better-colors` when the fix also needs them.
- An entry that builds real UI from a chosen preview uses `--skill interfaces:build-design` or the `better-*` skill that fits. It never uses `stageshow`.
- Acceptance names what the filmed frame must show: "the poster frame shows the result on screen", "the demo has a `compact` design at 358 px". Do not invent a criterion the audit did not produce.
