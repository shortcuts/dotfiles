# Drawing plates

A plate is a sketch in the note's `plates`: an SVG string, a title, and a key. The main page
draws it under **Why it works**, inline, so it takes the Obsidian theme in light and dark. Draw it like a technical manual: thin ink lines, one
accent color, circled numbers, a key below.

| Idea to show | Plate |
|---|---|
| The parts of one thing | Cutaway with numbered callouts |
| Layers, or a format read from byte 0 | Exploded view, in reading order |
| One small part that matters | Enlargement circle out of the cutaway |
| An input moving through the machine | Strip of numbered frames |
| Before and after, or two options | Side-by-side pair, one difference marked |

Draw boxes and arrows in the `flow`, not in a plate: `render.mjs` lays it out and
numbers its shapes.

## Rules that keep a plate rendering

- **Set a `viewBox` and leave out `width`.** The page scales the viewBox width to the
  note column, about 700 px on a laptop and 350 px on a phone. A 12-unit label reads at
  12 × column / width px: at the template's 360, about 23 px on a laptop and 12 px on a
  phone. Grow the height, not the width.
- **Take every color from the theme**, so the plate works in light and dark mode:

  | Use | Value |
  |---|---|
  | Ink: lines, labels, numbers | `currentColor` |
  | The one part the plate is about | `style="fill:var(--text-accent,#7c5cff)"` |
  | Shaded areas | `style="fill:currentColor;fill-opacity:.08"` |
  | Text on the accent fill | `style="fill:var(--background-primary,#fff)"` |

- **Draw what is true.** Draw the real count: three servers on the ring when the
  lifecycle names three. `check.py` cannot see a wrong proportion, so check it by eye.
- **Draw with shapes and text only:** `g`, `path`, `rect`, `circle`, `ellipse`, `line`,
  `polyline`, `polygon`, `text`, `tspan`, `title`, `defs`, `marker`. No `on*` attribute,
  no `href`, no `url()` other than `url(#id)`. The page inlines the SVG, so `check.py`
  rejects anything that runs or loads.
- **Keep the markup valid XML.** Escape `&` as `&amp;` and `<` as `&lt;` inside `<text>`.
- **Write labels of three words at most**, at `font-size` 11 to 13. The explanation goes
  in the key.

## Callouts and key

- Put a circled number on each part the key explains, with a short leader line.
- Number top to bottom, then left to right. Use up to seven callouts.
- Each `key` line matches its callout number, and says what the part does, not only its
  name: `"Dictionary page: holds each distinct value once, so data pages store small
  indexes."` `check.py` requires callouts `1` to `n` and exactly `n` key lines.

## Caption

One sentence under the plate: what moves, and the true numbers. "A key hashes to 0x3a and
walks clockwise to server C, the next of 3 servers." Take each number from the same case
as the lifecycle, so the caption and the map agree.

## Template: cutaway with an enlargement

The left block is the machine. The circle enlarges part 2. Copy it into `svg` as one
string, and replace the parts.

```html
<svg viewBox="0 0 360 230" xmlns="http://www.w3.org/2000/svg" style="font-size:12px">
  <g fill="none" stroke="currentColor" stroke-width="1">
    <rect x="44" y="16" width="120" height="196" rx="3"/>
    <line x1="44" y1="40" x2="164" y2="40"/>
    <line x1="44" y1="176" x2="164" y2="176"/>
    <circle cx="272" cy="108" r="76"/>
    <line x1="164" y1="72" x2="210" y2="62"/>
    <line x1="164" y1="120" x2="210" y2="154"/>
  </g>
  <rect x="44" y="72" width="120" height="48" style="fill:var(--text-accent,#7c5cff)"/>
  <rect x="44" y="176" width="120" height="36" rx="3" style="fill:currentColor;fill-opacity:.08"/>
  <g text-anchor="middle" style="fill:currentColor">
    <text x="104" y="32">HEADER</text>
    <text x="104" y="198">FOOTER</text>
    <text x="272" y="84">small part</text>
    <text x="272" y="112">shown big</text>
  </g>
  <text x="104" y="100" text-anchor="middle" style="fill:var(--background-primary,#fff)">part</text>
  <g fill="none" stroke="currentColor">
    <circle cx="20" cy="28" r="9"/><line x1="29" y1="28" x2="44" y2="28"/>
    <circle cx="20" cy="96" r="9"/><line x1="29" y1="96" x2="44" y2="96"/>
    <circle cx="20" cy="194" r="9"/><line x1="29" y1="194" x2="44" y2="194"/>
  </g>
  <g text-anchor="middle" style="fill:currentColor;font-size:11px">
    <text x="20" y="32">1</text>
    <text x="20" y="100">2</text>
    <text x="20" y="198">3</text>
  </g>
</svg>
```

## Other forms

- **Exploded view**: the template's blocks, pulled apart vertically with a 12-unit gap,
  and one callout each. Byte 0 at the top.
- **Frame strip**: boxes 100 units wide, three per row, each with its frame number in the
  corner. The moving input is the accent-filled shape, so the eye follows it.
- **Byte strip**: a row of 16-unit cells in a monospace font, with the field names
  below. Use one accent per field.
