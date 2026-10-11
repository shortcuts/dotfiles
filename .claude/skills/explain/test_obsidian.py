#!/usr/bin/env python3
"""python3 test_obsidian.py: writes the test notes into a temporary vault and reads them back."""
import copy
import json
import re
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

import obsidian
import test_check as t

SKETCH = ('<svg viewBox="0 0 360 80" xmlns="http://www.w3.org/2000/svg" style="font-size:12px"><circle cx="40" cy="40" r="30"/>'
          '<text x="20" y="44">1</text></svg>')


def notes():
    code = copy.deepcopy(t.VALID)
    code["root"]["children"].append(copy.deepcopy(t.SERVICE))
    code["root"]["flow"]["nodes"].append({"id": "v", "name": "viewer", "node": "viewer"})
    code["root"]["flow"]["nodes"][0]["doc"] = ".gitignore#L1"
    code["root"]["flow"]["nodes"].append({"id": "x", "name": "hashing", "about": "The ring.",
                                          "external": {"repo": "notes", "url": "#note=consistent-hashing"}})
    code["root"]["flow"]["edges"] += [{"from": "a", "to": "v", "label": "call: stage"},
                                      {"from": "v", "to": "b", "label": "call: stage"}]
    code["root"]["lifecycle"] = [{"text": "Fish stages a file, so Git can record it.", "at": ["a", "v"],
                                  "detail": "The whitelist decides what Git sees."}]
    concept = copy.deepcopy(t.CONCEPT)
    concept["root"]["plates"] = [{"title": "The ring", "svg": SKETCH, "key": ["Ring: holds the hash space."],
                                  "caption": "A key walks to the next of 3 servers."}]
    return code, concept


def svgs(text):
    blocks = re.findall(r"^<svg\b.*?^</svg>$", text, re.M | re.S)
    for b in blocks:
        # Obsidian starts an HTML block only on a line that opens the tag, and a blank line ends it.
        assert b.splitlines()[0].endswith(">"), b[:80]
        assert not re.search(r"\n\s*\n", b), "a blank line inside an svg prints the rest as text"
        ET.fromstring(b)
    return blocks


def links(vault, text):
    for target in re.findall(r"\[\[([^|\]]+)", text):
        assert (vault / f"{target}.md").exists(), f"broken wikilink [[{target}]]"


def main():
  with tempfile.TemporaryDirectory() as d:
      vault = Path(d)
      (vault / ".obsidian").mkdir()
      code, concept = notes()
      main = obsidian.install(code, vault)
      folder = main.parent
      assert folder == vault / "Explain" / "config", main
      text = main.read_text()
      assert text.startswith("---\nexplain-slug: config\n"), text[:80]
      heads = re.findall(r"^## (.+)$", text, re.M)
      assert heads[:2] == ["The map", "How the data moves"], heads
      assert heads[-3:] == ["Check yourself", "Sources", "Words"] or heads[-2:] == ["Check yourself", "Sources"], heads
      blocks = svgs(text)
      shapes = len(code["root"]["flow"]["nodes"])
      assert blocks and blocks[0].count('class="badge"') == shapes, "each map shape carries its key number"
      key = re.search(r"## The map\n.*?</svg>\n\n((?:\d+\. [^\n]+\n)+)", text, re.S)
      assert key and len(key.group(1).splitlines()) == shapes, "one key line per shape"
      assert "[[Explain/config/viewer|viewer]]" in text, "a shape with a node links its note"
      assert text.count("> [!question]-") == 3, "each answer folds"
      assert "(1, 3)" in text, f"a step names its shapes by key number: {text}"
      assert "[Read more](https://github.com/o/r/blob/" in text and ".gitignore#L1)" in text, "a shape's doc links from its key line"
      links(vault, text)
      svc = (folder / "viewer.md").read_text()
      assert "## Data flow" in svc and "## Inside" in svc and "[[Explain/config/fish-functions|functions]]" in svc, svc
      svgs(svc)
      links(vault, svc)
      gitignore = (folder / "gitignore.md").read_text()
      assert "## Sends to" in gitignore and "[[Explain/config/nvim-lua|lua]]" in gitignore, gitignore
      assert "## Receives from" in (folder / "nvim-lua.md").read_text()
      assert json.loads((folder / "note.json").read_text())["slug"] == "config", "the vault keeps the note's data"

      # A word gets a footnote at its first use, and the definition at the foot of the note.
      cmain = obsidian.install(concept, vault)
      ctext = cmain.read_text()
      assert ctext.count("[^w1]") == 2 and "[^w1]: **ring**: The hash space bent into a circle." in ctext, ctext
      assert "*Sketch 1: The ring.* A key walks to the next of 3 servers." in ctext, ctext
      assert len(svgs(ctext)) == 2, "the map and the sketch"
      assert "dasharray" not in svgs(ctext)[0], "a concept has no outside system"
      links(vault, ctext)

      # A shape that names another note links its main page once that note exists.
      obsidian.install(code, vault)
      assert "[[Explain/consistent-hashing/Consistent hashing|hashing]]" in main.read_text()
      # The index lists every note, newest first; a renamed note replaces its old pages.
      index = (vault / "Explain.md").read_text()
      assert index.index("Consistent hashing") < index.index("Dotfiles"), index
      links(vault, index)
      obsidian.install(code | {"title": "Dotfiles renamed"}, vault)
      assert not (folder / "Dotfiles.md").exists() and (folder / "Dotfiles renamed.md").exists()
      (folder / "mine.md").write_text("hand-written")
      obsidian.install(code, vault)
      assert (folder / "mine.md").exists(), "a page the skill did not write stays"


if __name__ == "__main__":
    main()
    print("ok")
