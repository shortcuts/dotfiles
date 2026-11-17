#!/usr/bin/env python3
"""Check atlas topics and serve the canvas viewer.

Usage, inside a repo with docs/atlas/<topic>.json:
  python3 ~/.claude/skills/atlas/atlas.py check docs/atlas/<topic>.json
  python3 ~/.claude/skills/atlas/atlas.py serve [--port 4317]

A canvas records what code cannot say: context, options, decisions and consequences. A card may
name the doc heading that states its rule and the areas of the repo it concerns. `check` fails when
one of those no longer exists, and `serve` lists the commits that touched a card's areas since the
topic's `since` ref, so a stale decision shows. The human's marks go to docs/atlas/<topic>.marks.json.
"""

import hashlib
import json
import mimetypes
import re
import subprocess
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlparse

HERE = Path(__file__).resolve().parent
KINDS = {"context", "concept", "state", "option", "decision", "consequence", "image"}
VERDICTS = {"open", "chosen", "rejected"}
STATUSES = {"proposed", "accepted", "superseded"}


def slug(heading):
    """GitHub's anchor for a Markdown heading."""
    text = re.sub(r"[^\w\- ]", "", heading.strip().lower())
    return text.replace(" ", "-")


def headings(path):
    return {slug(m.group(1)) for m in re.finditer(r"^#+\s+(.+)$", path.read_text(), re.M)}


def check(model, root):
    """Return one line per broken reference in the topic."""
    errors, seen = [], set()
    status = model.get("status", "accepted")
    if status not in STATUSES:
        errors.append(f"status {status} is not proposed, accepted or superseded")
    bands = {band["id"] for band in model["bands"]}
    for card in model["cards"]:
        cid = card["id"]
        if cid in seen:
            errors.append(f"{cid}: duplicate id")
        seen.add(cid)
        if card["band"] not in bands:
            errors.append(f"{cid}: unknown band {card['band']}")
        kind = card.get("kind", "concept")
        if kind not in KINDS:
            errors.append(f"{cid}: unknown kind {kind}")
        if "verdict" in card and card["verdict"] not in VERDICTS:
            errors.append(f"{cid}: verdict {card['verdict']} is not open, chosen or rejected")
        if "image" in card and not (root / card["image"]).is_file():
            errors.append(f"{cid}: image {card['image']} does not exist")
        for area in card.get("touches", []):
            if not (root / area).exists():
                errors.append(f"{cid}: touches {area}, which does not exist")
        doc = card.get("doc")
        if doc:
            file, _, anchor = doc.partition("#")
            if not (root / file).is_file():
                errors.append(f"{cid}: {file} does not exist")
            elif anchor and anchor not in headings(root / file):
                errors.append(f"{cid}: heading #{anchor} not in {file}")
    for edge in model["edges"]:
        for end in (edge["from"], edge["to"]):
            if end not in seen:
                errors.append(f"edge {edge['from']}->{edge['to']}: unknown card {end}")
    return errors


def merge_marks(existing, incoming):
    """Take the viewer's marks, keeping the status and reply the agent wrote on each."""
    agent = {m["id"]: m for m in existing}
    merged = []
    for mark in incoming:
        old = agent.get(mark["id"], {})
        merged.append({**mark, "status": old.get("status", "open"), **({"reply": old["reply"]} if "reply" in old else {})})
    return merged


def git(root, *args):
    return subprocess.run(["git", "-C", str(root), *args], capture_output=True, text=True, check=True).stdout


def latest_tag(root):
    try:
        return git(root, "describe", "--tags", "--abbrev=0").strip()
    except subprocess.CalledProcessError:
        return None


def resolve(root, name):
    """The topic with each card's recent commits, plus its broken references and marks."""
    topic = root / "docs/atlas" / f"{name}.json"
    model = json.loads(topic.read_text())
    errors = check(model, root)
    ref = model.get("since") or latest_tag(root)
    try:
        git(root, "rev-parse", f"{ref}^{{commit}}")
    except subprocess.CalledProcessError:
        errors.append(f"since: {ref} is not a commit")
        ref = None
    for card in model["cards"]:
        areas = [a for a in card.get("touches", []) if (root / a).exists()]
        if ref and areas:
            out = git(root, "log", "--format=%h %s", f"{ref}..HEAD", "--", *areas)
            card["changes"] = [line for line in out.splitlines() if line]
    marks_file = topic.with_suffix(".marks.json")
    marks = json.loads(marks_file.read_text())["marks"] if marks_file.is_file() else []
    head = git(root, "rev-parse", "--short", "HEAD").strip()
    return {"name": name, "model": model, "errors": errors, "marks": marks, "since": ref, "head": head, "version": version(root, name)}


def version(root, name):
    """Changes when the topic, its marks or HEAD change, so the viewer knows to reload."""
    base = root / "docs/atlas" / name
    parts = [git(root, "rev-parse", "HEAD").strip()]
    for path in (base.with_suffix(".json"), base.with_suffix(".marks.json")):
        parts.append(path.read_text() if path.is_file() else "")
    return hashlib.sha1("\0".join(parts).encode()).hexdigest()[:12]


def topics(root):
    out = []
    for path in sorted((root / "docs/atlas").glob("*.json")):
        if path.name.endswith(".marks.json"):
            continue
        model = json.loads(path.read_text())
        marks_file = path.with_suffix(".marks.json")
        marks = json.loads(marks_file.read_text())["marks"] if marks_file.is_file() else []
        out.append({"name": path.stem, "topic": model["topic"], "status": model.get("status", "accepted"),
                    "open": sum(1 for m in marks if m.get("status", "open") == "open")})
    return out


class Handler(BaseHTTPRequestHandler):
    root = None

    def send(self, code, body, kind="application/json"):
        data = body if isinstance(body, bytes) else json.dumps(body).encode()
        self.send_response(code)
        self.send_header("Content-Type", kind)
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def topic_name(self, part):
        name = unquote(part)
        if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", name) or not (self.root / "docs/atlas" / f"{name}.json").is_file():
            raise FileNotFoundError(name)
        return name

    def do_GET(self):
        url = urlparse(self.path)
        parts = url.path.strip("/").split("/", 2)
        try:
            if url.path == "/":
                return self.send(200, (HERE / "viewer.html").read_bytes(), "text/html; charset=utf-8")
            if parts[:2] == ["api", "topics"]:
                return self.send(200, topics(self.root))
            if parts[:2] == ["api", "topic"]:
                return self.send(200, resolve(self.root, self.topic_name(parts[2])))
            if parts[:2] == ["api", "version"]:
                return self.send(200, {"version": version(self.root, self.topic_name(parts[2]))})
            if parts[0] == "repo":
                # Only files inside the repo, so a crafted path cannot read the rest of the disk.
                path = (self.root / unquote(url.path[len("/repo/"):])).resolve()
                if not path.is_relative_to(self.root) or not path.is_file():
                    raise FileNotFoundError(url.path)
                kind = mimetypes.guess_type(path.name)[0] or "text/plain; charset=utf-8"
                return self.send(200, path.read_bytes(), kind)
        except (FileNotFoundError, IndexError):
            pass
        self.send(404, {"error": f"not found: {url.path}"})

    def do_PUT(self):
        parts = urlparse(self.path).path.strip("/").split("/", 2)
        if parts[:2] != ["api", "marks"]:
            return self.send(404, {"error": "not found"})
        try:
            name = self.topic_name(parts[2])
        except (FileNotFoundError, IndexError):
            return self.send(404, {"error": "unknown topic"})
        incoming = json.loads(self.rfile.read(int(self.headers["Content-Length"])))["marks"]
        path = self.root / "docs/atlas" / f"{name}.marks.json"
        existing = json.loads(path.read_text())["marks"] if path.is_file() else []
        path.write_text(json.dumps({"marks": merge_marks(existing, incoming)}, indent=2, ensure_ascii=False) + "\n")
        self.send(200, {"version": version(self.root, name)})

    def log_message(self, *args):
        pass


def main(argv):
    root = Path(git(Path.cwd(), "rev-parse", "--show-toplevel").strip())
    if len(argv) >= 3 and argv[1] == "check":
        path = Path(argv[2]).resolve()
        errors = check(json.loads(path.read_text()), root)
        print("\n".join(errors) if errors else f"{path.relative_to(root)}: every link resolves", file=sys.stderr if errors else sys.stdout)
        return 1 if errors else 0
    if len(argv) >= 2 and argv[1] == "serve":
        port = int(argv[argv.index("--port") + 1]) if "--port" in argv else 4317
        Handler.root = root
        server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
        print(f"atlas: http://127.0.0.1:{port}/ serving {root}", flush=True)
        server.serve_forever()
        return 0
    print(__doc__, file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv))
