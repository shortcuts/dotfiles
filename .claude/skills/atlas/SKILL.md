---
name: atlas
description: Use to record why a feature works the way it does as an ADR-style tldraw canvas ("explain the <feature> design", "map the decisions behind X"), to draft a design the user decides on with notes and verdicts, to act on the user's open marks on a canvas, or to maintain a repo's docs/atlas/ canvases after code changes.
---

# Atlas

An **atlas topic** is one canvas, stored as `docs/atlas/<topic>.json`. It records what the code cannot say: the **forces** on a feature, the **decisions** they led to, the **options** turned down, and the **consequences** accepted. It is an ADR drawn as a canvas. Code shows *how*; a card states *why*, in plain words, with no symbol, line or snippet.

The agent writes the topic. The human writes **marks** (notes, strokes, Choose/Reject verdicts), which the viewer saves to `docs/atlas/<topic>.marks.json`. The viewer rebuilds the canvas from both files on every change. **Drift** is a doc heading or code area a card points at that no longer exists.

`atlas.py` sits in this skill's directory. Run it from the repo root.

## Every pass

1. **Serve.** When `curl -s 127.0.0.1:4317/api/topics` fails, start `python3 <skill dir>/atlas.py serve` in the background.
2. **Clear open marks** of the topic you touch: see [Marks](#marks).
3. Run the branch.
4. **Check.** `python3 <skill dir>/atlas.py check docs/atlas/<topic>.json` exits 0.

## Branch: record a feature's design

1. **Scope** one feature or flow whose design took decisions a reader cannot recover from the code. Split a canvas past 25 cards into two topics. Name the file for the feature in kebab-case.
2. **Read** the feature's docs first, then the code, only to confirm what the docs claim and to find the decisions they leave out.
3. **Write** the topic with `status: "accepted"`:
   - a **Forces** band: platform rules, user needs and constraints, as `context` cards;
   - a **Decisions** band: one `decision` card per choice, each fed by the forces behind it;
   - a **Consequences** band: what each decision costs or guarantees, including the exceptions;
   - optional bands for the domain model a user sees, such as `state` cards for the states of a session, and `option` cards with `verdict: "rejected"` for paths tried and dropped.

**Done when:** the check exits 0, every decision has at least one force and one consequence, and every `body` comes from a doc or a code comment or is listed as a doc gap.

## Branch: draft a design

1. **Frame it.** A first band holds what exists today and the constraints, as `context` and accepted `decision` cards.
2. **Options.** One `option` card per option, `verdict: "open"`, with its cost and its kill criterion. Sketch an option as an SVG in `docs/atlas/assets/<topic>-<option>.svg` and set it as the card's `image` when a picture shows it faster than prose.
3. **Recommend.** A `decision` card names the option you recommend and why. The human decides.
4. **Iterate.** Each round of marks adds a band below the last one, titled for the question it answers. Leave earlier options in place: a rejected option keeps `verdict: "rejected"` and its reason, so the canvas holds the decision history.
5. **Settle.** When every option has a verdict, set `status: "accepted"` and rewrite the decision card as the outcome, with its consequences. A later canvas that replaces this one sets this one to `status: "superseded"`.

**Done when:** each option has a cost and a kill criterion, and the decision card holds one recommendation.

## Branch: maintain a topic

1. **Fix drift.** Point a card at the doc heading or area that replaced the one it lost, or delete the card when its decision is gone.
2. **Review moved cards.** The header lists the cards whose areas changed since `since` (default: the latest tag). Read the commits listed on each one, and decide whether the decision still holds. Rewrite the card, add a consequence, or mark the decision superseded by a new one.
3. **Advance** `since` to the tag you reviewed against.

**Done when:** the check exits 0 and the reply names every moved card as rewritten or confirmed.

## Marks

Each mark has `id`, `kind` (`note`, `draw`, `arrow` or `verdict`), `card` (the card it sits on or nearest to), `text` and `status`.

- **A note** is a question or a request. Act on it in the topic, then reply.
- **A verdict** (`verdict: "chosen"` or `"rejected"`) is the human's decision. Copy it into that option card's `verdict`, then reply with what it changes.
- **A stroke** (`draw`, `arrow`) is a circle, a cross-out or a pointer at its `card`. Read it with the nearest note. A stroke alone over an option reads as a vote for it; ask in the reply when unsure.

**Close a mark** by setting `"status": "closed"` and a one-sentence `"reply"` in `.marks.json`. Keep every other field as the viewer wrote it. A mark you cannot act on without the human's choice stays open, with the question in `reply`.

## Model

```json
{
  "topic": "Spoofing lifecycle",
  "summary": "One sentence: what the canvas explains or decides.",
  "status": "accepted",
  "since": "v1.1.0",
  "bands": [{ "id": "decisions", "title": "Decisions", "columns": 3 }],
  "cards": [{
    "id": "dec-wakelock", "band": "decisions", "kind": "decision",
    "title": "Hold a wake lock only while something moves",
    "body": "Play vitals flags long partial wake locks with the screen off, and a stationary session has nothing to keep awake.",
    "touches": ["core/location/src/main/kotlin/.../SpoofingWakeLock.kt"],
    "doc": "docs/features/foreground-service.md#wake-lock"
  }],
  "edges": [{ "from": "dec-wakelock", "to": "con-doze", "label": "tradeoff" }]
}
```

- **`status`**: `proposed`, `accepted` or `superseded`, as in an ADR.
- **`bands`**: rows of cards, top to bottom. `columns` caps a row (default 4). Put two bands that share many edges next to each other.
- **`kind`**: `concept` (default), `context`, `decision`, `consequence`, `option`, `state`, `image`.
- **`title`** and **`body`**: plain words a new teammate understands. Name the behavior, never the class or function.
- **`touches`**: the narrowest files or folders whose change could break the decision. The viewer never shows them on the card; it flags the card when one of them changes. A path shared by many decisions flags them all, so pick the file that owns the rule.
- **`doc`**: `path#anchor` of the heading that states the rule. A rule with no written source is a **doc gap**: leave `doc` out and list the gap in the reply.
- **`image`**: a repo path to a screenshot or an SVG sketch.
- **Edge `kind: "rejected"`** draws a red dashed arrow for a transition or idea that is refused. Edge `label` is the event, condition or tradeoff.
- The repo's own doc rules (its `AGENTS.md` or `CONTRIBUTING.md`) apply to every `title`, `body` and `label`.

When `git status` lists `docs/atlas/` and the repo does not commit canvases, ask the user once whether to add `docs/atlas/` to `.gitignore`.

After any edit to `atlas.py`, run `python3 test_atlas.py` in this skill's directory.

## Reply

- The link `http://127.0.0.1:4317/?topic=<topic>`.
- Each mark closed, with its reply, and each mark left open, with its question.
- For maintain: each moved card, rewritten or confirmed.
- Every doc gap.
