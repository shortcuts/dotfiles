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

- **Overview, then the map, and nothing below.** The page opens on the title and the root
  `overview`, two to five sentences that give the whole idea, then the stage: the map at
  the left, the panel at the right. Numbered sections below the map were dropped: the
  reader scrolled away from the map to read the content that explains it.
- **The panel shows only the selection.** On the flow map, the panel shows the current
  step: its number, its text, and its `detail`, a concrete explanation of that stage. A
  click on a shape shows that shape instead: a tree node's summary and role, or a shape's
  own `about`. A tree node's panel adds **Show its data flow** and its **Inside** list.
  The principles, the problem, the entry points, the links, the stack, and the words were
  dropped from the panel: next to the map they read as noise. They stay in the note and in
  the Obsidian page, and each word still marks its terms with a `*` whose tooltip holds the
  definition.
- **The map is the star.** The map and a side panel fill one screen height, at 3/4 and
  1/4 of its width. A box click selects the box, and folds or unfolds it unless it is a
  service. A service box never unfolds: the panel lists its packages, and its flow carries
  how they work together. A package inside a service marks the service box. The panel
  shows the selected node: its path, summary, role, what is inside, who it talks to, where to
  start reading, and its outside services. A box shows only its name and kind, because
  the panel carries the rest.
  A linear paper with one section per node was tried first: it stacked the content and
  pushed the map down, but the map must carry the overview.
- **A root flow is the map.** A note with a root `flow` draws that flow on the stage, and
  the panel stays at its right. The box map and a separate life-of-the-data figure were two
  drawings of one system. A shape with a `node` selects that node in the panel and gets an
  outline; the panel's Inside list is how the reader walks the tree. The map opens on step
  one, because the whole graph is too small to read at the width of the stage. A note with
  no root flow keeps the box map.
- **A flow's steps sit in a header.** A bar above the map, or above a part's flow, shows **←**, the current step
  number (`2 / 6`), **→**, and that step's text. A step change also moves the panel. A full list under the map took a third of
  the stage height. The list stays in the page, visually hidden, for screen readers.
- **A flow reads top-down.** Left to right, each edge label took a column of its own, so
  the root flow was three screens wide and **Fit** shrank it past reading. Top-down, a
  label sits across a layer, and the stage's spare height holds the layers. A flow with
  more than 10 shapes gets more space between shapes, so its edges and labels stay apart.
- **A group is a frame.** Shapes with one `group` (the model providers, the services of
  another cloud project) sit in one tinted frame with the group name in its corner. The
  frame is solid, because dashed means outside this repo. Only the note can say who
  owns what, so the viewer never infers a group. In a flow with groups, the list order of
  the shapes is the layout hint, because ELK honors no placement hint on a frame. A shape
  listed earlier sits further left in its layer. Edges still set the layers, so the groups
  stack top-down by data direction.
- **A part's flow takes the stage.** The panel is too narrow to read a graph, so a part
  with a flow gets **Show its data flow**. The flow covers the map at full size, and
  **Back to the map** removes it. A pick from the panel removes it too. A service's flow
  brings its `lifecycle` as steps in that header. A list under its graph scrolled on its own
  and took a third of the height. A shape whose
  `node` names a tree node is a button: a click goes back to the map and selects that node.
- **Stores hide by default.** A flow with a `store` shape opens in a simple view: each store
  drops out, and each shape that fed it links to each shape that read it, with the feeding
  edge's label. A store with only readers or only writers drops with its edges. The
  **Stores** button in the canvas corner brings them back in every flow, and the hash keeps
  the choice (`stores=1`). A step that names only hidden stores lights their neighbours. A
  flow with no store shows no button. The reader meets the services first; the databases and
  queues are the second pass.
- **Dashed means outside this repo.** A shape with `node: null` or `external`, and each
  edge that touches one, is dashed: another repo's service or a vendor. A frame on the map
  has a solid border, so dashed keeps one meaning. Async shows in the label only.
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
- **A click never moves the view.** A fold, a select, a panel link, and a shape click leave
  the pan and zoom alone, so the layout does not shift under the pointer. Only the flow
  stepper (**←**, **→**, a step click) and **Fit**, **Expand all**, **Collapse** move it.
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
  flow with steps goes full screen with its step header, so the step text stays in view.
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
  iCloud is a personal account, and the notes summarize employer code. Flows, lifecycles,
  and node pointers stay out of it: they read only as graphs.
- **A flow is a second map.** A flow is shapes and edges as data. It gets its own canvas
  with the map's boxes, edges, pan, zoom, and **Fit**, so the two graphs read and move alike.
  The canvas code takes the canvas it acts on, so the map and each flow share it. Mermaid was dropped: a second layout engine
  drew a second visual language, and it doubled the bundle. With no ELK, a flow shows as a
  list of edges. `end` pins a shape to the first or the last layer in every flow, the
  root's and each service's.
- **The words are tooltips.** The first use of a term in a block of prose gets a small dim
  `*` whose tooltip holds the definition. A reader who knows the term reads on. A words
  section, first above the map and then at the foot of the page, was too loud.
- **The text reads top-down.** Nothing folds: every word and every entry point shows.
- **A shape click lights the shape's own flow.** The shape gets the outline, its
  incoming edges turn purple and its outgoing edges orange, and the shapes at their far
  ends light up. The step's shapes go dark, the header shows `– / 6`, and **→** steps
  on. The in and out legend shows only then. Keeping the step lit hid what the click
  asked for.
- **A step lights its part of the flow.** A
  click on a step, or **←** and **→** on the keyboard, lights its shapes and the edges
  between them, and the rest dims. The arrows drive the flow the pointer last entered.
  Each step zooms to its shapes, with a margin for their neighbours. **Fit** shows the
  whole graph. A flow with no `lifecycle` gets no steps: its labeled edges carry it.
- **A flow lays out near the viewport.** A flow below the fold waits for an
  IntersectionObserver 800 px ahead of the scroll. A wide flow opens at 70 % zoom from its
  left end, because below that its labels stop reading; the map's floor is 50 %. A flow on
  the stage is on screen already, so it lays out at once.
- **A decision is a rhombus.** A flow shape with `decision: true` branches the flow, such as
  a cache hit or miss. A stretched SVG polygon draws it, so the border keeps one width.
  An edge with `both: true` has an arrow at each end: a call that answers.
- **Three box types.** A package keeps the plain box. A service has a heavy rounded frame.
  A store (a database, a queue, a bucket) is a cylinder. Flow shapes carry it as `store`. On
  the map, a `service` node gets the service frame, and every other node keeps the package
  box. The tree has no store node, so stores show only in flows.
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
- **Figures leave the text measure.** Text stops at 68ch. The stage spans the window, so
  a wide graph gets room.
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
