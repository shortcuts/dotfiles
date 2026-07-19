---
name: obsidian-formatter
description: Reformat messy Obsidian web-clip documents into clean, standardized markdown. Use this skill when you need to clean up web clips, remove website navigation cruft, strip HTML tags, embed images with context, generate concise titles, add meaningful tags, or transform cluttered documents into readable notes. Handles Reddit posts, blog articles, and other web content. Trigger phrases include "format Obsidian document", "clean up web clip", "remove HTML from markdown", "fix messy note", "standardize web clippings", "embed images", "generate better title".
compatibility: markdown, obsidian, web scraping, content cleanup
---

# Obsidian Formatter Skill

Transform messy web-clipped documents into clean, readable Obsidian notes. This skill handles the complete workflow from raw web scraps to polished markdown.

## Why This Skill Exists

Web clippers dump everything into markdown: navigation menus, HTML tags, cookie banners, comment sections, verbose titles. The result? Unreadable notes buried in website cruft.

This skill surgically removes noise while preserving valuable content (like FAQ sections), generates meaningful titles and tags, embeds images with context, and validates the output meets markdown quality standards.

## When to Use This Skill

- User says "format this Obsidian document" or "clean up this web clip"
- Document has HTML tags (`<div>`, `<iframe>`, `<span>`) mixed with markdown
- Title is verbose (10+ words) or contains website navigation text
- Images are raw URLs instead of embedded markdown
- Tags are generic ("clippings") instead of meaningful
- Navigation cruft present (Reddit headers, "Skip to content", cookie notices)
- User wants to "remove HTML", "fix formatting", or "make this readable"

## Complete 8-Step Workflow

### Step 1: Extract Current State

**Why**: Understand the document structure before making changes. Identify content boundaries (where real content starts/ends) and detect preservation zones (FAQs, valuable comments).

**How**:
```
1. Read the entire file
2. Note line numbers where:
   - Navigation cruft ends (usually lines 1-20)
   - Real content begins (heading + substantial text)
   - FAQ/valuable sections appear
   - Footer cruft starts
3. Check frontmatter tags and title
4. List all image URLs
```

**Example Findings**:
- Lines 1-28: Reddit navigation (remove)
- Line 29: First real heading "Starting To Stretch"
- Lines 150-200: FAQ section (preserve completely)
- Current title: "r/flexibility Guide: Starting to Stretch - Beginner Flexibility Program" (20 words, needs shortening)
- Tags: Only "clippings" (needs meaningful tags)
- 15 imgur URLs (need embedding with context)

### Step 2: Generate Concise Title

**Why**: Long titles clutter the sidebar and obscure the actual content. Good titles are scannable, keyword-rich, and 1-4 words.

**Logic**:
1. Extract directory name (e.g., "Health/" → "health")
2. Identify 1-3 content keywords from first real heading or summary
3. Combine: `{keyword1} {keyword2} {context}`
4. Remove website names, navigation text, date strings
5. Capitalize properly (title case)

**Examples**:

| Before | After | Why |
|--------|-------|-----|
| r/flexibility Guide: Starting to Stretch - Beginner Flexibility Program | Beginner Flexibility Guide | Removed site name, redundant words; kept core keywords |
| Here's a three-month calisthenics training program for beginners to build foundational strength | Calisthenics Foundation Program | Removed filler words ("Here's", "to build"); kept essence |
| How I Fixed My Posture and You Can Too - Complete Guide 2024 | Posture Correction Guide | Removed clickbait, date, first-person; kept actionable keywords |

**Don't**:
- Keep website names ("r/flexibility", "Medium:", "[Blog]")
- Use dates in titles ("2024 Guide to...")
- Preserve filler words ("Here's", "Complete", "Ultimate")
- Exceed 5 words unless absolutely necessary

### Step 3: Generate Meaningful Tags

**Why**: Generic tags like "clippings" provide zero organizational value. Good tags enable discovery and categorization.

**Format**: Exactly 2 tags
1. `source/{website}` — Where it came from (reddit, medium, hackernews, blog)
2. `{directory}-{keyword}` — Topic classification derived from directory + content

**Examples**:

| File Path | Content Topic | Tags |
|-----------|---------------|------|
| Health/flexibility-doc.md | Stretching routines | `reddit`, `health-flexibility` |
| Programming/react-hooks.md | React tutorial | `medium`, `programming-react` |
| Finance/index-funds.md | Investment strategy | `blog`, `finance-investing` |

**Source Tag Extraction** (in order of priority):
1. Check frontmatter `source:` field
2. Check URL in frontmatter (reddit.com → reddit)
3. Look for website names in first 20 lines
4. If unclear, use "web"

**Topic Tag Construction**:
1. Take directory name (lowercase)
2. Add hyphen
3. Add 1-2 content keywords (from title or headings)
4. Example: "Health/" + "flexibility" = "health-flexibility"

### Step 4: Update Frontmatter Metadata

**Why**: Consistent metadata enables sorting, filtering, and source tracking.

**Required Fields**:
```yaml
---
title: "{Concise Title from Step 2}"
source: {website}
published: {original date if found, otherwise omit}
created: {YYYY-MM-DD of today}
tags:
  - {source tag}
  - {topic tag}
---
```

**Rules**:
- Remove generic "clippings" tag completely
- Keep `published:` only if original publication date is clearly stated
- Always add `created:` with today's date (format: YYYY-MM-DD)
- Title must NOT be wrapped in quotes if it contains no special chars
- Use two-space indentation for tag list

**Example Transformation**:

Before:
```yaml
---
title: "r/flexibility Guide: Starting to Stretch - Beginner Flexibility Program"
tags:
  - clippings
---
```

After:
```yaml
---
title: Beginner Flexibility Guide
source: reddit
published: 2018-07-26
created: 2026-03-24
tags:
  - reddit
  - health-flexibility
---
```

### Step 5: Strip HTML Tags (CRITICAL)

**Why**: HTML tags break markdown parsers, look ugly, and violate Obsidian's plain-text philosophy. This is NON-NEGOTIABLE.

**What to Remove**:
- All `<iframe>` tags (embedded content)
- All `<div>`, `<span>`, `<section>` tags (layout containers)
- All `<a>` tags but preserve link text: `<a href="...">text</a>` → `text`
- All `<img>` tags (you'll embed images properly in Step 6)
- All `<button>`, `<nav>`, `<header>`, `<footer>` tags
- Self-closing tags: `<br />`, `<hr />`, `<meta .../>`
- Inline styling: `<strong>`, `<em>`, `<code>` (use markdown equivalents)
- Comments: `<!-- ... -->`

**Regex Patterns** (for reference):
```
<iframe[^>]*>.*?</iframe>     Remove iframes with content
<div[^>]*>.*?</div>           Remove div blocks
<[^>]+>                        Remove any remaining tags
```

**Examples**:

| Before | After |
|--------|-------|
| `<iframe src="ads.com"></iframe>` | _(deleted entirely)_ |
| `Click <a href="reddit.com">here</a> to view` | Click here to view |
| `<div class="nav">Menu items</div>` | _(deleted if navigation)_ |
| `<strong>Important</strong>` | `**Important**` |
| `Line 1<br />Line 2` | Line 1<br>Line 2 _(or use double space)_ |

**Safety Check**:
After stripping, search the document for `<` and `>` characters. Any remaining angle brackets should ONLY be:
- Markdown comparison operators in code blocks
- Mathematical notation (properly escaped)
- NOT HTML tags

### Step 6: Remove Navigation Cruft

**Why**: Web clippers capture website chrome (headers, footers, navigation menus, cookie notices) that adds zero value to notes.

**Common Patterns to Remove**:

**Reddit-Specific**:
- `[Accéder au contenu principal]` / `[Skip to main content]`
- `Ouvrir l'onglet de navigation` / `Open navigation menu`
- `[Créer une publication]` / `[Create Post]`
- `Règles de Reddit` / `Reddit Rules`
- `[Reddit Inc. © 2024]`
- Vote count badges, award icons
- "Posted by u/username • 2 years ago"
- Comment count links
- Subreddit navigation breadcrumbs

**Generic Website Cruft**:
- Cookie consent banners
- "Subscribe to newsletter" prompts
- Social media share buttons
- "Back to top" links
- Footer copyright notices
- Privacy policy links
- Navigation menus (Home, About, Contact)
- Ad markers ("Advertisement", "Sponsored Content")

**How to Identify Cruft** (100% Certainty Rule):
1. Appears in first 20 lines before real content
2. Contains website UI language ("Skip to...", "Subscribe", "Cookie policy")
3. Repetitive across multiple web clips (same pattern)
4. Zero informational value (navigation, branding, legal)
5. NOT part of the article/post body

**Example** (Reddit flexibility doc):

Remove (lines 1-28):
```
[Accéder au contenu principal]
r/flexibility Guide
Ouvrir l'onglet de navigation
[Créer une publication]
Posted by u/author • 5 years ago
```

Keep (line 29+):
```
# Starting To Stretch

Starting To Stretch is our own full-body flexibility program...
```

**CRITICAL**: When in doubt, keep it. Only remove when you're 100% certain it's website chrome.

### Step 7: Embed Images with Context

**Why**: Raw URLs `https://i.imgur.com/abc123.png` provide no context and break visual flow. Proper embedding adds meaning and improves readability.

**Format**: `![descriptive-keyword](url)`

**Keyword Selection Logic**:
1. Look at surrounding text (±3 lines) for context
2. Check heading above the image
3. If image shows a specific exercise/concept, use that name
4. Fallback: Use generic but meaningful terms (diagram, example, screenshot)
5. Use kebab-case (lowercase, hyphens)

**Examples**:

| Context | URL | Embedded Format |
|---------|-----|-----------------|
| Text mentions "shoulder backbend stretch" | imgur.com/VlZ0FVr.png | `![shoulder-backbend](https://i.imgur.com/VlZ0FVr.png)` |
| Under heading "Form Checklist" | imgur.com/abc123.jpg | `![form-checklist](https://imgur.com/abc123.jpg)` |
| Generic reference in intro | example.com/pic.gif | `![example-diagram](https://example.com/pic.gif)` |
| No clear context, shows chart | site.com/chart.png | `![progress-chart](https://site.com/chart.png)` |

**Rules**:
- Never leave raw URLs hanging: `https://...` → `![keyword](...)`
- One keyword per image (2-3 words max)
- Descriptive over generic: "shoulder-flexibility" beats "image1"
- Keep original URL intact (don't shorten or modify)
- If multiple images show same concept, add numbers: `![squat-form-1](...)`, `![squat-form-2](...)`

**Before**:
```
Check out this stretch:

https://i.imgur.com/VlZ0FVr.png

It targets your shoulders.
```

**After**:
```
Check out this stretch:

![shoulder-stretch](https://i.imgur.com/VlZ0FVr.png)

It targets your shoulders.
```

### Step 8: Validate with Markdownlint

**Why**: Catch formatting issues (broken links, inconsistent lists, trailing whitespace) before considering the job done.

**Exact Command**:
```bash
markdownlint "{filepath}" --fix --disable MD013 MD041 MD060 MD045
```

**Disabled Rules Explained**:
- `MD013`: Line length (web content often has long URLs)
- `MD041`: First line heading (frontmatter comes first)
- `MD060`: HTML tags (we strip them in Step 5, but disable to avoid false positives)
- `MD045`: Images without alt text (we add keywords, not full alt text)

**Success Criteria**:
- Command exits with 0 (no errors)
- If warnings appear, evaluate if they're real issues
- Common acceptable warnings: Long table rows, reference-style links

**Example**:
```bash
$ markdownlint "Health/flexibility-guide.md" --fix --disable MD013 MD041 MD060 MD045
# (no output = success)

$ echo $?
0
```

If errors appear:
1. Read the error message carefully
2. Fix the specific issue (broken link, malformed list, etc.)
3. Re-run validation
4. Repeat until clean

## Safety Principles (NON-NEGOTIABLE)

### 1. Preserve FAQs and Valuable Comments

**Why**: FAQ sections contain condensed wisdom. Comments sometimes answer questions the main post didn't address.

**How to Identify Valuable Content**:
- ✅ **Keep**: FAQ sections, Q&A, "Edit: Addressing common questions", clarifications, updates from author
- ❌ **Remove**: Off-topic comments, jokes, meta-discussion about Reddit itself, "Thanks for the gold!", navigation links

**Example** (from flexibility doc):

Keep:
```markdown
# Frequently Asked Questions

Why didn't you include [insert stretch]?!

We designed Starting to Stretch to be minimalist...
```

Remove:
```markdown
[–] randomuser123 2 points · 3 years ago
This is awesome!

[–] author 1 point · 3 years ago
Thanks!
```

**Rule**: If removing a section would delete actual information (not just reactions), keep it.

### 2. The 100% Certainty Rule

**Never delete content unless you're 100% certain it's cruft.**

Uncertain? Keep it. Better to have extra content than lose valuable information.

**Certainty Checklist**:
- [ ] Appears in first/last 20 lines (likely navigation)
- [ ] Contains UI language (Skip to..., Subscribe, Cookie)
- [ ] Zero informational value (branding, legal boilerplate)
- [ ] Repetitive pattern seen in other web clips

If ANY checkbox is unchecked, keep the content.

### 3. Context Isolation (No Data Carryover)

**Each document is independent.** Don't carry assumptions from one file to another.

**Examples of Violations**:
- ❌ "The last doc had FAQs at line 150, so I'll assume this one does too"
- ❌ "Previous doc used 'source: reddit', so I'll use that here" (without verification)
- ❌ "Last time I removed comment sections, so I'll do it again" (without checking value)

**Correct Approach**:
- ✅ Read each file completely before making decisions
- ✅ Verify source from THIS document's content
- ✅ Evaluate THIS document's FAQs and comments independently

### 4. Idempotence

**Running this skill twice on the same file must produce identical output.**

**Test**:
1. Run formatter on `doc.md` → `doc-v1.md`
2. Run formatter on `doc-v1.md` → `doc-v2.md`
3. `diff doc-v1.md doc-v2.md` must show zero changes

**Violations to Avoid**:
- ❌ Shortening title further on second run
- ❌ Adding/removing tags on second pass
- ❌ Reformatting already-clean sections

**Design for Idempotence**:
- Check if frontmatter is already formatted correctly (skip update)
- Check if HTML tags exist before stripping (skip if clean)
- Check if images are already embedded (skip re-embedding)

## Example Transformation

### Before (Lines 1-60 of flexibility doc):

```markdown
---
title: "r/flexibility Guide: Starting to Stretch - Beginner Flexibility Program"
tags:
  - clippings
---

[Accéder au contenu principal]
r/flexibility Guide
Ouvrir l'onglet de navigation
[Créer une publication]
Posted by u/antranik • 5 years ago

<iframe src="https://ads.example.com"></iframe>

# Starting To Stretch

Starting To Stretch is our own full-body flexibility program designed for beginners!

https://i.imgur.com/VlZ0FVr.png

The routine targets all major muscle groups...

# Frequently Asked Questions

Why didn't you include [insert stretch]?!

We designed Starting to Stretch to be minimalist...

[Règles de Reddit](https://reddit.com/rules)
```

### After:

```markdown
---
title: Beginner Flexibility Guide
source: reddit
created: 2026-03-24
tags:
  - reddit
  - health-flexibility
---

# Starting To Stretch

Starting To Stretch is our own full-body flexibility program designed for beginners!

![shoulder-backbend](https://i.imgur.com/VlZ0FVr.png)

The routine targets all major muscle groups...

# Frequently Asked Questions

Why didn't you include [insert stretch]?!

We designed Starting to Stretch to be minimalist...
```

### Key Changes:

| Element | Before | After | Why |
|---------|--------|-------|-----|
| Title | 20 words with site name | 3 words, keyword-focused | Concise, scannable |
| Tags | Generic "clippings" | `reddit`, `health-flexibility` | Meaningful categorization |
| HTML | `<iframe>` tag present | Removed | Markdown purity |
| Navigation | Reddit UI elements | Stripped | Zero value content |
| Images | Raw URL | `![keyword](url)` | Context + readability |
| FAQ | Preserved | Preserved | Valuable information |
| Footer | Reddit rules link | Removed | Website chrome |

## Common Pitfalls

### Pitfall 1: Vague HTML Removal
**Wrong**: "Remove HTML tags"
**Right**: Use specific patterns, show examples, verify with `<` search after stripping

### Pitfall 2: Over-Aggressive Comment Removal
**Wrong**: "Delete all comments"
**Right**: Keep FAQ-style comments, author clarifications, informational additions

### Pitfall 3: Inconsistent Tag Format
**Wrong**: Using 1 tag or 3+ tags, mixing formats
**Right**: Exactly 2 tags, consistent `source` + `topic-keyword` pattern

### Pitfall 4: Losing Context in Images
**Wrong**: `![image](url)` (generic keyword)
**Right**: `![shoulder-stretch](url)` (descriptive, context-derived)

### Pitfall 5: Skipping Validation
**Wrong**: Assuming markdown is clean after manual edits
**Right**: Always run markdownlint as final step

## Quick Reference Checklist

Before marking task complete, verify:

- [ ] Title is 1-4 words, keyword-focused, no website names
- [ ] Exactly 2 tags: `source` + `topic-keyword`
- [ ] Frontmatter has `created: YYYY-MM-DD` (today)
- [ ] Zero HTML tags remain (search for `<` to verify)
- [ ] Navigation cruft removed (first ~20 lines, footer)
- [ ] All images embedded: `![keyword](url)` format
- [ ] FAQ sections preserved completely
- [ ] Markdownlint passes with disabled rules: `--disable MD013 MD041 MD060 MD045`
- [ ] File is readable, scannable, and looks like native markdown

## Success Metrics

A well-formatted document:
- Passes markdownlint validation
- Contains zero HTML tags
- Has meaningful title (≤5 words)
- Uses exactly 2 descriptive tags
- Removes all website chrome
- Embeds images with context keywords
- Preserves valuable FAQ/comment sections
- Looks like it was written in markdown from scratch

If the document still "feels like a web scrape", you're not done.
