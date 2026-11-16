# Wiki and docs kit

Several repos ship the same documentation kit. The reference implementation is `~/Documents/locationjoystick` (`docs/wiki/`). A consumer is a repo that copies it and keeps some parts local. Today: `~/Documents/pgpemu`. Use this file to build, audit and port the kit across consumers.

## Contents

- What the kit is
- Information architecture
- Page types
- Writing rules
- Page mechanics
- Repo-level docs
- Shared and local parts
- Syncing a consumer
- Audit checklist

## What the kit is

A static HTML site in `docs/wiki/`, hosted on GitHub Pages. Files:

| File | Role |
|---|---|
| `style.css` | One stylesheet. Colors live in `:root`. |
| `wiki-init.js` | Injects the sidebar (`NAV_ITEMS`, `EXT_ITEMS`), search and heading anchors. Pages carry no nav markup. |
| `CONTRIBUTING.md` | The wiki's own rules. It records the `Design upstream` line. |
| `sitemap.xml`, `robots.txt`, `CNAME` | Search and domain. |
| `<page>.html` | Pages. Every page uses the same shell. |
| `screenshots/`, `fonts/` | Assets. Fonts load from the site, not a CDN. |

The README stays minimal and links to the wiki. Developer detail goes to `AGENTS.md`, `CONTRIBUTING.md` and `docs/`. Never duplicate wiki prose in the README.

## Information architecture

Six sidebar groups, fixed order. A new group needs a user decision. Guides is the decided exception to the rule "one group per user goal".

| Group | Holds | Page type |
|---|---|---|
| Start | First-time setup: Getting started, plus hardware or install pages when the product has them | Tutorial or how-to |
| Guides | `tasks.html` (the hub) and one page per goal a user arrives with | How-to |
| Features | One page per feature the user navigates daily | Reference or explanation |
| Configure | Settings, plus backup or transfer pages when they exist | Reference |
| Help | Troubleshooting, and FAQ or integration references | How-to, reference |
| About | Compare apps (when it exists), Changelog, Privacy, Acknowledgements | Reference |

Rules:

- The hub (`tasks.html`) links every Guides page. A Guides page answers one goal in a title that starts with a verb ("Move a device to a new phone").
- A feature page is a noun ("Game monitor").
- Merge a feature into an existing page when it is a sub-topic or has under about 300 words. Add a page only for a distinct user goal.
- A move or merge leaves a redirect stub (see "Page mechanics"). Stubs are never deleted.
- Sentence case for every title, heading and nav label. Match the app's own strings ("Device profiles", not "Device Profiles").

## Page types

Each page has one Diátaxis type. Never mix. If content fits two types, write two pages and link them. Judge with `/documentation`.

- **Tutorial.** Goal, numbered steps, a visible result after each step.
- **How-to.** Goal, prerequisites, numbered steps, expected result.
- **Reference.** One heading per entry. See the rules below.
- **Explanation.** Context, concept, trade-offs.

Typical mixing to split: a connect page that also explains slot limits (move the explanation to the feature page), a settings page that holds a full feature walkthrough (move it to its own Features page), a FAQ that holds how-to steps (move them to Guides).

### Reference pages

- Never a `<table>`. Tables squash on phones.
- Open the section with one sentence saying what the entries are.
- One heading per entry, one level below the section heading. Add `class="item"` where the consumer's stylesheet supports it so the outline skips it.
- Give every entry heading a unique `id`, prefixed with the section `id`.
- Write the heading as the entry name only.
- End with `<p><strong>Default:</strong> ...</p>` when there is a default. Reuse the bold label for other facts (`Meaning:`, `Confirm with:`, `License:`).
- Keep the same facts in the same order for every entry in a section.
- A developer-only section (API reference) is the one exception to the no-code rule. Head it "(for developers)", open it with a plain paragraph for users, and keep it to endpoints, formats and error codes.

## Writing rules

- Audience: users, not developers. No code symbols, function or opcode names, file paths, framework or library names (except an acknowledgements page), or internal platform concepts. `<code>` only for a UI label or a literal the user types or reads.
- Active voice, present tense, one idea per sentence, under 20 words.
- Audience test: a non-technical friend understands every sentence.
- No marketing tone, no history, no repeated explanations. Link an explanation once.
- Prose gate: run `/unslop` (or `/no-ai-slop`, whichever the consumer's `CONTRIBUTING.md` names), then `/documentation`, on every page whose prose changed. Judge the result against the audience test.
- Changelog: some consumers generate `changelog.html` from JSON. Read the consumer's `CONTRIBUTING.md` before touching it. A hand-written changelog still follows the same prose rules. Version headings read `1.0.1 (February 18, 2026)`, not an em dash.

## Page mechanics

- Shell: DOCTYPE, `lang="en"`, charset and viewport, title, description, canonical, Open Graph, Twitter, icon, `style.css`, DocSearch CSS, then `<div class="layout"><main>...</main></div>` and `<script src="wiki-init.js"></script>`.
- Title: `<Page name> | <site>`. Unique per page. Do not use an em dash.
- Description: one plain sentence under 160 characters. Mirror it in `og:` and `twitter:` tags.
- Canonical and `og:url`: the custom domain URL of the page.
- One `<h1>` with an `id`. Every `<h2>` and `<h3>` has a unique `id`. Keep ids stable. A rename that changes an id breaks inbound links.
- Links: relative, descriptive text, never "click here". Every image has `alt`.
- Screenshots: `<section class="has-shot">` with `<aside class="shot"><img class="phone-shot" ...></aside>` right after the heading. One per section. Landing page only carries the `.hero` and one `.btn`.
- Sitemap: add each real page. Never list a stub.
- Stub: keep the old file with a matching `<title>`, `<meta http-equiv="refresh">` (add the anchor when merged into a section), a canonical link to the new page, `<meta name="robots" content="noindex">`, and one body line: "This page moved. See <a>Page name</a>."
- A section that moves to a new page inside the same site needs no stub when the old page stays. Update every inbound link and anchor instead.

## Repo-level docs

The reference repo splits non-wiki docs this way. Consumers follow the shape that fits their size.

| File | Audience | Holds |
|---|---|---|
| `README.md` | Users and visitors | Header, badges, short features list linking to wiki pages, install, quick start, community, contributing, license. Minimal. |
| `CONTRIBUTING.md` | Contributors | Build, PR rules, commit format, required checks, reference-doc table. |
| `AGENTS.md` | Agents | Scope, rules, doc-maintenance table (file to update when X changes), module and service tables. Link to symbols; do not copy what code states. |
| `docs/*.md` | Agents and contributors | Internal specifics: architecture, code style, testing, domain models, constants, permissions, constraints. |
| `docs/features/*.md` | Agents | One spec per feature (reference repo only). |

State the policy once in `AGENTS.md`: docs give context, code holds the data. Doc changes ship in the same commit as the code change.

## Shared and local parts

Shared with the upstream (port changes): `style.css` layout rules, `wiki-init.js` logic, the structure and rules in `CONTRIBUTING.md`, the page shell.

Local to each consumer: `:root` colors, `NAV_ITEMS` items, the pages themselves, the site name and domain, the changelog mechanism, extra pages (an install page with a browser flasher, a compare page).

Record the split in one `Design upstream` line in the wiki `CONTRIBUTING.md` (format in `design-system.md`). Add the docs-kit pieces to its "Local:" list.

## Syncing a consumer

1. Read the `Design upstream` line and list upstream commits since the sync hash for the shared files, including `CONTRIBUTING.md` and `wiki-init.js`.
2. Sort each change: not yet ported, local by design, local drift.
3. Port structure before prose. Order: nav groups, page moves and merges, page type splits, then prose.
4. After a port, move the sync hash to the upstream `HEAD`.
5. When a consumer finds a better rule, port it upstream first, then to the other consumers. Never let two consumers diverge on a shared rule.

When a user asks directly to restructure or port a wiki, apply the change to the docs files only (HTML, `wiki-init.js`, `sitemap.xml`, `CONTRIBUTING.md`, `AGENTS.md`, README). Otherwise log findings to radin as usual. Product code stays untouched either way.

## Audit checklist

- Nav: six groups in order. Every real page is in `NAV_ITEMS` and `sitemap.xml`. No orphan page, no stub in the nav.
- Hub: `tasks.html` links every Guides page.
- Types: each page has one type. Guides are verb titles. Features are nouns.
- Reference pages: no `<table>`, one heading per entry, same facts in the same order.
- Anchors: every `href="page.html#id"` resolves. Check with a script, not by eye.
- Case: sentence-case titles, headings, labels. Same words as the app.
- Prose: no em dash, no filler, no code symbols, no library names, under 20 words per sentence.
- Head: unique title and description, canonical on the right domain, one `h1`.
- Stubs: present for every moved page, absent from the sitemap.
- README: minimal, no duplicated wiki prose, every link live.
- `AGENTS.md`: the doc-maintenance table and the wiki file table list every page.
- Sync: the `Design upstream` hash is current.
