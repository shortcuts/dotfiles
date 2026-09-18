# Writing the note into the vault

```bash
vault="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes"
```

Markdown carries the note. The vault theme styles it, so the note needs no CSS. Reach for
inline HTML only for a shape Markdown cannot express - Obsidian strips `<script>`, and a
`<style>` block fights the user's theme and dark mode.

## Frontmatter

The vault already has a frontmatter convention, set by the notes the web clipper writes.
Reuse those keys - a new key of your own is a property Obsidian shows in its own row and
no other note shares.

```yaml
---
title: Fair build scheduling in the index builder
description: One sentence - the TL;DR's first line. Obsidian shows it in hover previews and search results.
source: https://algolia.atlassian.net/wiki/spaces/.../RFC+-+Fair+build+scheduling
author: indexing-scale team
created: 2026-09-11
aliases:
  - c2m
  - orchestrator
tags:
  - explain
  - engineering-distributed-systems
  - metis
---
```

| Key | What goes in it |
|---|---|
| `title` | The note title, same as the `#` heading |
| `description` | The TL;DR's first sentence. This is what the reader sees before opening the note |
| `source` | The **one best read** only - the primary source. The rest stay in **Sources** |
| `tags` | `explain`, then the field, then the repo or product if there is one |
| `created` | `date +%F`. Never type today's date from memory |
| `author`, `published`, `aliases` | Only when they apply: the owning team or spec author, the source's own date, the acronyms and alternate names a reader would search for |

## Tags

**Match the vault's existing tags before you invent one.** The taxonomy is flat
`field-subfield` kebab-case (`engineering-distributed-systems`, `engineering-apis`,
`health-fitness`), not nested `#engineering/distributed`. Read what is already in use, and
reuse the closest:

```bash
grep -rhE '^  - [a-z0-9-]+$' "$vault" --include='*.md' | sort -u
```

Every note the skill writes carries `explain`, so `tag:#explain` lists them all. Add at
most three more: the field, the repo or product, and the subsystem if it earns its own
tag. Wikilink tags (`- "[[GitHub]]"`) appear in clipped notes - that is the clipper's
habit, not a convention to copy.

## Where the note goes

Scope the note by repository, the way `fish/functions/obsd.fish` does:

| Subject | Path under the vault |
|---|---|
| Code, a commit, a PR, or anything else in a git repo | `<repo>/explain/<slug>.md` |
| A general concept, with no repo behind it | `Knowledge/<slug>.md` |

Name the slug after the subject: `data-ingestion-pr7959`, `metis-metricsreporter`,
`oauth-pkce`. The note lives in the vault only - an explanation is not a project artifact,
so keep it out of the user's repository and working directory.

```bash
root=$(git rev-parse --show-toplevel 2>/dev/null)
rel="Knowledge/<slug>.md"
[ -n "$root" ] && rel="$(basename "$root")/explain/<slug>.md"

mkdir -p "$vault/$(dirname "$rel")"
# write the note to "$vault/$rel", then:
for i in 1 2 3 4 5 6; do obsidian open vault=notes path="$rel" && break; sleep 0.5; done
```

Obsidian indexes a new file with a delay, so the open retries.
