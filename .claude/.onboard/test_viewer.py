#!/usr/bin/env python3
"""python3 test_viewer.py: draws a note in headless Chrome and checks the rendered page."""
import html
import json
import re
import shutil
import subprocess
import tempfile
from pathlib import Path

HERE = Path(__file__).parent
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

NOTE = {
    "schema": 2, "slug": "t", "title": "T", "generated": "2026-10-02",
    "repo": {"name": "t", "path": "/t", "sha": "0" * 40, "web": None},
    "scope": {"kind": "repo", "query": ""},
    "words": [{"term": "render job", "def": "One report to build."}],
    "root": {
        "id": "", "name": "t", "kind": "repo", "path": "",
        "summary": "Builds one Render Job.", "role": ["Each render job runs alone."],
        "problem": "A render job is slow, and a render job blocks.",
        "children": [],
    },
}


def dom(note=NOTE, driver=""):
    with tempfile.TemporaryDirectory() as d:
        for f in ("app.js", "app.css"):
            shutil.copy(HERE / f, d)
        if (HERE / "vendor").exists():
            shutil.copytree(HERE / "vendor", Path(d) / "vendor")
        (Path(d) / "index.html").write_text((HERE / "index.html").read_text().replace("</body>", driver + "</body>"))
        (Path(d) / "notes").mkdir()
        (Path(d) / "notes/manifest.js").write_text(f"ONBOARD.manifest({json.dumps([{'slug': note['slug'], 'title': 'T'}])});")
        (Path(d) / "notes" / f"{note['slug']}.js").write_text(f"ONBOARD.register({json.dumps(note)});")
        return subprocess.run([CHROME, "--headless", "--disable-gpu", "--virtual-time-budget=10000",
                               "--window-size=1280,900", "--dump-dom", f"file://{d}/index.html"],
                              capture_output=True, text=True, timeout=60).stdout


def test_word_marks_jump_to_the_words():
    page = dom()
    assert 'id="word-render-job"' in page, "the words section names each term"
    # One mark per term per block: the panel lead, the role, and the problem.
    assert page.count('class="wref"') == 3, page.count('class="wref"')
    assert "Render Job<sup>" in page, "the mark sits right after the term, in any case"
    assert "<h2>" not in page.split('class="notes"')[1].split("</footer>")[0], "the words are footnotes, not a section"
    assert page.rindex('id="word-render-job"') > page.rindex('class="sec"'), "the words close the page"


def pkg(id, name):
    return {"id": id, "name": name, "kind": "package", "path": id, "summary": name, "role": []}


SERVICE = {**NOTE, "slug": "s", "words": [], "root": {**NOTE["root"], "problem": None, "children": [{
    "id": "worker", "name": "worker", "kind": "service", "path": "worker", "summary": "Enriches records.", "role": [],
    "children": [pkg("worker/enrich", "enrich"), pkg("worker/push", "push")],
    "flow": {
        "nodes": [
            {"id": "q", "name": "queue: records", "store": True, "node": None, "end": "in"},
            {"id": "enrich", "name": "enrich", "node": "worker/enrich"},
            {"id": "oa", "name": "OpenAI", "node": None},
            {"id": "push", "name": "push", "node": "worker/push"},
            {"id": "alg", "name": "Algolia", "node": None, "end": "out"},
            {"id": "metis", "name": "metis", "external": {"repo": "metis", "url": "#note=metis"}},
        ],
        "edges": [
            {"from": "q", "to": "enrich", "label": "queue: record"},
            {"from": "enrich", "to": "oa", "label": "http: prompt"},
            {"from": "oa", "to": "enrich", "label": "http: tags"},
            {"from": "enrich", "to": "push", "label": "call: record"},
            {"from": "push", "to": "alg", "label": "http: batch"},
            {"from": "push", "to": "metis", "label": "grpc: done"},
        ],
    },
    "lifecycle": [{"text": "The worker takes a record.", "at": ["q", "enrich"]},
                  {"text": "The worker pushes it.", "at": ["push", "alg"]}],
}]}}

# Clicks through the page and logs what each click shows; the test reads the log back.
DRIVER = """<script>
(async () => {
  const wait = (ms) => new Promise((ok) => setTimeout(ok, ms));
  const $ = (s) => document.querySelector(s), $$ = (s) => [...document.querySelectorAll(s)];
  const texts = (s) => $$(s).map((e) => e.textContent).sort();
  const log = {};
  await wait(1500);
  log.boxes = $$(".stage .box").length;
  $('.box[data-id="worker"] .head').click();
  await wait(800);
  const w = $('.box[data-id="worker"]');
  log.worker = { svc: w.classList.contains("svc"), open: w.classList.contains("open"), can: w.classList.contains("can") };
  log.hashOpen = (new URLSearchParams(location.hash.slice(1)).get("open") || "").split(",");
  $(".panel .see").click();
  await wait(1500);
  log.outside = texts(".over .box.shape.outside");
  log.outEdges = new Set($$(".over path.edge.outside").map((p) => p.closest("g[data-i]"))).size;
  log.jumps = texts(".over button.box.shape");
  log.steps = $$(".over ol.steps li").length;
  $(".over ol.steps button")?.click();
  await wait(500);
  log.lit = texts(".over .box.shape.step");
  $$(".over button.box.shape").find((b) => b.textContent === "push")?.click();
  await wait(800);
  log.over = !!$(".over");
  log.panel = $(".panel h2")?.textContent;
  log.current = $(".stage .box[aria-current]")?.dataset.id;
  document.body.append(Object.assign(document.createElement("pre"), { id: "t", textContent: JSON.stringify(log) }));
})();
</script>"""


def test_service_graph():
    page = dom(SERVICE, DRIVER)
    m = re.search(r'<pre id="t">(.*?)</pre>', page, re.S)
    assert m, "the driver ran to its end"
    log = json.loads(html.unescape(m.group(1)))
    assert log["boxes"], "the map drew boxes: run python3 bundle.py once to fetch vendor/"
    assert log["worker"] == {"svc": True, "open": False, "can": False}, f"a service box has the service frame and never unfolds: {log['worker']}"
    assert "worker" not in log["hashOpen"], "the hash never lists a service as unfolded"
    assert log["outside"] == ["Algolia", "OpenAI", "metis", "queue: records"], f"node null and external shapes are dashed: {log['outside']}"
    assert log["outEdges"] == 5, f"each edge that touches an outside shape is dashed: {log['outEdges']}"
    assert log["jumps"] == ["enrich", "push"], f"a shape with a tree node is a button: {log['jumps']}"
    assert log["steps"] == 2, "the service lifecycle shows as the step list"
    assert log["lit"] == ["enrich", "queue: records"], f"a step lights its shapes: {log['lit']}"
    assert not log["over"], "a node jump goes back to the map"
    assert log["panel"] == "push", f"a node jump selects that node in the panel: {log['panel']}"
    assert log["current"] == "worker", f"a package inside a service marks the service box: {log['current']}"


if __name__ == "__main__":
    if not Path(CHROME).exists():
        raise SystemExit("skip: no Google Chrome")
    test_word_marks_jump_to_the_words()
    test_service_graph()
    print("ok")
