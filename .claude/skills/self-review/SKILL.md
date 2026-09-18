---
name: self-review
description: Summarize what the user shipped on GitHub over a time range, as one Obsidian note with 5-7 one-line bullets per repository, grouped by feature. Use this whenever the user asks what they accomplished, shipped, or worked on over a period - "what did I do since last November", "summarize my year", "self review", "write my perf review", "recap my last quarter", "what did I ship in Q3" - even when they never say the words "self review" or name a repository.
disable-model-invocation: false
argument-hint: "A time range, e.g. 'since last november', 'Q1 2026', 'last 6 months'"
---

The user is writing their own review in Lattice, and will paste this note into it. So two people read it: the user, who checks that it is true and that nothing is missing, and their manager, who reads it to decide what this person owned. Write it in the user's voice, as their words about their own work - not as a report about them.

Merged pull requests are the raw material. The note is the deliverable.

A list of PR titles is not an achievement summary. 339 merged PRs in one repo are maybe six things the user actually did. Your job is that collapse: from titles to themes, from commits to outcomes. A manager who skims the note must be able to name what the user owned.

## Resolve the range first

The user says "since last november", not a date. Convert it before you query, and never type today's date from memory:

```bash
today=$(date +%F)
```

Relative words anchor to that date. "Last November" from 2026-09 means 2025-11-01. When the phrasing has two readings - "last quarter" mid-quarter, "this year" in January - say which one you took in one clause, and carry on. Do not stall on it.

State the resolved window on the note. A reader cannot judge "12 PRs" without knowing over how long.

## Collect the work

Volume is the thing to get right here. A ten-month window runs to several hundred PRs, and a query that silently returns the first 100 will hand the user a review that misses most of their year. `scripts/fetch-prs.sh` in this skill's directory exists for that: GitHub search caps every query at 1000 results, so the script queries one month at a time, paginates inside each month, and dedupes the overlap.

```bash
# run it by its full path under this skill's directory
scripts/fetch-prs.sh 2025-11-01 > "$TMPDIR/self-review-prs.json"          # since, to today
scripts/fetch-prs.sh 2026-01-01 2026-03-31 > "$TMPDIR/self-review-prs.json"  # explicit window
```

Each record is `{repo, number, title, url, mergedAt, labels}`. Sanity-check the count against the window before you go further - a few hundred over a year is normal, 100 exactly means something truncated.

Then group by repository and sort by volume:

```bash
jq '[.[] | .repo] | group_by(.) | map({repo: .[0], n: length}) | sort_by(-.n)' "$TMPDIR/self-review-prs.json"
```

The tail is long: twenty repositories with one or two PRs each is typical, and none of them is a theme. Give a full section to the three or four repositories that carry the work, and fold everything else into one closing line. A manager reading twenty headings learns less than one reading four.

### When titles are not enough

Titles carry most of the signal. Read the bodies only for the PRs you cannot place in a theme, and only those:

```bash
gh pr view <number> --repo <owner/repo> --json title,body,labels,additions,deletions
```

Two other cheap sources of altitude when a repo's titles are all `fix:` and `chore:`:

- The diff size. `gh pr list --author "@me" --repo <r> --state merged --json number,title,additions,deletions` tells you which PRs were the real work.
- Release notes or a CHANGELOG in the repo, which already names features the way the team names them.

Resist reading 50 bodies. That spends the whole budget on input and leaves none for the synthesis, which is the part the user asked for.

## Group by feature, not by month

A theme is something the user can claim in a sentence: "owned the migration of X to Y", "built the rate limiter". Chronology is not a theme, and neither is a directory name.

Build themes like this:

1. Cluster PRs that serve one outcome, whatever their order or their conventional-commit prefix. A `feat:`, three `fix:` and a `test:` that all built one endpoint are one theme, not four.
2. Name each theme by its outcome, not by its mechanism. "Cut index build latency by moving scheduling off the critical path" beats "refactored the scheduler".
3. Rank themes by weight - what the user would lead with in a review - not by PR count. Ten typo fixes outrank nothing.
4. Collapse the leftovers. Maintenance, dependency bumps, and CI repair are real work and belong in one bullet, not six.

Five to seven themes per repository is the target, because that is what a reader holds. Fewer is fine for a repo the user barely touched. More than seven means you stopped one step short of collapsing, so go back and merge the two closest.

### Write the bullets

One line each. A line is one claim, active voice, first person - "I split the ingestion pipeline", not "Clement split" and not "Split". The user pastes these straight into Lattice, so a bullet that needs rewriting before it can be pasted has failed.

**Vary how the lines open.** Seven bullets that all start "I built", "I added", "I fixed" read as a form the user filled in, and a manager skimming them stops seeing the content - the eye locks onto the repeated word and slides past the claim behind it. Let no two consecutive bullets open the same way. Three shapes cover it, and mixing them is the point:

- The plain one: `I bounded the forwarding scans at the sentinel.`
- Outcome first, with the user's hand named inside: `Existing BYOC sources run on the extractor now, because I shipped the algoliaIndex source end to end.`
- The condition or reason first: `Replication only failed under load, so I heartbeat the long Temporal activities.`

Fixing this badly just moves the tic. Four bullets opening "X is mine" is the same failure wearing a different word, and a passive line ("the source was shipped") loses who did the work, which is the one thing a self review exists to say. Keep the user as the actor in every line, and change the sentence around them.

**No links in the bullets.** A trail of `([#7959](url), [#8012](url), [#8104](url))` turns an achievement into a changelog entry - the reader's eye lands on the numbers instead of the claim, and the line stops reading like something a person said about their own work. The receipts go in **Sources** at the bottom, where a manager who wants to check a claim can find them, and everyone else can ignore them.

```markdown
- I split the ingestion pipeline into per-source workers, removing the global lock that capped throughput.
```

Three rules keep the bullets honest:

- **Claim only what the PRs show.** "Reduced p99 by 40%" needs a number from a PR body, a dashboard, or a benchmark. Without one, say what changed, not what it achieved.
- **Never inflate a fix into a feature.** The user's manager may ask about any line. A bullet the user cannot defend costs them more than a bullet they never wrote.
- **Say who did what.** On a PR the user reviewed rather than authored, that is a different contribution - and this note covers authored, merged work only. Leave reviews off unless the user asks for them.

### Sources

One section at the bottom of the note, one line per theme, in the same order as the bullets. The theme name is what links a line back to its bullet, so reuse the bullet's own words - a reader should not have to guess which entry backs which claim.

```markdown
## Sources

- Per-source ingestion workers - [#7959](url), [#8012](url), [#8104](url)
- algoliaIndex source - [#7050](url), [#7052](url), [#7095](url)
```

Pick the three to six PRs that best show the work, not every PR in the theme. A theme built from 80 PRs does not need 80 links - it needs the ones a manager would open: the PR that introduced the thing, the one that was hardest, the one that proves it shipped. A wall of links is as unreadable as no links.

## The note

Write one Markdown file into the Obsidian vault and open it. Never into the user's repository - a self review is not a project artifact.

```bash
vault="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes"
rel="Knowledge/self-review-<slug>.md"   # slug names the window: 2025-11-to-2026-09, q1-2026

mkdir -p "$vault/$(dirname "$rel")"
# write the note, then:
for i in 1 2 3 4 5 6; do obsidian open vault=notes path="$rel" && break; sleep 0.5; done
```

The retry is there because Obsidian indexes a new file with a delay.

The vault sets its own frontmatter convention, so reuse its keys rather than inventing new ones. Match its existing tags too - the taxonomy is flat `field-subfield` kebab-case:

```bash
grep -rhE '^  - [a-z0-9-]+$' "$vault" --include='*.md' | sort -u
```

Every note this skill writes carries `self-review`, so `tag:#self-review` lists them all.

```yaml
---
title: Self review - November 2025 to September 2026
description: One sentence naming the biggest thing shipped in the window.
created: 2026-09-18
tags:
  - self-review
  - engineering
---
```

### Structure

```markdown
# Self review - <window in words>

<Window as dates, PR count, repo count. One line.>

## <owner/repo> - <n> PRs

- <theme bullet, no links>
- ...

## <owner/repo> - <n> PRs

...

## Elsewhere

- <one line folding in the repos with one or two PRs each>

## Sources

- <theme name> - [#123](url), [#124](url)
- ...
```

Lead with the repository the user put the most weight into, not the one with the most PRs, when those differ.

## The slop pass

Write the file, then run the whole note through the `no-ai-slop` skill in Edit mode. The pass covers the note as it stands - frontmatter description, every bullet, the Elsewhere line - because the tics this note collects are about rhythm across lines, and a pass over one bullet at a time cannot see them.

Answer its audience question up front so it does not stall: the user's own manager, reading the user's self review in Lattice to decide what this person owned.

It catches this note's failure mode - bullets that would read identically on someone else's review. "Improved system reliability" says nothing. "Made the retry loop idempotent so a failed build no longer double-charges" says what happened. Leave the Sources links alone; they are identifiers, not prose.

## After the note

The note is the deliverable. Open it and stop.

The user may push back on a specific theme - "that wasn't the point of that work", "you missed the migration". Fix that theme in the file. Do not regenerate the whole note for one bullet.
