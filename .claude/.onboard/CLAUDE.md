# Onboard viewer

`index.html` draws the notes that the `onboard` skill writes
(`../skills/onboard/`). The skill owns the data shape (`SCHEMA.md`) and its validator
(`check.py`). This folder owns only the page. Change the design here without touching the
skill.

## Layout

| Path | What | Tracked |
|---|---|---|
| `index.html` | The page shell: markup and the `ONBOARD` registry | yes |
| `app.css`, `app.js` | The viewer's style and code, shared by the page and every bundle | yes |
| `bundle.py` | Fetches `vendor/`, and builds the one-file copy of a note | yes |
| `vendor/` | ELK, pinned by version and sha256 | no |
| `notes/<slug>.js` | One note, written by `check.py --install` | no |
| `notes/<slug>.html` | The note's one-file copy, written by `bundle.py` on each install | no |
| `notes/manifest.js` | The note list for the switcher, rebuilt on each install | no |
| `$ONBOARD_VAULT/Onboard/<title>.md` | The note's Obsidian page, written by `bundle.py` on each install | no |

`notes/` stays out of git: notes summarize employer code, and this dotfiles repo can be
public.

## Decisions

- **Shared files, bundled at install.** A `file://` page cannot `fetch()` its own
  `app.js` to inline it, so the browser cannot build a one-file copy. `bundle.py` builds
  it at install instead: the page, the note, and ELK in one HTML file of about
  1.6 MB. The file opens offline, and the download button links to it.
- **Vendored libraries, fetched once.** `bundle.py` downloads ELK into
  `vendor/` and checks each file against its pinned sha256, because the page runs that
  code. The viewer loads `vendor/` first and falls back to jsDelivr. It fetches with
  `curl`, because a python.org Python ships without CA certificates. The files stay out
  of git: 1.5 MB of minified code does not belong in a dotfiles history.
- **Notes are `.js`, not `.json`.** Chrome blocks `fetch()` on `file://`. A `<script>` tag
  that calls `ONBOARD.register(...)` loads from disk with no server.
- **One canvas, nested boxes.** The whole note sits on one pannable, zoomable canvas. A
  folded node is a box. A click unfolds it into a frame with its children inside, so the
  reader always sees where a node lives. A column view that moved the reader between
  levels hid both the position and the links, and it was dropped. A disk-usage sunburst
  was rejected: area encodes size, and size is not what the reader needs.
- **A fold re-fits the map.** A fold moves every box, so the view zooms to show the whole
  new layout, and boxes slide to their new place. A click that only selects keeps the
  view. A panel link to a visible node centers it instead.
- **Links land on the deepest visible box.** Each link lifts to the first folded node on
  the path to each end, so one link written on a leaf shows at every fold. The links that
  cross the selected node's border light up: purple for a link into the selection, orange
  for a link out of it. A legend in the canvas corner names the two. The boxes at their far
  end get an accent border. Inside a selected frame, every link would light up otherwise.
- **ELK lays out the canvas.** It is built for nested graphs and routes links around
  boxes. A frame with no link inside packs its children
  with `rectpacking`, because layered layout stacks unlinked siblings in one tall column.
  With neither `vendor/` nor a network, the map shows a message, and the panel still works.
- **The fold state shows on each box.** A box a click unfolds has an accent stripe on its
  leading edge and a chevron pointing right in a soft accent circle. An unfolded frame has
  an accent band on its header and a solid accent circle with the chevron pointing down.
  A leaf has neither. The chevron turns, so the state change reads as one motion.
- **Drag pans, pinch zooms.** A plain wheel or two-finger swipe pans, and a pinch or
  Ctrl/⌘+wheel zooms at the pointer. A drag of 4 px or more is a pan, not a click.
  **Fit**, **Expand all**, **Collapse**, and **Full screen** sit in the canvas corner. A
  flow with a stepper goes full screen with its banner, so the step text stays in view.
- **One title in the bar.** With more than one note, the switcher shows the title on the
  right, and the `h1` stays for screen readers only. A visible `h1` repeated the select.
- **The hash holds the view state:** the note, the selected node, and the unfolded nodes.
- **One Obsidian page per note.** The page holds the root's summary, problem, principles,
  parts, and words, so vault search finds a term, plus a `file://` link that opens the
  viewer. `ONBOARD_VAULT` sets the vault folder, and the default is the iCloud vault's
  `Knowledge`. With no such folder, as on a Mac with no vault, the export skips. The
  `onboard-slug` frontmatter key names the page's note, so a renamed title replaces the
  old page, and hand-written pages stay. Only links go to the vault, never the HTML:
  iCloud is a personal account, and the notes summarize employer code.
- **A flow is a second map.** A flow is shapes and edges as data. It gets its own canvas
  with the map's boxes, edges, pan, zoom, and **Fit**, so the two graphs read and move alike.
  The canvas code takes the canvas it acts on, so the map and each flow share it. A store
  (a database, a queue, a bucket) is a pill. Mermaid was dropped: a second layout engine
  drew a second visual language, and it doubled the bundle. With no ELK, a flow shows as a
  list of edges.
- **The root panel reads top-down.** Summary, then the words every section uses, then the
  problem, the principles, and the flow graph. The words show five, the rest fold behind
  "Show N more".
- **The life of the data is a stepper on the flow.** A banner on the graph's top edge
  shows one step. **←** and **→**, on screen or on the keyboard, move it. The step's shapes
  and the edges between them light up, and the rest dims. A list beside the graph made the
  reader match each step to its shapes by eye. With no ELK, the steps show as a list.
- **Links pin to `repo.sha`.** A branch link drifts as the code moves. With `repo.web`
  null, the links open `vscode://file/…`.
- **Entry points show three, the rest fold behind "Show N more".**
- **No layout shift.** The canvas has a fixed height, so a fold never moves the panel. A
  flow renders to SVG before its panel enters the page, and the SVG is cached per source.
  The selected box gets an outline, never a new size. Fonts load with
  `display=optional`, and `scrollbar-gutter: stable` holds the width when a long note adds
  a scrollbar.
- **One box geometry.** Every folded box has one fixed size: a one-line name and a
  two-line summary. A frame header shows one summary line. The full summary sits in the
  panel and in the tooltip. The monospace face makes a link label's width a character
  count, so ELK gets exact label sizes without measuring the DOM.
- **Flows leave the text measure.** A flow canvas spans `main` at a fixed 380 px height,
  so a wide graph gets room and a fold never shifts the text below.

## Design tokens

GitHub Dark Dimmed in dark mode, GitHub Light in light mode. Muted text is scale gray
`#909dab`, because the theme's own `#768390` measures 3.9:1 on the canvas. The accent marks
only what a click reaches, so the links away from the selection stay muted. The link
directions use purple and orange, which stay apart under red-green color blindness. One face for everything:
JetBrainsMono Nerd Font Mono, with the web JetBrains Mono as fallback for a shared file.
Ligatures are off, so code reads as typed. No shadows, blur, or background texture. Tokens
sit on `:root`. Dark mode redefines them under `prefers-color-scheme` and
`[data-theme="dark"]`.

## Iterating on the design

Install a sample note, then open the page. After an edit to `app.css` or `app.js`, run
`python3 bundle.py <slug>` to refresh a one-file copy:

```bash
python3 ../skills/onboard/check.py <note.json> --install
open "file://$HOME/.claude/.onboard/index.html"
```

Check a note with many links and one with none (`dotfiles`), each after **Expand all**.
Headless Chrome keeps a 500 px minimum viewport, so a narrower screenshot crops the page.
