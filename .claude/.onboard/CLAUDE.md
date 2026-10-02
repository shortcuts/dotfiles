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
| `vendor/` | ELK and the JetBrains Mono woff2 files, pinned by version and sha256 | no |
| `notes/<slug>.js` | One note, written by `check.py --install` | no |
| `notes/<slug>.html` | The note's one-file copy, written by `bundle.py` on each install | no |
| `notes/manifest.js` | The note list for the switcher, rebuilt on each install | no |
| `$ONBOARD_VAULT/Onboard/<title>.md` | The note's Obsidian page, written by `bundle.py` on each install | no |

`notes/` stays out of git: notes summarize employer code, and this dotfiles repo can be
public.

## Decisions

- **The idea, then the solution.** The title, the problem, and the words come first, so
  the reader knows why the system exists and what its terms mean before the map shows it.
  The map follows, then the principles, the life of the data, where to start reading, and
  the stack.
- **The map is the star.** The map and a side panel fill one screen height, at 3/4 and
  1/4 of its width. A box click selects the box and folds or unfolds it, and the panel
  shows that node: its path, summary, role, what is inside, who it talks to, where to
  start reading, and its outside services. A box shows only its name and kind, because
  the panel carries the rest.
  A linear paper with one section per node was tried first: it stacked the content and
  pushed the map down, but the map must carry the overview.
- **A part's flow takes the stage.** The panel is too narrow to read a graph, so a part
  with a flow gets **Show its data flow**. The flow covers the map at full size, and
  **Back to the map** removes it. A pick from the panel removes it too.
- **Source links stay quiet.** A link to GitHub or a vendor doc is small muted mono text
  with a dotted underline, at the end of its line. A loud link pulled the reader out of
  the page before they had the overview. A jump inside the page is a blue link.
- **Shared files, bundled at install.** A `file://` page cannot `fetch()` its own
  `app.js` to inline it, so the browser cannot build a one-file copy. `bundle.py` builds
  it at install instead: the page, the note, ELK, and the font in one HTML file of about
  1.7 MB. The file references nothing outside itself, so "Save as" or a mail attachment
  carries all of it. The download button links to it.
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
  With neither `vendor/` nor a network, the map shows a message, and the text still reads.
- **The fold state shows on each box.** A box a click unfolds has an accent stripe on its
  leading edge and a chevron pointing right in a soft accent circle. An unfolded frame has
  an accent band on its header and a solid accent circle with the chevron pointing down.
  A leaf has neither. The chevron turns, so the state change reads as one motion.
- **Drag pans, pinch zooms.** A pinch or Ctrl/⌘+wheel zooms at the pointer. A plain
  wheel scrolls the page: a canvas that took it trapped the reader at every figure. A
  drag of 4 px or more is a pan, not a click.
  **Fit**, **Expand all**, **Collapse**, and **Full screen** sit in the canvas corner. A
  flow with steps goes full screen with its step list, so the step text stays in view.
- **One title in the bar.** With more than one note, the switcher shows the title. With
  none, as in a one-file copy, the bar shows it, so the title stays in view on the map.
  The `h1` opens the page.
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
  The canvas code takes the canvas it acts on, so the map and each flow share it. Mermaid was dropped: a second layout engine
  drew a second visual language, and it doubled the bundle. With no ELK, a flow shows as a
  list of edges.
- **The text reads top-down.** The problem comes before the words: a reader new to the
  code needs the reason first. Nothing folds: every word and every entry point
  shows.
- **The life of the data is a step list under the flow.** Every step shows in full. A
  click on a step, or **←** and **→** on the keyboard, lights its shapes and the edges
  between them, and the rest dims. The arrows drive the flow the pointer last entered.
  Each step zooms to its shapes, with a margin for their neighbours. **Fit** shows the
  whole graph. A flow with no `lifecycle` gets no steps: its labeled edges carry it.
- **A flow lays out near the viewport.** The lifecycle flow sits below the fold, so it
  waits for an IntersectionObserver 800 px ahead of the scroll. A wide flow opens at
  70 % zoom from its left end, because below that its labels stop reading.
- **Three box types.** A package keeps the plain box. A service has a heavy rounded frame.
  A store (a database, a queue, a bucket) is a cylinder. Only flow shapes carry the data
  today: `store` marks the cylinder, and every other shape is a service. The map's boxes
  stay package boxes until the note marks services and stores (backlog:
  "onboard: runtime view so the map shows services first").
- **Links pin to `repo.sha`.** A branch link drifts as the code moves. With `repo.web`
  null, the links open `vscode://file/…`.
- **No layout shift.** The map and each flow slot have a fixed height, so a fold or a late
  layout never moves the text. The flow layout is cached per source.
  The selected box gets an outline, never a new size. Fonts load with
  `display=optional`, and `scrollbar-gutter: stable` holds the width when a long note adds
  a scrollbar.
- **One box geometry.** Every folded box has one fixed size: a name line and a kind line.
  A frame header has the same two lines. The full summary sits in the
  panel and in the tooltip. The monospace face makes a link label's width a character
  count, so ELK gets exact label sizes without measuring the DOM.
- **Figures leave the text measure.** Text stops at 68ch. The lifecycle flow spans the
  content column, so a wide graph gets room.
- **Laptop screens only.** The page targets an 11-inch screen or larger, so it has no
  narrow layout.

## Design tokens

Light only: drafting paper. A yellow sheet `#f6f0d4`, graphite ink `#1c2430`, and a blue
pencil `#1f5a96` for what a click reaches. A dark theme was dropped, so one palette gets
all the contrast work. Muted text `#5c584b` measures over 6:1 on the paper. The map and
the flows sit on a lighter sheet with an engineering grid, so the figures read apart from
the text. The link directions use purple and orange, which stay apart under red-green
color blindness.

Two faces. Body text is Charter, a system serif on every Mac, so a bundle inlines no
extra font: 18 px, line height 1.7, 68ch measure. Code, paths, section numbers, and the
canvases use JetBrainsMono Nerd Font Mono, with JetBrains Mono as fallback for a shared
file. The canvases stay mono, because a link label's width is a character count. Ligatures
are off, so code reads as typed. No shadows or blur. Tokens sit on `:root`.

## Iterating on the design

Install a sample note, then open the page. After an edit to `app.css` or `app.js`, run
`python3 bundle.py <slug>` to refresh a one-file copy:

```bash
python3 ../skills/onboard/check.py <note.json> --install
open "file://$HOME/.claude/.onboard/index.html"
```

Check a note with many links and one with none (`dotfiles`), each after **Expand all**.
Headless Chrome keeps a 500 px minimum viewport, so a narrower screenshot crops the page.
Take screenshots in real time, over the DevTools protocol: under `--virtual-time-budget`,
an IntersectionObserver never fires on scroll, so the flows below the fold stay empty.
