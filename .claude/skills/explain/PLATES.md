# Drawing plates for Obsidian

A plate is an inline SVG inside the Markdown note. Obsidian renders it in reading view on
desktop and on the phone. The look to aim for is a technical manual: thin ink lines, one
accent color, circled numbers, and a key under the drawing.

## Rules that keep a plate rendering

- **Put the opening `<svg …>` tag alone on one line, at column 0**, with a blank line
  before and after the whole block. Markdown starts an HTML block only on a line like that.
- **Keep every line inside the `<svg>` non-blank.** A blank line ends the HTML block, and
  Obsidian prints the rest of the SVG as text. `check.py` catches it.
- **Set `viewBox="0 0 360 H"` and `width="100%"`.** 360 units is a phone screen, so a
  12-unit label reads as 12 px text on the phone. Grow the height `H`, never the width.
  Add `style="max-width:560px"` so desktop does not blow the plate up.
- **Take every color from the theme**, so the plate works in light and dark mode:

  | Use | Value |
  |---|---|
  | Ink: lines, labels, numbers | `currentColor` |
  | The one part the plate is about | `style="fill:var(--text-accent,#7c5cff)"` |
  | Shaded areas | `style="fill:currentColor;fill-opacity:.08"` |
  | Text on the accent fill | `style="fill:var(--background-primary,#fff)"` |

- **Write labels of three words at most**, at `font-size` 11–13. The explanation goes
  in the key, where it wraps and stays searchable.
- **Keep the markup valid XML.** `check.py` parses each plate: escape `&` as `&amp;` and
  `<` as `&lt;` inside `<text>`.

## Callouts and key

Put a circled number on each part the key explains. Draw a short leader line to the part.
Number top to bottom, then left to right, so the eye follows the reading order. Seven
callouts fit well; twelve is the ceiling.

Under the plate, write one italic caption, then the key as a numbered Markdown list. Each
list number matches its callout:

```markdown
*Plate 2 — one column chunk, enlarged*

1. **Page header** — size and encoding of the page that follows.
2. **Dictionary page** — each distinct value once; data pages store indexes into it.
```

## Template: cutaway with an enlargement

Copy it, then replace the parts. The left block is the machine. The circle enlarges part 2.

```html
<svg viewBox="0 0 360 230" width="100%" xmlns="http://www.w3.org/2000/svg" style="max-width:560px;font-size:12px">
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
  corner. The moving input is the accent-filled shape, so the eye follows it across frames.
- **Byte strip**: a row of 16-unit cells in a monospace font, with the field names
  below. Use one accent per field.
- **Mermaid**: a flowchart or sequence of up to about eight nodes. Keep node labels short,
  because Mermaid shrinks the whole diagram to fit a phone.
