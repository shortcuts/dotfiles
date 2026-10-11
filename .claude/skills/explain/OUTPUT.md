# What install writes

`check.py --install` hands the checked note to `obsidian.py`. It writes one folder in the
vault, and rewrites one index page:

| Path under `$EXPLAIN_VAULT` | What |
|---|---|
| `Explain/<slug>/<title>.md` | The main page |
| `Explain/<slug>/<part-id>.md` | One page per part below the root |
| `Explain/<slug>/note.json` | The note itself. Obsidian hides it; a reinstall reads it |
| `Explain.md` | One link per note, newest first |

`EXPLAIN_VAULT` defaults to the `Knowledge` folder of the iCloud vault. With no such
folder, install stops and names the variable. `render.mjs` needs `node`, and ELK, which
`obsidian.py` fetches into `vendor/` once and checks against its pinned sha256.

## Decisions

- **Static pages, no viewer.** Obsidian strips scripts from a note, so nothing
  interactive runs there. An HTML viewer with pan, zoom, a step header, and a click panel
  was retired for one store: every note lives in the vault, next to the user's other
  notes, and syncs to the phone.
- **The map is an inline SVG.** `render.mjs` lays each flow out with ELK at install, with
  the options the viewer used: top to bottom, groups as frames, `end` shapes pinned to the
  first and last rows. Inline SVG takes `currentColor` and the theme variables, so it
  reads in light and dark mode, and its text stays searchable. A screenshot would be a
  raster in one theme.
- **Numbers replace the click.** Each shape carries its position in the `nodes` list. The
  key under the map gives each number one line, and each step cites the numbers it
  touches, as *The Way Things Work* cites its callouts. A frame strip, one map per step,
  was skipped: six copies of the map cost more page than the numbers.
- **Links replace the tree.** Each part gets its own page, linked by its path from the
  vault root, so two parts with one name never collide. Backlinks and the graph view
  show who links to a part.
- **Footnotes replace the word tooltips.** A term gets a footnote at its first use on each
  page, and the definitions collect at the foot of the page. A reader who knows the term
  reads on.
- **Stores always show.** The viewer hid them by default behind a toggle. A static map
  draws them, because a map without its databases tells half the story.
- **A reinstall replaces only its own pages.** Each page starts with `explain-slug:
  <slug>` in its frontmatter. A page without it, such as a hand-written one, stays.
- **The SVG block follows Markdown's HTML rules.** The opening `<svg …>` tag sits alone on
  its line, and no line inside is blank: a blank line ends the HTML block, and Obsidian
  prints the rest as text.

## Limits

- **A wide map prints small.** A page column is about 700 px on a laptop and 350 px on a
  phone, and the map scales to fit it. A 14-shape map laid out 1,159 px wide, so its
  13 px labels print at about 8 px on a laptop and 4 px on a phone. Keep labels short,
  and split a big flow into the services' own flows.
- **Code notes sync to iCloud.** The vault is a personal account, and code notes
  summarize employer code. The user chose one vault knowing this.
