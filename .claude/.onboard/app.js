(() => {
const O = window.ONBOARD;
// bundle.py sets the flag in a one-file copy, which carries one note and no switcher.
const standalone = !!O.standalone;
const app = document.getElementById("app");

const h = (tag, attrs = {}, ...kids) => {
  const el = tag === "svg"
    ? document.createElementNS("http://www.w3.org/2000/svg", tag)
    : document.createElement(tag);
  for (const [k, v] of Object.entries(attrs)) {
    if (v == null || v === false) continue;
    if (k.startsWith("on")) el.addEventListener(k.slice(2), v);
    else if (k === "html") el.innerHTML = v;
    else el.setAttribute(k, v === true ? "" : v);
  }
  el.append(...kids.flat(Infinity).filter((x) => x != null && x !== false));
  return el;
};

const readHash = () => Object.fromEntries(new URLSearchParams(location.hash.slice(1)));
const writeHash = (note, node, open) => {
  const p = new URLSearchParams({ note });
  if (node) p.set("node", node);
  if (open?.size) p.set("open", [...open].join(","));
  history.replaceState(null, "", "#" + p);
};

function loadNote(slug) {
  if (O.notes[slug]) return Promise.resolve(O.notes[slug]);
  return new Promise((ok, fail) => {
    const s = h("script", { src: `notes/${slug}.js` });
    s.onload = () => (O.notes[slug] ? ok(O.notes[slug]) : fail(new Error(slug)));
    s.onerror = () => fail(new Error(slug));
    document.body.append(s);
  });
}

function index(root) {
  const byId = new Map(), parent = new Map(), links = [];
  (function walk(n, p) {
    byId.set(n.id, n);
    if (p) parent.set(n.id, p);
    (n.links || []).forEach((l) => links.push({ from: n.id, to: l.to, label: l.label }));
    (n.children || []).forEach((c) => walk(c, n));
  })(root, null);
  const lineage = (id) => {
    const out = [];
    for (let n = byId.get(id); n; n = parent.get(n.id)) out.unshift(n);
    return out;
  };
  const within = (top, id) => lineage(id).includes(top);
  // A service never unfolds on the map: its flow shows how its packages work together.
  const foldable = (n) => !!n.children?.length && !lineage(n.id).some((m) => m.kind === "service");
  return { byId, parent, links, lineage, within, foldable };
}

function link(note, path, lines) {
  const r = note.repo;
  if (!r.web) {
    const line = lines ? `:${lines[0]}` : "";
    return `vscode://file${r.path}/${path}${line}`;
  }
  if (lines) return `${r.web}/blob/${r.sha}/${path}#L${lines[0]}-L${lines[1]}`;
  return `${r.web}/tree/${r.sha}/${path}`;
}

// The vendor/ copy comes first, so the viewer works offline once bundle.py has fetched it.
// A one-file copy inlines the library, so the global exists before any load.
const libs = {};
function lib(name, file, cdn) {
  if (window[name]) return Promise.resolve(window[name]);
  return (libs[name] ||= new Promise((ok, fail) => {
    const load = (src, next) => document.head.append(h("script", { src, onload: () => ok(window[name]), onerror: next }));
    load(`vendor/${file}`, () => load(cdn, () => { delete libs[name]; fail(new Error(name)); }));
  }));
}

// A flow is a second canvas: the map's boxes, edges, pan, and zoom, so both graphs read alike.
// A store is taller: its cylinder lid takes the top of the box.
const SHAPE = { h: 40, store: 56, ch: 8 };
// A shape outside this repo: a vendor (`node: null`) or another repo's service (`external`).
const outside = (s) => s.node === null || !!s.external;
const rendering = new Map(), rendered = new Map();
function renderFlow(f) {
  const key = JSON.stringify(f);
  if (!rendering.has(key)) rendering.set(key, elk()
    .then((E) => E.layout({
      id: "flow",
      // `end` pins the source to the first layer and the destination to the last.
      children: f.nodes.map((n) => ({ id: n.id, width: n.name.length * SHAPE.ch + 32, height: n.store ? SHAPE.store : SHAPE.h,
        ...(n.end && { layoutOptions: { "elk.layered.layering.layerConstraint": n.end === "in" ? "FIRST" : "LAST" } }) })),
      edges: f.edges.map((e, i) => ({ id: `f${i}`, sources: [e.from], targets: [e.to],
        labels: [{ text: e.label, width: e.label.length * CH + 8, height: 14 }] })),
      // A loop (a sink the source also reads) would put the sink mid-graph; the node order breaks it.
      // A dense flow gets more vertical room between shapes, so its edges and labels stay apart.
      layoutOptions: { ...LAYERED, "elk.layered.cycleBreaking.strategy": "MODEL_ORDER",
        ...(f.nodes.length > 10 && { "elk.spacing.nodeNode": "64", "elk.spacing.edgeNode": "24", "elk.spacing.edgeEdge": "16" }) },
    }))
    .then((res) => rendered.set(key, res), () => null));
  // ponytail: a CDN slower than 3 s leaves the text list in place until a reload.
  return Promise.race([rendering.get(key), new Promise((ok) => setTimeout(ok, 3000))]);
}
// The arrow keys drive the stepper the pointer last entered; the first stepper takes them on load.
let stepKey = null;
addEventListener("keydown", (e) => stepKey?.(e));
// A flow lays out only near the viewport, so a panel switch never waits on one below the fold.
// The step list renders at once, so the text never waits on ELK and never shifts.
// An overlay flow is on screen already, so `now` draws it at once.
function flowFigure(f, steps, now, stage) {
  const items = (steps || []).map((s, i) => h("li", {}, h("button", { onclick: () => fig.show(i) }, s.text)));
  const slot = h("div", { class: "flow-slot" });
  // On the stage, the steps sit in a header that shows only the current one; the list stays for the keyboard and screen readers.
  const head = stage && items.length > 0 && h("div", { class: "step-head" },
    h("button", { "aria-label": "Previous step", onclick: () => fig.show((fig.at ?? 0) - 1) }, "←"),
    h("strong", { class: "count" }), h("button", { "aria-label": "Next step", onclick: () => fig.show((fig.at ?? 0) + 1) }, "→"),
    h("span", { class: "text" }));
  const fig = h("figure", { class: `flow-fig${stage ? " stage-flow" : ""}`, onpointerenter: () => fig.key && (stepKey = fig.key) },
    head, slot, items.length > 0 && h("ol", { class: "steps" }, items));
  fig.head = head;
  fig.show = () => {};
  const load = () => renderFlow(f).then(() => drawFlow(f, steps, slot, items, fig));
  if (now) load(); else { near.set(slot, load); nearby.observe(slot); }
  return fig;
}
const near = new WeakMap();
const nearby = new IntersectionObserver((es) => es.forEach((e) => {
  if (!e.isIntersecting) return;
  nearby.unobserve(e.target);
  near.get(e.target)();
}), { rootMargin: "800px" });
function drawFlow(f, steps, slot, items, fig) {
  const res = rendered.get(JSON.stringify(f)), stage = fig.classList.contains("stage-flow");
  const shape = new Map(f.nodes.map((n) => [n.id, n]));
  if (!res) return slot.replaceChildren(h("pre", { class: "flow-list" },
    f.edges.map((e) => `${shape.get(e.from).name} → ${shape.get(e.to).name}: ${e.label}`).join("\n")));
  const cv = { view: { x: 0, y: 0, k: 1 }, minK: stage ? 0.5 : 0.7, bounds: () => ({ x: 0, y: 0, width: res.width, height: res.height }) };
  Object.assign(cv, canvas(() => cv, "flow", "Data flow diagram. Drag to pan, pinch or Ctrl+scroll to zoom."));
  const boxes = new Map(res.children.map((n) => {
    const s = shape.get(n.id), to = s.node != null && current.idx.byId.has(s.node);
    // A shape with a tree node jumps to it: back on the map, with the panel on that node.
    // On the stage, a shape with no node shows its own `about` in the panel.
    const own = !to && stage && !!s.about;
    return [n.id, h(to || own ? "button" : "div", {
      class: `box shape ${s.store ? "store" : "svc"}${outside(s) ? " outside" : ""}${to || own ? " to" : ""}`,
      "data-node": to ? s.node : null, "data-shape": n.id,
      style: `left:${n.x}px;top:${n.y}px;width:${n.width}px;height:${n.height}px`,
      ...(to && { title: `Read about ${current.idx.byId.get(s.node).name} in the panel`, onclick: () => cv.dragged || go(s.node) }),
      ...(own && { title: `Read about ${s.name} in the panel`, onclick: () => cv.dragged || showShape(s) }),
    }, h("span", { class: "name" }, s.name))];
  }));
  cv.world.append(...boxes.values());
  const svg = h("svg", { width: res.width, height: res.height, "aria-hidden": "true" });
  svg.innerHTML = TIP + res.edges.map((e, i) =>
    `<g data-i="${i}">${marks(e, outside(shape.get(f.edges[i].from)) || outside(shape.get(f.edges[i].to)) ? " outside" : "", e.labels?.[0]?.text || "")}</g>`).join("");
  cv.world.append(svg);
  slot.replaceChildren(cv.map);
  fit(cv, false);
  if (current?.flowMap && current.map === fig) markShape(current);
  if (!items.length) return;

  // A step lights its shapes and the edges between them; the rest of the graph dims.
  let at = -1;
  fig.show = (i) => {
    at = fig.at = Math.max(0, Math.min(steps.length - 1, i));
    if (fig.head) {
      fig.head.querySelector(".count").textContent = `${at + 1} / ${steps.length}`;
      fig.head.querySelector(".text").textContent = steps[at].text;
    }
    if (stage) showStep(at);
    const on = new Set(steps[at].at);
    // The margin keeps the step's neighbours in view, so the reader sees where it sits.
    const lit = res.children.filter((n) => on.has(n.id));
    const x = Math.min(...lit.map((n) => n.x)) - 120, y = Math.min(...lit.map((n) => n.y)) - 60;
    cv.focus = { x, y, width: Math.max(...lit.map((n) => n.x + n.width)) + 120 - x,
      height: Math.max(...lit.map((n) => n.y + n.height)) + 60 - y };
    fit(cv, true);
    cv.map.classList.add("stepping");
    items.forEach((li, j) => li.toggleAttribute("aria-current", j === at));
    for (const [id, el] of boxes) el.classList.toggle("step", on.has(id));
    for (const g of svg.querySelectorAll("g[data-i]")) {
      const e = f.edges[g.dataset.i], hot = on.has(e.from) && on.has(e.to);
      for (const el of g.children) el.classList.toggle("hot", hot);
    }
  };
  fig.key = (e) => {
    // A closed overlay's stepper keeps the key until the pointer enters another flow.
    if (!fig.isConnected || e.target.closest?.("input, select, textarea") || e.metaKey || e.ctrlKey || e.altKey) return;
    const d = { ArrowLeft: -1, ArrowRight: 1 }[e.key];
    if (d) { e.preventDefault(); fig.show(at + d); }
  };
  stepKey ||= fig.key;
  // The map opens on its first step: the whole graph is too small to read at the width of the stage.
  // A node named in the hash keeps the panel; the map still zooms to the first step.
  if (stage) { const keep = current.sel; fig.show(0); if (keep && !keep.startsWith("shape:")) pick(keep, false); }
}

const chevron = () => {
  const s = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  s.setAttribute("width", "14"); s.setAttribute("height", "14"); s.setAttribute("viewBox", "0 0 16 16");
  s.innerHTML = '<path d="M4 6l4 4 4-4" fill="none" stroke="currentColor" stroke-width="1.6"/>';
  return s;
};

// A source link is quiet: the reader finishes the overview before leaving for GitHub.
const src = (href, text) => h("a", { class: "src", href, target: "_blank", rel: "noopener" }, text);
// Siblings can share a name, so a jump to a twin also names its parent folder.
const jump = (idx, n) => {
  const twin = [...idx.byId.values()].some((m) => m !== n && m.name === n.name);
  const where = twin && n.path && n.path.split("/").slice(-2, -1)[0];
  return [h("button", { class: "jump", onclick: () => go(n.id) }, n.name), where && h("span", { class: "ref" }, ` in ${where}`)];
};

// A term from the words gets a small mark that jumps to its definition, like a paper's
// footnote: a reader who knows the term reads on. One mark per term per block.
function gloss(note, text) {
  const ws = note.words || [];
  if (!ws.length || !text) return text;
  const alt = ws.map((w) => w.term).sort((a, b) => b.length - a.length)
    .map((t) => t.replace(/[.*+?^${}()|[\]\\]/g, "\\$&")).join("|");
  const seen = new Set(), out = [];
  let last = 0;
  for (const m of text.matchAll(new RegExp(`(?<!\\w)(?:${alt})(?!\\w)`, "gi"))) {
    const w = ws.find((w) => w.term.toLowerCase() === m[0].toLowerCase());
    if (seen.has(w)) continue;
    seen.add(w);
    const end = m.index + m[0].length;
    out.push(text.slice(last, end), h("sup", { class: "wref", title: `${w.term}: ${w.def}` }, "*"));
    last = end;
  }
  out.push(text.slice(last));
  return out;
}

// The panel says what the reader is looking at, and nothing else: one node, one shape, or one step.
const panelBox = (...kids) => h("aside", { class: "panel", "aria-live": "polite" }, ...kids);
function panel(note, idx, node) {
  const up = idx.lineage(node.id).slice(1, -1);
  return panelBox(
    up.length > 0 && h("nav", { class: "crumbs", "aria-label": "Path" },
      up.map((n) => [h("button", { class: "jump", onclick: () => go(n.id) }, n.name), h("span", { "aria-hidden": "true" }, " / ")])),
    h("p", { class: "meta" }, node.kind, node.path != null && [" at ", src(link(note, node.path), node.path || "/")]),
    h("h2", {}, node.name),
    h("p", { class: "lead" }, gloss(note, node.summary)),
    node.role.map((p) => h("p", {}, gloss(note, p))),
    node !== note.root && node.flow && h("button", { class: "see", onclick: () => showFlow(node) }, "Show its data flow"),
    node !== note.root && node.children?.length > 0 && [h("h3", {}, "Inside"), h("ul", { class: "facts" }, node.children.map((c) =>
      h("li", {}, jump(idx, c), h("span", { class: "how" }, c.summary))))]);
}
function setPanel(p, sel) {
  const c = current;
  c.panel.replaceWith(p);
  c.panel = p;
  c.sel = sel;
  if (c.flowMap) markShape(c);
}
function showStep(i) {
  const c = current, steps = c.note.root.lifecycle;
  setPanel(panelBox(h("p", { class: "meta" }, `step ${i + 1} of ${steps.length}`),
    h("h2", { class: "step-title" }, steps[i].text),
    steps[i].detail && h("p", {}, gloss(c.note, steps[i].detail))), null);
}
function showShape(s) {
  setPanel(panelBox(h("p", { class: "meta" }, s.store ? "store" : outside(s) ? "outside this repo" : "service"),
    h("h2", {}, s.name),
    h("p", {}, gloss(current.note, s.about)),
    s.external?.url?.startsWith("https://") && h("p", {}, src(s.external.url, "docs"))), "shape:" + s.id);
}

// The page opens on the title and the overview, then the map with its panel: nothing else.
function page(note, stage) {
  const r = note.repo, at = `${r.name} at ${r.sha.slice(0, 7)}`;
  return [h("article", { class: "paper intro" },
    h("header", { class: "title" },
      h("h1", {}, note.title),
      h("p", { class: "meta" }, r.web ? src(`${r.web}/tree/${r.sha}`, at) : at, `, written ${note.generated}`),
      h("p", { class: "lead" }, gloss(note, note.root.overview ?? note.root.summary)))), stage];
}

// The word before the colon says how the data moves; the payload stays in the panel.
const word = (label) => label.split(":")[0].trim();

let elkReady;
function elk() {
  elkReady ||= lib("ELK", "elk.bundled.js", "https://cdn.jsdelivr.net/npm/elkjs@0.10.2/lib/elk.bundled.js")
    .then((E) => new E(), (e) => { elkReady = null; throw e; });
  return elkReady;
}

// The monospace face makes a label's width a character count.
// A box holds its name and its kind; the panel holds the rest.
const LEAF = { w: 232, h: 58 }, HEAD = 58, CH = 6.6;
const esc = (t) => t.replace(/&/g, "&amp;").replace(/</g, "&lt;");
const TIP = `<defs><marker id="tip" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="6" markerHeight="6" orient="auto"><path d="M0,0L8,4L0,8z" style="fill:context-stroke"/></marker></defs>`;
// One ELK edge as SVG: its path, then its label with the full text as a tooltip.
function marks(e, on, title) {
  const out = (e.sections || []).map((s) => {
    const pts = [s.startPoint, ...(s.bendPoints || []), s.endPoint];
    return `<path class="edge${on}" marker-end="url(#tip)" d="M${pts.map((p) => `${p.x},${p.y}`).join(" L")}"/>`;
  });
  const lb = e.labels?.[0];
  if (lb) out.push(`<text class="elabel${on}" x="${lb.x + lb.width / 2}" y="${lb.y + lb.height - 3}"><title>${esc(title)}</title>${esc(lb.text)}</text>`);
  return out.join("");
}
const LAYERED = {
  "elk.algorithm": "layered", "elk.direction": "RIGHT",
  "elk.edgeRouting": "ORTHOGONAL", "elk.edgeLabels.placement": "CENTER",
  "elk.spacing.nodeNode": "28", "elk.layered.spacing.nodeNodeBetweenLayers": "56",
  "elk.spacing.edgeLabel": "4", "elk.layered.spacing.edgeNodeBetweenLayers": "20",
};

// The deepest node the reader can see on the path to `id`: the first folded one.
const shown = (idx, open, id) => idx.lineage(id).find((n) => !open.has(n.id) || !idx.foldable(n));

function graph(idx, open) {
  const edges = new Map();
  for (const l of idx.links) {
    const a = shown(idx, open, l.from), b = shown(idx, open, l.to);
    if (a === b) continue;
    const e = edges.get(`${a.id}\u0000${b.id}`) || { a, b, words: new Set(), raw: [] };
    e.words.add(word(l.label));
    e.raw.push(l);
    edges.set(`${a.id}\u0000${b.id}`, e);
  }
  // Layered layout stacks unlinked siblings in one tall column, so a frame with no link
  // inside packs its children instead.
  // ponytail: a frame with some links still stacks its unlinked children; pack those too if notes get wide.
  const linked = new Set([...edges.values()].flatMap((e) => [...idx.lineage(e.a.id), ...idx.lineage(e.b.id)]));
  const box = (n) => open.has(n.id) && idx.foldable(n)
    ? { id: n.id, children: n.children.map(box), layoutOptions: {
        "elk.padding": `[top=${HEAD + 12},left=16,bottom=16,right=16]`,
        "elk.nodeSize.constraints": "MINIMUM_SIZE", "elk.nodeSize.minimum": `(${LEAF.w}, ${LEAF.h})`,
        ...(!linked.has(n) && { "elk.hierarchyHandling": "SEPARATE_CHILDREN", "elk.algorithm": "rectpacking",
          "elk.aspectRatio": "1.6", "elk.spacing.nodeNode": "20" }) } }
    : { id: n.id, width: LEAF.w, height: LEAF.h };
  const list = [...edges.values()];
  return { list, elk: {
    id: "\u0000", children: [box(idx.byId.get(current.note.root.id))],
    edges: list.map((e, i) => {
      const text = [...e.words].join(", ");
      return { id: `e${i}`, sources: [e.a.id], targets: [e.b.id], labels: [{ text, width: text.length * CH + 8, height: 14 }] };
    }),
    layoutOptions: {
      ...LAYERED, "elk.hierarchyHandling": "INCLUDE_CHILDREN",
      "elk.json.shapeCoords": "ROOT", "elk.json.edgeCoords": "ROOT",
    } } };
}

// A canvas is { map, world, view, bounds }: the main map, or one flow.
function applyView(cv, anim) {
  const { world, view: v } = cv;
  world.classList.toggle("anim", !!anim);
  world.style.transform = `translate(${v.x}px,${v.y}px) scale(${v.k})`;
}

// A flow stepper sets cv.focus, so a resize keeps the step in view; Fit shows the whole graph.
// A flow sets cv.minK: past that zoom its labels stop reading, so a wide flow starts at its
// left end instead, and the reader drags. Fit passes 0.1 to show the whole graph anyway.
function fit(cv, anim, r = cv.focus || cv.bounds(), minK = cv.minK || 0.1) {
  const { map, view: v } = cv;
  if (!r || !map.clientWidth) return;
  const W = map.clientWidth, H = map.clientHeight;
  v.k = Math.max(minK, Math.min(1, (W - 48) / r.width, (H - 72) / r.height));
  v.x = Math.max(24 - r.x * v.k, (W - r.width * v.k) / 2 - r.x * v.k);
  v.y = (H - 36 - r.height * v.k) / 2 - r.y * v.k;
  applyView(cv, anim);
}

function center(id) {
  const { map, pos, view: v } = current;
  // A package inside a service has no box of its own: center the service.
  const r = pos.get(id) || pos.get(shown(current.idx, current.open, id).id);
  v.x = map.clientWidth / 2 - (r.x + r.width / 2) * v.k;
  v.y = map.clientHeight / 2 - (r.y + r.height / 2) * v.k;
  applyView(current, true);
}

// Each draw is a fresh ELK layout; a later click cancels an earlier one still in flight.
let drawSeq = 0;
async function draw() {
  const c = current, seq = ++drawSeq;
  const { list, elk: g } = graph(c.idx, c.open);
  let res;
  try { res = await (await elk()).layout(g); } catch {
    c.world.replaceChildren();
    c.map.querySelector(".msg")?.remove();
    c.map.append(h("div", { class: "msg" }, "The layout engine did not load. Run bundle.py once with a network connection."));
    return;
  }
  if (seq !== drawSeq || c !== current) return;
  c.map.querySelector(".msg")?.remove();
  const pos = new Map();
  (function walk(n) { for (const k of n.children || []) { pos.set(k.id, k); walk(k); } })(res);
  c.pos = pos;

  const sel = c.idx.byId.get(c.sel);
  // Only links that cross the selection's border light up: inside a frame, everything would.
  // One drawn edge joins two boxes, so its links all cross the border the same way.
  const crosses = (l) => c.idx.within(sel, l.from) !== c.idx.within(sel, l.to);
  const hot = (e) => e.raw.some(crosses);
  const dir = (e) => { const l = e.raw.find(crosses); return !l ? "" : c.idx.within(sel, l.from) ? " out" : " in"; };
  const near = new Set(list.filter(hot).flatMap((e) => [e.a.id, e.b.id]));
  // A selection with no box of its own, as a package inside a service, marks its box.
  const mark = (shown(c.idx, c.open, c.sel) || sel).id;
  for (const [id, el] of c.boxes) if (!pos.has(id)) { el.remove(); c.boxes.delete(id); }
  for (const [id, r] of pos) {
    const n = c.idx.byId.get(id), isOpen = !!r.children?.length;
    let el = c.boxes.get(id);
    if (!el) {
      const count = n.children?.length || 0, fold = c.idx.foldable(n);
      el = h("div", { class: `box${fold ? " can" : ""}${n.kind === "service" ? " svc" : ""}`, "data-id": id, style: `z-index:${c.idx.lineage(id).length}` },
        h("button", { class: "head", title: n.summary, "aria-expanded": fold ? "false" : null,
          onclick: () => c.dragged || pick(id, true) },
          h("span", { class: "name" }, n.name),
          h("span", { class: "more" }, count ? `${n.kind}, ${count} inside` : n.kind),
          fold && h("span", { class: "tog", "aria-hidden": "true" }, chevron())));
      c.boxes.set(id, el);
      c.world.append(el);
    }
    el.classList.toggle("open", isOpen);
    el.classList.toggle("rel", near.has(id) && id !== mark);
    el.toggleAttribute("aria-current", id === mark);
    if (c.idx.foldable(n)) el.firstChild.setAttribute("aria-expanded", String(isOpen));
    Object.assign(el.style, { left: `${r.x}px`, top: `${r.y}px`, width: `${r.width}px`, height: `${r.height}px` });
  }

  const parts = [TIP, ...res.edges.map((e, i) =>
    marks(e, dir(list[i]), list[i].raw.map((l) => l.label).join("\n")))];
  c.svg?.remove();
  c.svg = h("svg", { width: res.width, height: res.height, "aria-hidden": "true", style: "z-index:999" });
  c.svg.innerHTML = parts.join("");
  c.world.append(c.svg);
}

function pan(map, get) {
  let start = null;
  map.addEventListener("pointerdown", (e) => {
    if (e.button !== 0 || e.target.closest(".tools")) return;
    start = { x: e.clientX, y: e.clientY, vx: get().view.x, vy: get().view.y, id: e.pointerId };
    get().dragged = false;
  });
  map.addEventListener("pointermove", (e) => {
    if (!start) return;
    const dx = e.clientX - start.x, dy = e.clientY - start.y;
    // A small slip during a click stays a click.
    if (!get().dragged && Math.hypot(dx, dy) < 4) return;
    if (!get().dragged) { get().dragged = true; map.setPointerCapture(start.id); map.classList.add("drag"); }
    get().view.x = start.vx + dx; get().view.y = start.vy + dy;
    applyView(get(), false);
  });
  const end = () => {
    start = null; map.classList.remove("drag");
    // The click event fires after pointerup, so the flag clears one task later.
    setTimeout(() => (get().dragged = false));
  };
  map.addEventListener("pointerup", end);
  map.addEventListener("pointercancel", end);
  // A pinch arrives as ctrl+wheel and zooms. A plain wheel scrolls the paper: a canvas that
  // took it would trap the reader at every figure on the way down.
  map.addEventListener("wheel", (e) => {
    if (!e.ctrlKey && !e.metaKey) return;
    e.preventDefault();
    const v = get().view;
    const b = map.getBoundingClientRect(), mx = e.clientX - b.left, my = e.clientY - b.top;
    const k = Math.min(2.5, Math.max(0.1, v.k * Math.exp(-e.deltaY * 0.01)));
    v.x = mx - ((mx - v.x) * k) / v.k; v.y = my - ((my - v.y) * k) / v.k; v.k = k;
    applyView(get(), false);
  }, { passive: false });
}

function zoom(cv, f) {
  const { map, view: v } = cv;
  const k = Math.min(2.5, Math.max(0.1, v.k * f)), mx = map.clientWidth / 2, my = map.clientHeight / 2;
  v.x = mx - ((mx - v.x) * k) / v.k; v.y = my - ((my - v.y) * k) / v.k; v.k = k;
  applyView(cv, true);
}

let current;
// Select a node: the panel follows it. A click on a node with children also folds or unfolds it.
// A fold moves every box, so the map fits again and the reader sees the whole new layout.
async function pick(id, toggle) {
  const c = current, node = c.idx.byId.get(id), was = c.open.size;
  if (c.flowMap) {
    // The flow is the map: a pick only moves the panel and the mark on the shapes.
    writeHash(c.note.slug, id);
    c.over?.remove(); c.over = null;
    setPanel(panel(c.note, c.idx, node), id);
    return true;
  }
  if (toggle && c.idx.foldable(node)) c.open.has(id) ? c.open.delete(id) : c.open.add(id);
  for (const n of c.idx.lineage(id).slice(0, -1)) if (c.idx.foldable(n)) c.open.add(n.id);
  c.sel = id;
  writeHash(c.note.slug, id, c.open);
  c.over?.remove(); c.over = null;
  const p = panel(c.note, c.idx, node);
  c.panel.replaceWith(p);
  c.panel = p;
  await draw();
  // Folds only add or only remove within one pick, so the size tells whether the layout moved.
  const moved = c.open.size !== was;
  if (moved) fit(current, true);
  return moved;
}
// The shape of the deepest node on the path to the selection gets the mark, so a package marks its service.
function markShape(c) {
  const els = [...c.map.querySelectorAll(".box.shape")];
  const hit = c.sel?.startsWith("shape:") ? els.find((e) => e.dataset.shape === c.sel.slice(6))
    : c.sel && c.idx.lineage(c.sel).reverse().map((n) => els.find((e) => e.dataset.node === n.id)).find(Boolean);
  els.forEach((e) => e.toggleAttribute("aria-current", e === hit));
}
// A part's flow takes the map's place on the stage: the panel is too narrow to read a graph.
// A service's lifecycle brings the same step list as the life of the data.
function showFlow(node) {
  const c = current;
  c.over?.remove();
  c.over = h("div", { class: "over" },
    h("div", { class: "over-head" }, h("strong", {}, `How the data moves in ${node.name}`),
      node.lifecycle?.length > 0 && h("span", { class: "hint" }, "Click a step, or press ← and →, to light it on the graph."),
      h("button", { class: "see", onclick: () => { c.over.remove(); c.over = null; } }, "Back to the map")),
    flowFigure(node.flow, node.lifecycle, true));
  c.map.after(c.over);
}
// From the panel: reveal the node. With no fold, bring it to the middle instead.
function go(id) {
  current.map.scrollIntoView({ block: "nearest" });
  pick(id, false).then((moved) => moved || center(id));
}

function canvas(get, cls, label, ...extra) {
  const world = h("div", { class: "world" });
  const tools = h("div", { class: "tools" },
    h("button", { "aria-label": "Zoom out", onclick: () => zoom(get(), 1 / 1.25) }, "−"),
    h("button", { "aria-label": "Zoom in", onclick: () => zoom(get(), 1.25) }, "+"),
    h("button", { onclick: () => fit(get(), true, get().bounds(), 0.1) }, "Fit"), ...extra,
    h("button", { onclick: (e) => full(get(), e.currentTarget) }, "Full screen"));
  const map = h("section", { class: `map ${cls}`, "aria-label": label }, world, tools,
    cls === "tree" && h("div", { class: "legend", "aria-hidden": "true" },
      h("span", { class: "in" }, "input"), h("span", { class: "out" }, "output")));
  pan(map, get);
  // The canvas resizes more than once on its way in or out of full screen, so each resize
  // fits again for a second. A plain window resize keeps the reader's pan.
  let isFull = false, until = 0;
  new ResizeObserver(() => {
    const f = !!document.fullscreenElement?.contains(map);
    if (f !== isFull) { isFull = f; until = Date.now() + 1000; }
    if (f || Date.now() < until) fit(get(), false);
  }).observe(map);
  return { map, world };
}

// A flow goes full screen with its step list, so the text still says which step shows.
function full(cv, btn) {
  const el = cv.map.closest(".flow-fig") || cv.map;
  if (document.fullscreenElement) return document.exitFullscreen();
  el.onfullscreenchange = () => (btn.textContent = document.fullscreenElement === el ? "Exit full screen" : "Full screen");
  el.requestFullscreen();
}

const mapView = () => canvas(() => current, "tree", "Map. Drag to pan, pinch or Ctrl+scroll to zoom.",
  h("button", { onclick: () => {
    current.idx.byId.forEach((n) => current.idx.foldable(n) && current.open.add(n.id));
    draw().then(() => fit(current, true));
  } }, "Expand all"),
  h("button", { onclick: () => {
    current.open = new Set([current.note.root.id]);
    pick(current.note.root.id, false).then(() => fit(current, true));
  } }, "Collapse"));

async function open(slug, nodeId, openIds) {
  const note = await loadNote(slug);
  document.title = note.title;
  stepKey = null;
  const switcher = !standalone && O.list.length > 1;
  // The select shows the title; with no switcher, the bar names the note, since the map fills the first screen.
  const bar = h("header", { class: "bar" },
    !switcher && h("span", { class: "bar-title" }, note.title),
    switcher && h("select", {
      "aria-label": "Switch note",
      onchange: (e) => open(e.target.value).catch(fail),
    }, O.list.map((n) => h("option", { value: n.slug, selected: n.slug === slug }, n.title))),
    !standalone && h("a", { class: "share", href: `notes/${slug}.html`, download: `${slug}.html` }, "Download as one file"));
  // A note with a root flow draws that flow as the map; the box map stays for a note without one.
  const flowMap = !!note.root.flow;
  const { map, world } = flowMap ? {} : mapView();
  const idx = index(note.root), side = h("aside");
  const fig = flowMap && flowFigure(note.root.flow, note.root.lifecycle, true, true);
  app.replaceChildren(bar, h("main", {}, page(note, h("div", { class: "stage" }, fig || map, side))));
  const unfolded = new Set([note.root.id, ...(openIds || "").split(",").filter((id) => idx.byId.has(id) && idx.foldable(idx.byId.get(id)))]);
  current = flowMap ? { note, idx, flowMap, map: fig, panel: side, open: new Set([note.root.id]), over: null } : { note, idx, map, world, panel: side, open: unfolded, boxes: new Map(), pos: new Map(), view: { x: 0, y: 0, k: 1 },
    bounds: () => current.pos.get(note.root.id) };
  // The flow map's panel starts on step one, once the flow draws, unless the hash names a node.
  if (!flowMap || idx.byId.has(nodeId) || !note.root.lifecycle?.length) await pick(idx.byId.has(nodeId) ? nodeId : note.root.id, false);
  if (!flowMap) fit(current, false);
}

function fail() {
  app.replaceChildren(h("div", { class: "empty" },
    h("p", {}, "No onboarding notes yet."),
    h("p", {}, "Run ", h("code", {}, "/onboard"), " in a repository to write the first one.")));
}

const want = readHash();
const first = standalone ? Object.keys(O.notes)[0] : want.note || O.list[0]?.slug;
if (first) open(first, want.node, want.open).catch(fail); else fail();
})();
