"""Write a checked note into the Obsidian vault: one folder per note, one page per part.

check.py --install calls install(). Obsidian strips scripts, so render.mjs lays out each
flow here and the pages carry static SVG.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
from urllib.parse import quote
from pathlib import Path

HERE = Path(__file__).resolve().parent
VAULT = Path(os.environ.get("EXPLAIN_VAULT", Path.home() / "Library/Mobile Documents"
                            "/iCloud~md~obsidian/Documents/notes/Knowledge"))
# Pinned by hash: install runs this code on every machine that writes a note.
ELK = ("https://cdn.jsdelivr.net/npm/elkjs@0.10.2/lib/elk.bundled.js",
       "88f7753e5b41af205d56ee4edaf6eea4fceabe0115b76c9495e5a2cee95c31d1")
# Marks a page the skill wrote, so a reinstall replaces it and leaves hand-written pages.
MARK = "explain-slug"
SVG_NS = "http://www.w3.org/2000/svg"
ET.register_namespace("", SVG_NS)


def vendor():
    path = HERE / "vendor" / "elk.bundled.js"
    data = path.read_bytes() if path.exists() else b""
    if hashlib.sha256(data).hexdigest() != ELK[1]:
        # curl, because a python.org Python ships without CA certificates.
        data = subprocess.run(["curl", "-fsSL", "--max-time", "120", ELK[0]],
                              capture_output=True, check=True).stdout
        if hashlib.sha256(data).hexdigest() != ELK[1]:
            sys.exit(f"elk.bundled.js: the download from {ELK[0]} does not match its pinned hash")
        path.parent.mkdir(exist_ok=True)
        path.write_bytes(data)


def render(flows):
    vendor()
    out = subprocess.run(["node", HERE / "render.mjs"], input=json.dumps(flows),
                         capture_output=True, text=True, check=True)
    return json.loads(out.stdout)


def filename(text):
    return re.sub(r'[\\/:*?"<>|#^\[\]]', "-", text).strip() or "note"


def link(note, path, lines=None):
    r = note["repo"]
    if not r["web"]:
        return f"vscode://file{r['path']}/{path}" + (f":{lines[0]}" if lines else "")
    if lines:
        return f"{r['web']}/blob/{r['sha']}/{path}#L{lines[0]}-L{lines[1]}"
    return f"{r['web']}/tree/{r['sha']}/{path}"


class Page:
    """One Markdown page. Each term of `words` gets a footnote at its first use on the page."""

    def __init__(self, words):
        self.words, self.used, self.lines = words, [], []

    def gloss(self, text):
        for w in self.words:
            if w in self.used:
                continue
            m = re.search(rf"(?<!\w){re.escape(w['term'])}(?!\w)", text or "", re.I)
            if m:
                self.used.append(w)
                text = f"{text[:m.end()]}[^w{len(self.used)}]{text[m.end():]}"
        return text

    def add(self, *lines):
        self.lines.extend(lines)

    def text(self):
        notes = [f"[^w{i}]: **{w['term']}**: {w['def']}" for i, w in enumerate(self.used, 1)]
        return "\n".join(self.lines + ([""] + notes if notes else [])).rstrip() + "\n"


def svg_block(svg):
    """Obsidian starts an HTML block only on a line that opens the tag, and a blank line ends it."""
    root = ET.fromstring(svg)
    root.set("width", "100%")
    body = ET.tostring(root, encoding="unicode")
    head, rest = body.split(">", 1)
    rest = re.sub(r"\n\s*\n", "\n", rest).strip()
    return ["", head + ">", rest.removesuffix("</svg>").strip() or " ", "</svg>", ""]


def doc_link(note, path):
    # GitHub renders a file's anchors only under blob/.
    r = note["repo"]
    return f"{r['web']}/blob/{r['sha']}/{path}" if r["web"] else link(note, path)


def other_note(shape, vault):
    """An `external` shape links its repo's docs, or the main page of the note it names."""
    url = (shape.get("external") or {}).get("url", "")
    if url.startswith("https://"):
        return f"[{shape['name']}]({url})"
    other = vault / "Explain" / url.removeprefix("#note=") / "note.json"
    if url.startswith("#note=") and other.exists():
        title = json.loads(other.read_text())["title"]
        rel = other.parent.relative_to(vault_root(vault)).as_posix()
        return f"[[{rel}/{filename(title)}|{shape['name']}]]"
    return None


def flow_section(page, note, flow, svg, steps, wiki, heading, vault):
    """The map, its key, and the steps that cite the key's numbers."""
    page.add(*svg_block(svg))
    for i, s in enumerate(flow["nodes"], 1):
        name = wiki.get(s.get("node")) or other_note(s, vault) or f"**{s['name']}**"
        about = s.get("about") or note_summary(note, s.get("node"))
        kind = " (store)" if s.get("store") else ""
        more = ""
        if s.get("doc") and note["repo"]:
            path, _, anchor = s["doc"].partition("#")
            more = f" [Read more]({doc_link(note, path)}{'#' + anchor if anchor else ''})"
        page.add(f"{i}. {name}{kind}" + (f": {page.gloss(about)}" if about else "") + more)
    if steps:
        number = {s["id"]: i for i, s in enumerate(flow["nodes"], 1)}
        page.add("", heading, "")
        for i, st in enumerate(steps, 1):
            at = ", ".join(str(number[a]) for a in st["at"] if a in number)
            page.add(f"{i}. **{page.gloss(st['text'])}** ({at})" + (f" {page.gloss(st['detail'])}" if st.get("detail") else ""))


def note_summary(note, node_id):
    if node_id is None:
        return ""
    def find(n):
        if n.get("id") == node_id:
            return n
        return next((m for c in n.get("children") or [] if (m := find(c))), None)
    return (find(note["root"]) or {}).get("summary", "")


def nodes(root):
    yield root
    for c in root.get("children") or []:
        yield from nodes(c)


def install(note, vault=None):
    vault = Path(vault or VAULT)
    if not vault.is_dir():
        sys.exit(f"no vault folder at {vault}; set EXPLAIN_VAULT to a folder of your Obsidian vault")
    slug, root, words = note["slug"], note["root"], note["words"]
    folder = vault / "Explain" / slug
    folder.mkdir(parents=True, exist_ok=True)
    rel = folder.relative_to(vault_root(vault)).as_posix()

    # One page per part, named after its id, so two parts with one name never share a page.
    files, taken = {}, set()
    for n in nodes(root):
        if n is root:
            continue
        name = filename(re.sub(r"[^A-Za-z0-9]+", "-", n["id"]).strip("-").lower())
        while name in taken:
            name += "-x"
        taken.add(name)
        files[n["id"]] = name
    wiki = {n["id"]: f"[[{rel}/{files[n['id']]}|{n['name']}]]" for n in nodes(root) if n is not root}
    main_name = filename(note["title"])
    wiki[root["id"]] = f"[[{rel}/{main_name}|{note['title']}]]"

    with_flow = [n for n in nodes(root) if n.get("flow")]
    drawn = dict(zip([n["id"] for n in with_flow], render([n["flow"] for n in with_flow])))

    pages = {main_name: main_page(note, drawn.get(root["id"]), wiki, vault)}
    sends, gets = {}, {}
    for n in nodes(root):
        for ln in n.get("links") or []:
            sends.setdefault(n["id"], []).append((ln["to"], ln["label"]))
            gets.setdefault(ln["to"], []).append((n["id"], ln["label"]))
    parent = {c["id"]: n["id"] for n in nodes(root) for c in n.get("children") or []}
    for n in nodes(root):
        if n is not root:
            pages[files[n["id"]]] = part_page(note, n, drawn.get(n["id"]), wiki, parent[n["id"]],
                                              sends.get(n["id"], []), gets.get(n["id"], []), vault)

    for old in folder.glob("*.md"):
        if old.stem not in pages and old.read_text().startswith(f"---\n{MARK}: {slug}\n"):
            old.unlink()
    for name, text in pages.items():
        (folder / f"{name}.md").write_text(text)
    (folder / "note.json").write_text(json.dumps(note, ensure_ascii=False, indent=1))
    index(vault)
    return folder / f"{main_name}.md"


def vault_root(folder):
    """The vault is the nearest folder with .obsidian; wikilinks and obsidian:// URLs start there."""
    for p in [folder, *folder.parents]:
        if (p / ".obsidian").is_dir():
            return p
    return folder


def front(note, title, **extra):
    r = note["repo"]
    meta = {MARK: note["slug"], "title": title, "scope": note["scope"]["kind"],
            **({"repo": r["name"], "sha": r["sha"][:7]} if r else {}),
            "created": note["generated"], **extra}
    lines = ["---", *(f"{k}: {json.dumps(v, ensure_ascii=False)}" if k != MARK else f"{k}: {v}" for k, v in meta.items() if v),
             "tags:", "  - explain", "---"]
    return lines


def main_page(note, svg, wiki, vault):
    root, sources = note["root"], note["root"].get("sources") or []
    page = Page(note["words"])
    page.add(*front(note, note["title"], description=root["summary"], source=sources[0]["url"] if sources else None))
    r = note["repo"]
    page.add(f"# {note['title']}", "",
             f"*{r['name']} at [{r['sha'][:7]}]({r['web']}/tree/{r['sha']})*" if r and r["web"]
             else f"*{r['name']} at {r['sha'][:7]}*" if r else f"*{note['scope']['kind']}*", "",
             page.gloss(root.get("overview") or root["summary"]), "", "## The map")
    if svg:
        flow_section(page, note, root["flow"], svg, root.get("lifecycle"), wiki, "## How the data moves", vault)
    if root.get("stack"):
        page.add("", "## Stack", "", *(f"- [{s['name']}]({s['url']}): {s['role']}" for s in root["stack"]))
    if root.get("io"):
        io = root["io"]
        page.add("", "## In and out", "", *(f"- In: {x}" for x in io["inputs"]), *(f"- Out: {x}" for x in io["outputs"]),
                 f"- Goes to: {io['goes']}")
    page.add("", "## Why it works", "", page.gloss(root["problem"]))
    for p in root["principles"]:
        page.add("", f"### {page.gloss(p['claim'])}", "", page.gloss(p["why"]), "",
                 *(f"- **{c}**: {page.gloss(d)}" for c, d in p["example"]), "",
                 *([f"*Except:* {page.gloss(p['except'])}", ""] if p.get("except") else []),
                 f"*Cost:* {page.gloss(p['cost'])}"
                 + (f" Source: [{sources[p['source'] - 1]['title']}]({sources[p['source'] - 1]['url']})." if p.get("source") else ""))
    for i, pl in enumerate(root.get("plates") or [], 1):
        page.add(*svg_block(pl["svg"]), f"*Sketch {i}: {pl['title']}.* {page.gloss(pl['caption'])}", "",
                 *(f"{j}. {page.gloss(k)}" for j, k in enumerate(pl["key"], 1)))
    if root.get("children"):
        page.add("", "## Parts", "", *(f"- {wiki[c['id']]}: {page.gloss(c['summary'])}" for c in root["children"]))
    if root.get("check"):
        page.add("", "## Check yourself", "")
    for c in root.get("check") or []:
        # The callout folds, so the reader commits to a guess before the answer shows.
        page.add(f"> [!question]- {c['q']}", f"> {page.gloss(c['a'])}", "")
    if root.get("further"):
        page.add("## Go further", "")
        for f in root["further"]:
            s = sources[f["source"] - 1]
            page.add(f"- {f['q']} Read [{s['title']}]({s['url']}), {f['at']}.")
        page.add("")
    if sources:
        page.add("## Sources", "", *(f"- [{s['title']}]({s['url']}) {s['why']}" for s in sources))
    return page.text()


def part_page(note, n, svg, wiki, up, sends, gets, vault):
    page = Page(note["words"])
    page.add(*front(note, n["name"], description=n["summary"]))
    where = f" at [{n['path'] or '/'}]({link(note, n['path'])})" if n.get("path") is not None and note["repo"] else ""
    page.add(f"# {n['name']}", "", f"*{n['kind']}{where}* · part of {wiki[up]}", "",
             page.gloss(n["summary"]), "", *(page.gloss(r) for r in n.get("role") or []))
    if svg:
        page.add("", "## Data flow")
        flow_section(page, note, n["flow"], svg, n.get("lifecycle"), wiki, "### Steps", vault)
    for title, items in (("Sends to", sends), ("Receives from", gets)):
        if items:
            page.add("", f"## {title}", "", *(f"- {wiki[i]}: {label}" for i, label in items))
    if n.get("children"):
        page.add("", "## Inside", "", *(f"- {wiki[c['id']]}: {page.gloss(c['summary'])}" for c in n["children"]))
    if n.get("entry"):
        page.add("", "## Where to start reading", "",
                 *(f"- [{e['name']}]({link(note, e['path'], e['lines'])}): {page.gloss(e['note'])}" for e in n["entry"]))
    if n.get("external"):
        page.add("", "## Outside services", "", *(f"- [{s['name']}]({s['url']}): {page.gloss(s['how'])}" for s in n["external"]))
    return page.text()


def index(vault):
    """Explain.md links every note's main page, newest first."""
    entries = [json.loads(f.read_text()) for f in (vault / "Explain").glob("*/note.json")]
    rel = (vault / "Explain").relative_to(vault_root(vault)).as_posix()
    lines = ["---", "tags:", "  - explain", "---", "# Explain", ""]
    for n in sorted(entries, key=lambda n: n["generated"], reverse=True):
        where = n["repo"]["name"] if n["repo"] else n["scope"]["kind"]
        lines.append(f"- [[{rel}/{n['slug']}/{filename(n['title'])}|{n['title']}]] · {where} · {n['generated']}")
    (vault / "Explain.md").write_text("\n".join(lines) + "\n")


def open_url(path):
    root = vault_root(path.parent)
    return f"obsidian://open?vault={quote(root.name)}&file={quote(path.relative_to(root).with_suffix('').as_posix())}"
