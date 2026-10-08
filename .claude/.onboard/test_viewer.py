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


def test_word_marks_carry_their_definition():
    page = dom()
    # One mark per term per block: the summary above the map, the panel lead, and the role.
    assert page.count('class="wref"') == 3, page.count('class="wref"')
    assert 'title="render job: One report to build."' in page, "the mark's tooltip defines the term"
    assert "Render Job<sup" in page, "the mark sits right after the term, in any case"
    assert "The problem" not in page and 'class="notes"' not in page, "the panel carries no fluff"
    assert 'class="sec"' not in page and 'class="no"' not in page, "the page has no numbered sections"


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
  log.flowTags = $$(".stage .flowtag").map((e) => e.closest(".box").dataset.id);
  $(".panel .see").click();
  await wait(1500);
  log.simple = texts(".over .box.shape");
  $('.over .tools button[aria-pressed]').click();
  await wait(1500);
  log.outside = texts(".over .box.shape.outside");
  log.outEdges = new Set($$(".over path.edge.outside").map((p) => p.closest("g[data-i]"))).size;
  log.jumps = texts(".over button.box.shape");
  log.steps = $$(".over ol.steps li").length;
  log.headFirst = $(".over .step-head")?.textContent;
  $('.over .step-head button[aria-label="Next step"]')?.click();
  log.head = $(".over .step-head .count")?.textContent;
  await wait(500);
  log.lit = texts(".over .box.shape.step");
  $$(".over button.box.shape").find((b) => b.textContent === "push")?.click();
  await wait(800);
  log.stays = !!$(".over");
  log.shapePanel = $(".panel h2")?.textContent;
  $(".panel button.see")?.click();
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
    assert "queue: records" not in log["simple"], f"the simple view hides the stores: {log['simple']}"
    assert log["outside"] == ["Algolia", "OpenAI", "metis", "queue: records"], f"node null and external shapes are dashed: {log['outside']}"
    assert log["outEdges"] == 5, f"each edge that touches an outside shape is dashed: {log['outEdges']}"
    assert log["jumps"] == ["enrich", "push"], f"a shape with a tree node is a button: {log['jumps']}"
    assert log["flowTags"] == ["worker"], f"a box with a data flow carries a tag, the root and the packages do not: {log['flowTags']}"
    assert log["steps"] == 2, "the service lifecycle shows as the step list"
    assert log["headFirst"] == "←– / 2→Press → to step through the flow.", f"the steps sit in a header above the flow: {log['headFirst']}"
    assert log["head"] == "1 / 2", f"the header's → shows the first step: {log['head']}"
    assert log["lit"] == ["enrich", "queue: records"], f"a step lights its shapes: {log['lit']}"
    assert log["stays"] and log["shapePanel"] == "push", f"a click on a shape with a node fills the panel and stays in the flow: {log}"
    assert not log["over"], "the panel's button goes back to the map"
    assert log["panel"] == "push", f"a node jump selects that node in the panel: {log['panel']}"
    assert log["current"] == "worker", f"a package inside a service marks the service box: {log['current']}"


FLOWMAP = {**SERVICE, "slug": "f", "root": {**SERVICE["root"], "flow": {
    "nodes": [{"id": "src", "name": "Source", "node": None, "end": "in", "about": "Where records start."},
              {"id": "w", "name": "worker", "node": "worker", "group": "GCP: ingest"},
              {"id": "out", "name": "Index", "node": None, "end": "out", "about": "Where records land."}],
    "edges": [{"from": "src", "to": "w", "label": "grpc: record"}, {"from": "w", "to": "out", "label": "http: batch"}]},
    "lifecycle": [{"text": "A record arrives.", "at": ["src", "w"], "detail": "The source sends one record."}],
    "overview": "Records flow from a source. The worker indexes them."}}

FLOWDRIVER = """<script>
(async () => {
  const wait = (ms) => new Promise((ok) => setTimeout(ok, ms));
  const $ = (s) => document.querySelector(s), $$ = (s) => [...document.querySelectorAll(s)];
  await wait(1500);
  const log = { stage: !!$(".stage > .flow-fig"), tree: $$(".stage .box:not(.shape):not(.grp)").length, steps: $$(".stage ol.steps li").length, head: $(".stage .step-head .count")?.textContent,
    life: $$("h2").some((h) => h.textContent.includes("Life of the data")) };
  log.step = $(".panel h2")?.textContent + "|" + $(".panel p:not(.meta)")?.textContent;
  log.overview = $(".intro .lead")?.textContent;
  log.flowShapes = $$(".stage .box.shape.flow").map((b) => b.textContent);
  $$(".stage button.box.shape").find((b) => b.textContent === "Source").click();
  await wait(300);
  log.shape = $(".panel h2")?.textContent + "|" + $(".panel p:not(.meta)")?.textContent;
  log.lit = $$(".stage .box.shape.step").map((b) => b.textContent).sort();
  log.outEdge = $$(".stage text.elabel.out").map((t) => t.lastChild.textContent);
  log.headAfterClick = $(".stage .step-head .count")?.textContent;
  log.groups = $$(".stage .box.grp").map((g) => g.textContent);
  const g = $(".stage .box.grp"), w = $$(".stage .box.shape").find((b) => b.textContent === "worker");
  log.inside = !!g && g.offsetLeft <= w.offsetLeft && g.offsetTop <= w.offsetTop
    && w.offsetLeft + w.offsetWidth <= g.offsetLeft + g.offsetWidth && w.offsetTop + w.offsetHeight <= g.offsetTop + g.offsetHeight;
  $$(".stage button.box.shape").find((b) => b.textContent === "worker").click();
  await wait(500);
  log.panel = $(".panel h2")?.textContent;
  log.mark = $(".stage .box.shape[aria-current]")?.textContent;
  document.body.append(Object.assign(document.createElement("pre"), { id: "t", textContent: JSON.stringify(log) }));
})();
</script>"""


def test_flow_is_the_map():
    page = dom(FLOWMAP, FLOWDRIVER)
    m = re.search(r'<pre id="t">(.*?)</pre>', page, re.S)
    assert m, "the driver ran to its end"
    log = json.loads(html.unescape(m.group(1)))
    assert log["stage"] and log["tree"] == 0, f"the root flow replaces the box map: {log}"
    assert log["steps"] == 1 and not log["life"], f"the steps sit under the map, with no second diagram: {log}"
    assert log["head"] == "1 / 1", f"the header shows the current step number: {log}"
    assert log["overview"] == "Records flow from a source. The worker indexes them.", f"the overview sits above the map: {log}"
    assert log["step"] == "A record arrives.|The source sends one record.", f"the panel opens on the step's detail: {log}"
    assert log["shape"] == "Source|Where records start.", f"a shape with no node shows its about: {log}"
    assert log["flowShapes"] == ["worker"], f"a shape whose node has a data flow carries a tag: {log}"
    assert log["panel"] == "worker" and log["mark"] == "worker", f"a shape click moves the panel and marks the shape: {log}"
    assert log["lit"] == ["worker"], f"a shape click lights its neighbours, not the step's shapes: {log}"
    assert log["outEdge"] == ["grpc: record"], f"a shape click colors its outgoing edges: {log}"
    assert log["headAfterClick"] == "– / 1", f"a shape click leaves the step: {log}"
    assert log["groups"] == ["GCP: ingest"] and log["inside"], f"a group draws a frame around its shapes: {log}"


SIDES = {**FLOWMAP, "slug": "sd", "root": {**FLOWMAP["root"], "flow": {
    "nodes": [{"id": "a", "name": "First", "node": None, "end": "in"},
              {"id": "b", "name": "Second", "node": None, "end": "in"},
              {"id": "w", "name": "worker", "node": "worker", "end": "out", "group": "GCP"}],
    "edges": [{"from": "a", "to": "w", "label": "grpc: a"}, {"from": "b", "to": "w", "label": "grpc: b"}]},
    "lifecycle": []}}

SIDESDRIVER = """<script>
(async () => {
  const wait = (ms) => new Promise((ok) => setTimeout(ok, ms));
  await wait(1500);
  const at = (t) => [...document.querySelectorAll(".stage .box.shape")].find((b) => b.textContent === t).offsetLeft;
  document.body.append(Object.assign(document.createElement("pre"), { id: "t", textContent: JSON.stringify({ first: at("First"), second: at("Second") }) }));
})();
</script>"""


def test_flow_lists_left_to_right():
    page = dom(SIDES, SIDESDRIVER)
    m = re.search(r'<pre id="t">(.*?)</pre>', page, re.S)
    assert m, "the driver ran to its end"
    log = json.loads(html.unescape(m.group(1)))
    assert log["first"] < log["second"], f"a flow with groups keeps the list order, so the first shape sits at the left: {log}"


STORED = {**FLOWMAP, "slug": "st", "root": {**FLOWMAP["root"], "flow": {
    "nodes": [{"id": "src", "name": "Source", "node": None, "end": "in"},
              {"id": "q", "name": "Pub/Sub: runs", "store": True, "node": None},
              {"id": "w", "name": "worker", "node": "worker"},
              {"id": "db", "name": "PostgreSQL: jobs", "store": True, "node": None, "end": "out"}],
    "edges": [{"from": "src", "to": "q", "label": "queue: run"}, {"from": "q", "to": "w", "label": "queue: run"},
              {"from": "w", "to": "db", "label": "writes DB: jobs"}]},
    "lifecycle": [{"text": "A run is queued.", "at": ["q"]}]}}

STOREDRIVER = """<script>
(async () => {
  const wait = (ms) => new Promise((ok) => setTimeout(ok, ms));
  const $ = (s) => document.querySelector(s), $$ = (s) => [...document.querySelectorAll(s)];
  const shapes = () => $$(".stage .box.shape").map((b) => b.textContent).sort();
  const labels = () => $$(".stage text.elabel").map((t) => t.lastChild.textContent);
  await wait(1500);
  const log = { shapes: shapes(), labels: labels(), lit: $$(".stage .box.shape.step").map((b) => b.textContent).sort() };
  $(".stage .tools button[aria-pressed]").click();
  await wait(1500);
  log.allShapes = shapes(); log.allLabels = labels();
  log.pressed = $(".stage .tools button[aria-pressed]").getAttribute("aria-pressed");
  log.hash = new URLSearchParams(location.hash.slice(1)).get("stores");
  log.head = $(".stage .step-head .count")?.textContent;
  document.body.append(Object.assign(document.createElement("pre"), { id: "t", textContent: JSON.stringify(log) }));
})();
</script>"""


def test_stores_toggle():
    page = dom(STORED, STOREDRIVER)
    m = re.search(r'<pre id="t">(.*?)</pre>', page, re.S)
    assert m, "the driver ran to its end"
    log = json.loads(html.unescape(m.group(1)))
    assert log["shapes"] == ["Source", "worker"], f"the simple view hides the stores: {log}"
    assert log["labels"] == ["queue: run"], f"a hidden store joins its writer to its reader, and a sink drops: {log}"
    assert log["lit"] == ["Source", "worker"], f"a step on a hidden store lights its neighbours: {log}"
    assert log["allShapes"] == ["PostgreSQL: jobs", "Pub/Sub: runs", "Source", "worker"], f"the toggle shows the stores: {log}"
    assert len(log["allLabels"]) == 3, f"the toggle shows the edges to the stores: {log}"
    assert log["pressed"] == "true" and log["hash"] == "1", f"the toggle shows in the button and the hash: {log}"
    assert log["head"] == "1 / 1", f"the toggle keeps the step: {log}"


DECIDED = {**FLOWMAP, "slug": "d", "root": {**FLOWMAP["root"], "flow": {
    "nodes": [{"id": "src", "name": "Source", "node": None, "end": "in", "about": "Where records start."},
              {"id": "hit", "name": "Cache hit?", "decision": True, "about": "Same hash: stored attributes."},
              {"id": "idx", "name": "Index", "node": None, "end": "out", "about": "Where records land."}],
    "edges": [{"from": "src", "to": "hit", "label": "grpc: record"},
              {"from": "hit", "to": "idx", "label": "call: hit"},
              {"from": "src", "to": "idx", "label": "http: browse", "both": True},
              {"from": "idx", "to": "hit", "label": "http: webhook", "back": True}]},
    "lifecycle": [{"text": "A record arrives.", "at": ["src", "hit"], "detail": "The source sends one record."}]}}

DECIDEDRIVER = """<script>
(async () => {
  const wait = (ms) => new Promise((ok) => setTimeout(ok, ms));
  const $ = (s) => document.querySelector(s), $$ = (s) => [...document.querySelectorAll(s)];
  await wait(1500);
  const log = { diamond: $$(".stage .box.decision polygon").length, name: $(".stage .box.decision")?.textContent,
    both: $$(".stage path.edge[marker-start][marker-end]").length, one: $$(".stage path.edge:not([marker-start])").length,
    back: $$(".stage path.edge[marker-start]:not([marker-end])").length };
  document.body.append(Object.assign(document.createElement("pre"), { id: "t", textContent: JSON.stringify(log) }));
})();
</script>"""


def test_decision_and_two_way_edge():
    page = dom(DECIDED, DECIDEDRIVER)
    m = re.search(r'<pre id="t">(.*?)</pre>', page, re.S)
    assert m, "the driver ran to its end"
    log = json.loads(html.unescape(m.group(1)))
    assert log["diamond"] == 1 and log["name"] == "Cache hit?", f"a decision shape draws a rhombus: {log}"
    assert log["both"] == 1 and log["one"] >= 2, f"a `both` edge has an arrow at each end, the others at one: {log}"
    assert log["back"] == 1, f"a `back` edge lays out reversed and keeps its arrow on its target: {log}"



# A part's flow fills the panel like the map: a shape with an about shows it, a step shows its detail.
OVERPANEL = {**SERVICE, "slug": "op", "root": {**SERVICE["root"], "children": [{**SERVICE["root"]["children"][0],
    "flow": {**SERVICE["root"]["children"][0]["flow"], "nodes": [
        {**n, "about": "The model the worker asks.", "doc": "docs/openai.md#models"} if n["id"] == "oa" else n
        for n in SERVICE["root"]["children"][0]["flow"]["nodes"]]},
    "lifecycle": [{"text": "The worker takes a record.", "at": ["q", "enrich"], "detail": "Record o1 leaves the queue."},
                  {"text": "The worker pushes it.", "at": ["push", "alg"]}]}]}}

OVERDRIVER = """<script>
(async () => {
  const wait = (ms) => new Promise((ok) => setTimeout(ok, ms));
  const $ = (s) => document.querySelector(s), $$ = (s) => [...document.querySelectorAll(s)];
  const log = {};
  await wait(1500);
  $('.box[data-id="worker"] .head').click();
  await wait(800);
  $(".panel .see").click();
  await wait(1500);
  $('.over .step-head button[aria-label="Next step"]').click();
  await wait(300);
  log.step = $(".panel h2")?.textContent + "|" + $(".panel p:not(.meta)")?.textContent;
  $$(".over button.box.shape").find((b) => b.textContent === "OpenAI")?.click();
  await wait(300);
  log.shape = $(".panel h2")?.textContent + "|" + $(".panel p:not(.meta)")?.textContent;
  log.doc = $(".panel a.src")?.getAttribute("href") || "";
  log.over = !!$(".over");
  document.body.append(Object.assign(document.createElement("pre"), { id: "t", textContent: JSON.stringify(log) }));
})();
</script>"""


def test_part_flow_fills_the_panel():
    page = dom(OVERPANEL, OVERDRIVER)
    m = re.search(r'<pre id="t">(.*?)</pre>', page, re.S)
    assert m, "the driver ran to its end"
    log = json.loads(html.unescape(m.group(1)))
    assert log["step"] == "The worker takes a record.|Record o1 leaves the queue.", f"a part's step shows its detail in the panel: {log}"
    assert log["shape"] == "OpenAI|The model the worker asks.", f"a part's shape with an about shows it in the panel: {log}"
    assert "docs/openai.md#models" in log["doc"], f"a shape's doc links from the panel: {log}"
    assert log["over"], f"a shape click keeps the part's flow open: {log}"

if __name__ == "__main__":
    if not Path(CHROME).exists():
        raise SystemExit("skip: no Google Chrome")
    test_word_marks_carry_their_definition()
    test_service_graph()
    test_flow_is_the_map()
    test_flow_lists_left_to_right()
    test_stores_toggle()
    test_decision_and_two_way_edge()
    test_part_flow_fills_the_panel()
    print("ok")
