# Writing the note into the vault

```bash
vault="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes"
```

Write Markdown, with inline SVG plates ([`PLATES.md`](PLATES.md)). Add no CSS: Obsidian
strips `<script>`, and a `<style>` block breaks the theme and dark mode.

## Frontmatter

Reuse the keys the web clipper writes. Obsidian shows a new key as its own property row
that no other note shares.

```yaml
---
title: Consistent hashing
description: The note's opening line. Obsidian shows it in hover previews and search.
source: https://dl.acm.org/doi/10.1145/258533.258660
author: Karger et al.
created: 2026-09-11
aliases:
  - hash ring
tags:
  - explain
  - engineering-distributed-systems
---
```

| Key | Value |
|---|---|
| `title` | Same as the `#` heading |
| `description` | The note's opening line |
| `source` | The one best read only. The rest stay in **Sources** |
| `tags` | `explain`, the field, then the repo or product |
| `created` | Output of `date +%F`. Never type the date from memory |
| `author` | Only when it applies: the inventors or spec authors |
| `published` | Only when it applies: the `source:` date, `YYYY` or `YYYY-MM-DD` |
| `aliases` | Only when it applies: acronyms and alternate names a reader searches for |

## Tags

Reuse the closest existing tag before you invent one. Tags are flat `field-subfield`
kebab-case (`engineering-distributed-systems`, `health-fitness`), not nested
(`#engineering/distributed`). List the tags in use:

```bash
grep -rhE '^  - [a-z0-9-]+$' "$vault" --include='*.md' | sort -u
```

Every note carries `explain`, so `tag:#explain` lists them all. Add at most three more:
the field, the repo or product, the subsystem. Do not copy the clipper's wikilink tags
(`- "[[GitHub]]"`).

## Where the note goes

| Subject | Path under the vault |
|---|---|
| Code, a commit, a PR, or anything in a git repo | `<repo>/explain/<slug>.md` |
| A general concept | `Knowledge/<slug>.md` |

Name the slug after the subject: `data-ingestion-pr7959`, `oauth-pkce`. Write the note to
the vault only, never to the user's repository.

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null)
rel="Knowledge/<slug>.md"
[ -n "$root" ] && rel="$(basename "$root")/explain/<slug>.md"

mkdir -p "$vault/$(dirname "$rel")"
# write the note to "$vault/$rel", then:
# Obsidian indexes a new file with a delay, so the open retries.
for i in 1 2 3 4 5 6; do obsidian open vault=notes path="$rel" && break; sleep 0.5; done
```
