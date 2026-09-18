---
name: release-notes
description: "Generate user-facing release notes from tickets, PRDs, git logs, or internal changelogs. Use when writing release notes, creating a changelog, announcing a product update, or summarizing what shipped."
argument-hint: "A version, a path to tickets/PRDs/changelogs, or a product URL"
---

# Release Notes Generator

Write user-facing release notes for **$ARGUMENTS**. Read every file the user provides
first. A product URL means web search for the product and its audience.

Lead every entry with the **benefit**, not the change:

- "Implemented Redis caching layer for dashboard API endpoints" → "Dashboards now load up
  to 3× faster, so you spend less time waiting and more time analyzing."
- "Fixed race condition in concurrent checkout flow" → "Fixed an issue where some orders
  could fail during high-traffic periods."

Write in plain language. Keep ticket numbers, internal codenames, class names, and module
names off the notes. One to three sentences per entry.

Done when every user-facing change in the source material appears under a heading below,
and every non-user-facing one is dropped.

```
# [Product Name] — [Version / Date]

## New Features
- **[Feature name]**: [what it does and why it matters]

## Improvements
- **[Area]**: [what got better and how it helps]

## Bug Fixes
- Fixed [issue, in user terms]

## Breaking Changes
- **Action required**: [what users need to do]

## Deprecations
- **[Feature]**: [what replaces it, and by when]
```

Drop a heading with no entries.
