// node render.mjs < flows.json > svgs.json: lays out each flow with ELK and draws it as one static SVG.
// Obsidian strips scripts from a note, so the layout runs here, once, at install.
import { createRequire } from "node:module";
import { readFileSync } from "node:fs";

const ELK = createRequire(import.meta.url)("./vendor/elk.bundled.js");
// A monospace face makes a label's width a character count, so ELK gets exact sizes.
const CH = 7.8, LABEL_CH = 6.6, H = 40, STORE = 44, DIAMOND = 64, BADGE = 22;
const INK = "currentColor", ACCENT = "var(--text-accent,#7c5cff)", PAPER = "var(--background-primary,#fff)";
const esc = (t) => String(t).replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/"/g, "&quot;");
// A vendor (`node: null`) or another repo (`external`) is outside the repo, and draws dashed.
const outside = (s) => s.node === null || !!s.external;

function children(f) {
  const leaf = (n) => ({ id: n.id, width: n.name.length * CH * (n.decision ? 1.6 : 1) + 28 + BADGE,
    height: n.store ? STORE : n.decision ? DIAMOND : H,
    ...(n.end && { layoutOptions: { "elk.layered.layering.layerConstraint": n.end === "in" ? "FIRST" : "LAST" } }) });
  const out = [], frames = new Map();
  for (const n of f.nodes) {
    if (!n.group) { out.push(leaf(n)); continue; }
    if (!frames.has(n.group)) {
      frames.set(n.group, { id: "\0g:" + n.group, children: [], layoutOptions: { "elk.padding": "[top=34,left=14,bottom=14,right=14]" } });
      out.push(frames.get(n.group));
    }
    frames.get(n.group).children.push(leaf(n));
  }
  return out;
}

async function layout(f) {
  const grouped = f.nodes.some((n) => n.group);
  // The options match the retired HTML viewer: top-down, so a label sits across a layer instead of
  // adding a column; with groups, the note's list order is the only placement ELK honors on a frame.
  return new ELK().layout({
    id: "flow", children: children(f),
    // A `back` edge lays out reversed, so a loop back up the map never re-layers the shapes above it.
    edges: f.edges.map((e, i) => ({ id: `e${i}`, sources: [e.back ? e.to : e.from], targets: [e.back ? e.from : e.to],
      labels: [{ text: e.label, width: e.label.length * LABEL_CH + 8, height: 14 }] })),
    layoutOptions: {
      "elk.algorithm": "layered", "elk.direction": "DOWN", "elk.edgeRouting": "ORTHOGONAL",
      "elk.edgeLabels.placement": "CENTER", "elk.spacing.nodeNode": f.nodes.length > 10 ? "40" : "28",
      "elk.layered.spacing.nodeNodeBetweenLayers": "40", "elk.spacing.edgeLabel": "4",
      "elk.layered.spacing.edgeNodeBetweenLayers": "20",
      ...(grouped
        ? { "elk.layered.cycleBreaking.strategy": "GREEDY_MODEL_ORDER", "elk.layered.considerModelOrder.strategy": "NODES_AND_EDGES",
            "elk.layered.crossingMinimization.forceNodeModelOrder": "true" }
        : { "elk.layered.cycleBreaking.strategy": "MODEL_ORDER" }),
      "elk.hierarchyHandling": "INCLUDE_CHILDREN", "elk.json.shapeCoords": "ROOT", "elk.json.edgeCoords": "ROOT",
    },
  });
}

function shapeSvg(s, n, no) {
  const { x, y, width: w, height: h } = n;
  const dash = outside(s) ? ' stroke-dasharray="5 3"' : "";
  const body = s.decision
    ? `<polygon points="${x + w / 2},${y} ${x + w},${y + h / 2} ${x + w / 2},${y + h} ${x},${y + h / 2}" fill="${PAPER}" stroke="${INK}"${dash}/>`
    : `<rect x="${x}" y="${y}" width="${w}" height="${h}" rx="${s.store ? h / 2 : 4}" fill="${PAPER}" stroke="${INK}" stroke-width="${s.store ? 1 : 1.4}"${dash}/>`;
  // The badge is the callout: the key under the map and the steps cite the shape by this number.
  const bx = x + (s.decision ? w / 2 - 52 : 14), by = y + h / 2;
  return `<g>${body}<g class="badge"><circle cx="${bx}" cy="${by}" r="9" style="fill:${ACCENT}"/>` +
    `<text x="${bx}" y="${by + 4}" text-anchor="middle" font-size="11" style="fill:${PAPER}">${no}</text></g>` +
    `<text x="${x + (w + BADGE) / 2}" y="${by + 4}" text-anchor="middle" font-size="13" style="fill:${INK}">${esc(s.name)}</text></g>`;
}

function edgeSvg(e, edge, tip) {
  const pts = (e.sections || []).flatMap((s) => [s.startPoint, ...(s.bendPoints || []), s.endPoint]);
  const dash = edge.dashed ? ' stroke-dasharray="5 3"' : "";
  const start = edge.both || edge.back ? ` marker-start="url(#${tip})"` : "", end = edge.back ? "" : ` marker-end="url(#${tip})"`;
  let out = `<path d="M${pts.map((p) => `${p.x},${p.y}`).join(" L")}" fill="none" stroke="${INK}"${dash}${start}${end}/>`;
  const lb = e.labels?.[0];
  if (lb) out += `<rect x="${lb.x}" y="${lb.y}" width="${lb.width}" height="${lb.height}" style="fill:${PAPER}"/>` +
    `<text x="${lb.x + lb.width / 2}" y="${lb.y + lb.height - 3}" text-anchor="middle" font-size="11" style="fill:${INK}">${esc(lb.text)}</text>`;
  return out;
}

async function draw(f, i) {
  const res = await layout(f);
  const shape = new Map(f.nodes.map((n, j) => [n.id, { s: n, no: j + 1 }]));
  // Marker ids are global in the page, and one note holds several maps.
  const tip = `tip${i}`;
  const frames = res.children.filter((n) => n.id.startsWith("\0g:"));
  const placed = res.children.flatMap((n) => n.children || [n]);
  const W = Math.ceil(res.width), Hh = Math.ceil(res.height);
  return [
    `<svg viewBox="0 0 ${W} ${Hh}" width="100%" xmlns="http://www.w3.org/2000/svg" style="max-width:${W}px;font-family:ui-monospace,Menlo,monospace">`,
    `<defs><marker id="${tip}" viewBox="0 0 8 8" refX="7" refY="4" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M0,0L8,4L0,8z" style="fill:${INK}"/></marker></defs>`,
    ...frames.map((g) => `<rect x="${g.x}" y="${g.y}" width="${g.width}" height="${g.height}" rx="6" style="fill:${INK};fill-opacity:.05" stroke="${INK}" stroke-opacity=".3"/>` +
      `<text x="${g.x + 12}" y="${g.y + 20}" font-size="12" style="fill:${INK}">${esc(g.id.slice(3))}</text>`),
    ...res.edges.map((e, j) => {
      const ed = f.edges[j];
      return edgeSvg(e, { ...ed, dashed: outside(shape.get(ed.from).s) || outside(shape.get(ed.to).s) }, tip);
    }),
    ...placed.map((n) => shapeSvg(shape.get(n.id).s, n, shape.get(n.id).no)),
    "</svg>",
  ].join("\n");
}

const flows = JSON.parse(readFileSync(0, "utf8"));
process.stdout.write(JSON.stringify(await Promise.all(flows.map(draw))));
