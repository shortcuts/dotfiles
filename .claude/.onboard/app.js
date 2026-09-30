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
  return { byId, parent, links, lineage, within };
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
// Each flow lays out before its panel enters the page, so the diagram never pushes text down.
const SHAPE = { h: 40, ch: 8 };
const rendering = new Map(), rendered = new Map();
function renderFlow(f) {
  const key = JSON.stringify(f);
  if (!rendering.has(key)) rendering.set(key, elk()
    .then((E) => E.layout({
      id: "flow",
      children: f.nodes.map((n) => ({ id: n.id, width: n.name.length * SHAPE.ch + 32, height: SHAPE.h })),
      edges: f.edges.map((e, i) => ({ id: `f${i}`, sources: [e.from], targets: [e.to],
        labels: [{ text: e.label, width: e.label.length * CH + 8, height: 14 }] })),
      layoutOptions: LAYERED,
    }))
    .then((res) => rendered.set(key, res), () => null));
  // ponytail: a CDN slower than 3 s shows the text list until the next visit to the node.
  return Promise.race([rendering.get(key), new Promise((ok) => setTimeout(ok, 3000))]);
}
// The arrow keys drive the stepper of the panel on screen; each panel sets its own.
let stepKey = null;
addEventListener("keydown", (e) => stepKey?.(e));
function flow(f, steps) {
  const res = rendered.get(JSON.stringify(f));
  const shape = new Map(f.nodes.map((n) => [n.id, n]));
  if (!res) return [h("pre", { class: "flow-list" },
    f.edges.map((e) => `${shape.get(e.from).name} → ${shape.get(e.to).name}: ${e.label}`).join("\n")),
    steps && h("ol", { class: "steps" }, steps.map((s) => h("li", {}, s.text)))];
  const cv = { view: { x: 0, y: 0, k: 1 }, bounds: () => ({ x: 0, y: 0, width: res.width, height: res.height }) };
  Object.assign(cv, canvas(() => cv, "flow", "Data flow diagram. Drag to pan, pinch or Ctrl+scroll to zoom."));
  const boxes = new Map(res.children.map((n) => [n.id, h("div", {
    class: shape.get(n.id).store ? "box shape store" : "box shape",
    style: `left:${n.x}px;top:${n.y}px;width:${n.width}px;height:${n.height}px`,
  }, h("span", { class: "name" }, shape.get(n.id).name))]));
  cv.world.append(...boxes.values());
  const svg = h("svg", { width: res.width, height: res.height, "aria-hidden": "true" });
  svg.innerHTML = TIP + res.edges.map((e, i) =>
    `<g data-i="${i}">${marks(e, "", e.labels?.[0]?.text || "")}</g>`).join("");
  cv.world.append(svg);
  // The canvas has no size until the panel enters the page.
  requestAnimationFrame(() => fit(cv, false));
  if (!steps?.length) return cv.map;

  // A step lights its shapes and the edges between them; the rest of the graph dims.
  let at = 0;
  const count = h("span", { class: "count" }), text = h("p", { "aria-live": "polite" });
  const show = (i) => {
    at = Math.max(0, Math.min(steps.length - 1, i));
    const on = new Set(steps[at].at);
    count.textContent = `${at + 1} / ${steps.length}`;
    text.textContent = steps[at].text;
    prev.disabled = at === 0; next.disabled = at === steps.length - 1;
    for (const [id, el] of boxes) el.classList.toggle("step", on.has(id));
    for (const g of svg.querySelectorAll("g[data-i]")) {
      const e = f.edges[g.dataset.i], hot = on.has(e.from) && on.has(e.to);
      for (const el of g.children) el.classList.toggle("hot", hot);
    }
  };
  const prev = h("button", { "aria-label": "Previous step", onclick: () => show(at - 1) }, "←");
  const next = h("button", { "aria-label": "Next step", onclick: () => show(at + 1) }, "→");
  stepKey = (e) => {
    if (e.target.closest?.("input, select, textarea") || e.metaKey || e.ctrlKey || e.altKey) return;
    const d = { ArrowLeft: -1, ArrowRight: 1 }[e.key];
    if (d) { e.preventDefault(); show(at + d); }
  };
  cv.map.classList.add("stepping");
  show(0);
  return h("div", { class: "full" }, h("div", { class: "stepper" }, prev, count, text, next), cv.map);
}

const chevron = () => {
  const s = document.createElementNS("http://www.w3.org/2000/svg", "svg");
  s.setAttribute("width", "14"); s.setAttribute("height", "14"); s.setAttribute("viewBox", "0 0 16 16");
  s.innerHTML = '<path d="M4 6l4 4 4-4" fill="none" stroke="currentColor" stroke-width="1.6"/>';
  return s;
};

// A long list shows its first items; the rest wait behind one button.
function fold(list, shown, item, wrap) {
  const box = wrap(list.slice(0, shown).map(item));
  if (list.length <= shown) return [box];
  const rest = list.slice(shown).map(item).flat();
  const more = `Show ${list.length - shown} more `;
  const btn = h("button", { class: "expand", "aria-expanded": "false", onclick: () => {
    const open = btn.getAttribute("aria-expanded") === "true";
    btn.setAttribute("aria-expanded", String(!open));
    btn.firstChild.textContent = open ? more : "Show fewer ";
    rest.forEach((el) => (open ? el.remove() : box.append(el)));
  } }, more, chevron());
  return [box, btn];
}

const entries = (note, list) => fold(list, 3, (e) => h("li", {},
  h("a", { href: link(note, e.path, e.lines), target: "_blank", rel: "noopener" },
    h("code", {}, e.name)),
  " ", h("span", { class: "path" }, `${e.path}:${e.lines[0]}`),
  h("span", { class: "note" }, e.note)), (xs) => h("ul", { class: "entry" }, xs));

function panel(note, node, isRoot, idx, go) {
  const sec = (title, ...body) => [h("h3", {}, title), ...body.flat(Infinity)];
  const a = h("article", {},
    h("h2", {}, node.name),
    h("p", { class: "lead" }, node.summary),
    node.path != null && h("div", { class: "links-row" },
      h("a", { href: link(note, node.path || ""), target: "_blank", rel: "noopener" },
        note.repo.web ? "Open on GitHub" : "Open in editor"),
      h("span", { class: "path" }, node.path || "/")),
    node.role.map((p) => h("p", {}, p)));

  // The words come first: every section below uses them.
  if (isRoot && note.words?.length) a.append(...sec("Words", ...fold(note.words, 5,
    (w) => [h("dt", {}, w.term), h("dd", {}, w.def)], (xs) => h("dl", { class: "words" }, xs))));
  if (isRoot && node.problem) a.append(...sec("The problem", h("p", {}, node.problem)));
  if (isRoot && node.principles) a.append(...sec("The principle",
    node.principles.map((p) => h("div", { class: "principle" },
      h("p", { class: "claim" }, p.claim),
      h("table", { class: "mammoth" },
        h("thead", {}, h("tr", {}, h("th", {}, "In the scene"), h("th", {}, "In the code"))),
        h("tbody", {}, p.mammoth.rows.map(([s, c]) => h("tr", {}, h("td", {}, s), h("td", {}, c))))),
      h("p", { class: "breaks" }, `Breaks down at: ${p.mammoth.breaks}`),
      h("p", {}, p.cost)))));
  if (isRoot && node.io) a.append(...sec("In and out",
    h("ul", { class: "plain" },
      node.io.inputs.map((x) => h("li", {}, h("strong", {}, "In: "), x)),
      node.io.outputs.map((x) => h("li", {}, h("strong", {}, "Out: "), x))),
    h("p", {}, node.io.goes)));
  // The life of the data steps through the graph, so the two share one section.
  const steps = isRoot && node.lifecycle;
  if (node.flow) a.append(...sec(steps ? "Life of the data" : "How the data moves", flow(node.flow, steps)));
  const cs = connections(idx, node);
  if (cs.length) a.append(...sec("Connections",
    h("ul", { class: "conn" }, cs.map((c) => h("li", {},
      c.dir === "out" ? "To " : "From ",
      h("a", { href: "#", onclick: (e) => { e.preventDefault(); go(c.node.id); } }, c.node.name),
      h("span", { class: "how" }, `: ${[...c.labels].join("; ")}`))))));
  if (node.entry?.length) a.append(...sec("Where to start reading", ...entries(note, node.entry)));
  if (node.external?.length) a.append(...sec("Services it talks to",
    h("ul", { class: "plain" }, node.external.map((s) => h("li", {},
      h("a", { href: s.url, target: "_blank", rel: "noopener" }, s.name), ": ", s.how)))));
  if (isRoot && node.stack?.length) a.append(...sec("Stack",
    h("ul", { class: "plain" }, node.stack.map((s) => h("li", {},
      h("a", { href: s.url, target: "_blank", rel: "noopener" }, s.name), ": ", s.role)))));
  return a;
}

// The word before the colon says how the data moves; the payload stays in the panel.
const word = (label) => label.split(":")[0].trim();

// Links from or to a node's subtree, each lifted to the node the reader can click at this
// level: the child of the two ends' common ancestor, on the far side.
function connections(idx, node) {
  const out = new Map();
  for (const l of idx.links) {
    const fromIn = idx.within(node, l.from), toIn = idx.within(node, l.to);
    if (fromIn === toIn) continue;
    const far = idx.lineage(fromIn ? l.to : l.from), near = idx.lineage(node.id);
    const other = far.find((n, i) => near[i] !== n);
    const key = (fromIn ? ">" : "<") + other.id;
    const c = out.get(key) || { dir: fromIn ? "out" : "in", node: other, labels: new Set() };
    c.labels.add(l.label);
    out.set(key, c);
  }
  return [...out.values()];
}

let elkReady;
function elk() {
  elkReady ||= lib("ELK", "elk.bundled.js", "https://cdn.jsdelivr.net/npm/elkjs@0.10.2/lib/elk.bundled.js")
    .then((E) => new E(), (e) => { elkReady = null; throw e; });
  return elkReady;
}

// The monospace face makes a label's width a character count.
const LEAF = { w: 232, h: 80 }, HEAD = 60, CH = 6.6;
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
const shown = (idx, open, id) => idx.lineage(id).find((n) => !open.has(n.id) || !n.children?.length);

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
  const box = (n) => open.has(n.id) && n.children?.length
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

function fit(cv, anim) {
  const { map, view: v } = cv, r = cv.bounds();
  if (!r || !map.clientWidth) return;
  const W = map.clientWidth, H = map.clientHeight;
  v.k = Math.max(0.1, Math.min(1, (W - 48) / r.width, (H - 72) / r.height));
  v.x = (W - r.width * v.k) / 2 - r.x * v.k;
  v.y = (H - 36 - r.height * v.k) / 2 - r.y * v.k;
  applyView(cv, anim);
}

function center(id) {
  const { map, pos, view: v } = current;
  const r = pos.get(id);
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
  for (const [id, el] of c.boxes) if (!pos.has(id)) { el.remove(); c.boxes.delete(id); }
  for (const [id, r] of pos) {
    const n = c.idx.byId.get(id), isOpen = !!r.children?.length;
    let el = c.boxes.get(id);
    if (!el) {
      const count = n.children?.length || 0;
      el = h("div", { class: count ? "box can" : "box", "data-id": id, style: `z-index:${c.idx.lineage(id).length}` },
        h("button", { class: "head", title: n.summary, "aria-expanded": count ? "false" : null,
          onclick: () => c.dragged || pick(id, true) },
          h("span", { class: "name" }, n.name, h("span", { class: "more" }, count ? `${count} inside` : n.kind)),
          h("span", { class: "sum" }, n.summary),
          count > 0 && h("span", { class: "tog", "aria-hidden": "true" }, chevron())));
      c.boxes.set(id, el);
      c.world.append(el);
    }
    el.classList.toggle("open", isOpen);
    el.classList.toggle("rel", near.has(id) && id !== c.sel);
    el.toggleAttribute("aria-current", id === c.sel);
    if (n.children?.length) el.firstChild.setAttribute("aria-expanded", String(isOpen));
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
  // A pinch arrives as ctrl+wheel; a plain wheel or two-finger swipe pans.
  map.addEventListener("wheel", (e) => {
    e.preventDefault();
    const v = get().view;
    if (e.ctrlKey || e.metaKey) {
      const b = map.getBoundingClientRect(), mx = e.clientX - b.left, my = e.clientY - b.top;
      const k = Math.min(2.5, Math.max(0.1, v.k * Math.exp(-e.deltaY * 0.01)));
      v.x = mx - ((mx - v.x) * k) / v.k; v.y = my - ((my - v.y) * k) / v.k; v.k = k;
    } else { v.x -= e.deltaX; v.y -= e.deltaY; }
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
  if (toggle && node.children?.length) c.open.has(id) ? c.open.delete(id) : c.open.add(id);
  for (const n of c.idx.lineage(id).slice(0, -1)) c.open.add(n.id);
  c.sel = id;
  stepKey = null;
  if (node.flow) await renderFlow(node.flow);
  writeHash(c.note.slug, id, c.open);
  const crumbs = h("nav", { class: "crumbs", "aria-label": "Path" }, c.idx.lineage(id).map((n, i) => [
    i > 0 && h("span", { "aria-hidden": "true" }, "/"),
    h("button", { "aria-current": n === node ? "location" : null, onclick: () => n !== node && go(n.id) }, n.name),
  ]));
  const art = panel(c.note, node, node === c.note.root, c.idx, go);
  c.crumbs.replaceWith(crumbs); c.art.replaceWith(art);
  Object.assign(c, { crumbs, art });
  await draw();
  // Folds only add or only remove within one pick, so the size tells whether the layout moved.
  const moved = c.open.size !== was;
  if (moved) fit(current, true);
  return moved;
}
// From the panel or the path: reveal the node. With no fold, bring it to the middle instead.
function go(id) {
  pick(id, false).then((moved) => {
    if (!moved) center(id);
    if (current.map.getBoundingClientRect().top < 0) scrollTo(0, 0);
  });
}

function canvas(get, cls, label, ...extra) {
  const world = h("div", { class: "world" });
  const tools = h("div", { class: "tools" },
    h("button", { "aria-label": "Zoom out", onclick: () => zoom(get(), 1 / 1.25) }, "−"),
    h("button", { "aria-label": "Zoom in", onclick: () => zoom(get(), 1.25) }, "+"),
    h("button", { onclick: () => fit(get(), true) }, "Fit"), ...extra,
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

// A flow with a stepper goes full screen with its banner, so the arrows still say which step shows.
function full(cv, btn) {
  const el = cv.map.closest(".full") || cv.map;
  if (document.fullscreenElement) return document.exitFullscreen();
  el.onfullscreenchange = () => (btn.textContent = document.fullscreenElement === el ? "Exit full screen" : "Full screen");
  el.requestFullscreen();
}

const mapView = () => canvas(() => current, "tree", "Map. Drag to pan, pinch or Ctrl+scroll to zoom.",
  h("button", { onclick: () => {
    current.idx.byId.forEach((n) => n.children?.length && current.open.add(n.id));
    draw().then(() => fit(current, true));
  } }, "Expand all"),
  h("button", { onclick: () => {
    current.open = new Set([current.note.root.id]);
    pick(current.note.root.id, false).then(() => fit(current, true));
  } }, "Collapse"));

async function open(slug, nodeId, openIds) {
  const note = await loadNote(slug);
  document.title = note.title;
  const r = note.repo;
  // With a switcher, the select shows the title, so the heading stays for screen readers only.
  const switcher = !standalone && O.list.length > 1;
  const bar = h("header", { class: "bar" },
    h("h1", { class: switcher ? "sr" : null }, note.title),
    h("span", { class: "meta" },
      r.web ? h("a", { href: `${r.web}/tree/${r.sha}`, target: "_blank", rel: "noopener" },
        `${r.name}@${r.sha.slice(0, 7)}`) : `${r.name}@${r.sha.slice(0, 7)}`,
      `, ${note.generated}`),
    switcher && h("select", {
      "aria-label": "Switch note",
      onchange: (e) => open(e.target.value).catch(fail),
    }, O.list.map((n) => h("option", { value: n.slug, selected: n.slug === slug }, n.title))),
    !standalone && h("a", { class: "share", href: `notes/${slug}.html`, download: `${slug}.html` }, "Download as one file"));
  const { map, world } = mapView();
  const crumbs = h("nav"), art = h("article");
  const main = h("main", {}, crumbs, map, art);
  app.replaceChildren(bar, main);
  const idx = index(note.root);
  const unfolded = new Set([note.root.id, ...(openIds || "").split(",").filter((id) => idx.byId.get(id)?.children?.length)]);
  current = { note, main, idx, map, world, crumbs, art, open: unfolded, boxes: new Map(), pos: new Map(), view: { x: 0, y: 0, k: 1 },
    bounds: () => current.pos.get(note.root.id) };
  await pick(idx.byId.has(nodeId) ? nodeId : note.root.id, false);
  fit(current, false);
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
