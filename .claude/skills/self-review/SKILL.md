---
name: self-review
description: Summarize what the user shipped on GitHub over a time range, as one Obsidian note with one subsection per system. Use whenever the user asks what they accomplished or shipped over a period - "what did I do since last november", "self review", "write my perf review", "recap my last quarter" - including when they never say "self review" or name a repository.
disable-model-invocation: false
argument-hint: "A time range, e.g. 'since last november', 'Q1 2026', 'last 6 months'"
---

Merged pull requests are the raw material. The note is the deliverable, and the
user pastes it into their Lattice self review.

A list of PR titles is a **changelog**, not an achievement summary. 339 merged
PRs in one repo are maybe six things the user actually did. Your job is that
collapse: from titles to themes, from commits to outcomes. A manager who skims
the note must be able to name what the user owned.

## Resolve the range first

The user says "since last november", not a date. Convert it before you query,
and never type today's date from memory:

```bash
today=$(date +%F)
```

Relative words anchor to that date. "Last November" from 2026-09 means
2025-11-01. When the phrasing has two readings - "last quarter" mid-quarter,
"this year" in January - say which one you took in one clause, then carry on.

State the resolved window on the note. A reader cannot judge "12 PRs" without
knowing over how long.

## Collect the work

Volume is the thing to get right here. A ten-month window runs to several
hundred PRs, and a query that silently returns the first 100 hands the user a
review that misses most of their year. `scripts/fetch-prs.sh` exists for that:
GitHub search caps every query at 1000 results, so the script queries one month
at a time, paginates inside each month, and dedupes the overlap.

```bash
# run the script by its full path under this skill's directory
scripts/fetch-prs.sh 2025-11-01 > "$TMPDIR/self-review-prs.json"             # since, to today
scripts/fetch-prs.sh 2026-01-01 2026-03-31 > "$TMPDIR/self-review-prs.json"  # explicit window
```

Each record is `{repo, number, title, url, mergedAt, labels}`. Check the count
against the window before you go further: a few hundred over a year is normal,
and 100 exactly means something truncated.

Then group by repository and sort by volume:

```bash
jq '[.[] | .repo] | group_by(.) | map({repo: .[0], n: length}) | sort_by(-.n)' "$TMPDIR/self-review-prs.json"
```

The tail is long: twenty repositories with one or two PRs each is typical, and
none of them is a theme. Give a full section to the three or four **carrying**
repositories, and fold everything else into one closing line. A manager reading
twenty headings learns less than one reading four.

### Weigh the PRs, then read the heavy ones

A title says a PR happened. The body says what was built.
`fix(ai-enrichment): retry 400 errors` and `feat(ai-enrichment): add perpetual
runs` are one line each in the search results, and nowhere near the same work.
The second body carries what a manager needs: what the system is, what stores
its state, what it calls. A note written from titles alone lists changes to a
service without ever saying what the service does.

So weigh before you read. Diff size is the cheapest proxy, and it comes per
repository:

```bash
gh pr list --author "@me" --repo <owner/repo> --state merged --limit 300 \
  --json number,title,additions,deletions \
  --jq 'sort_by(-(.additions + .deletions))[] | "\(.additions + .deletions)\t#\(.number)\t\(.title)"'
```

Read the bodies of the ten to twenty heaviest PRs in each carrying repository.
Read the PR that introduced each theme too, even when its diff is small:

```bash
gh pr view <number> --repo <owner/repo> --json title,body,additions,deletions
```

Read them for the system, not for the change. Four questions:

- What is this thing, in one sentence a manager would understand?
- What does it integrate with?
- What stores its state, and what moves work through it?
- Why was it built this way?

A `feat:` body usually answers all four in its first paragraph. Those answers
are what a changelog-shaped note is missing. The repo's README or CHANGELOG is
the other cheap source, because it already names the system the way the team
names it.

Keep the budget at ten to twenty bodies per carrying repository, not two
hundred. The long tail of `chore:` and `fix:` titles is already Maintenance.
Spend the reading on the PRs that built something.

## Group by feature, not by month

A theme is something the user can claim in a sentence: "owned the migration of X
to Y", "built the rate limiter". Chronology is not a theme, and neither is a
directory name.

1. Cluster PRs that serve one outcome, whatever their order or their
   conventional-commit prefix. A `feat:`, three `fix:` and a `test:` that all
   built one endpoint are one theme, not four.
2. Name each theme after the system or product area it changed, in the words the
   company uses. The outcome belongs in the opening sentences, not in the
   heading.
3. Rank themes by weight - what the user would lead with in a review - not by PR
   count. A system they built outranks one they patched, and diff size plus the
   `feat:` bodies tell you which is which.
4. Collapse the leftovers. Maintenance, dependency bumps, and CI repair are real
   work and belong in one bullet, not six.

Three to six themes per repository is the target, because that is what a reader
holds. A repo where the user built one big system may hold only two. More than
six means you stopped one step short of collapsing, so merge the two closest.

## Write the note

Read [`WRITING.md`](WRITING.md) for the note's voice, the subsection and bullet
rules, Sources, the frontmatter, and the full structure.

Write one Markdown file into the Obsidian vault and open it. Never into the
user's repository - a self review is not a project artifact.

```bash
vault="$HOME/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes"
rel="Knowledge/self-review-<slug>.md"   # slug names the window: 2025-11-to-2026-09, q1-2026

mkdir -p "$vault/$(dirname "$rel")"
# write the note, then:
for i in 1 2 3 4 5 6; do obsidian open vault=notes path="$rel" && break; sleep 0.5; done
```

The retry is there because Obsidian indexes a new file with a delay.

## The slop pass

Write the file, then run the whole note through the `no-ai-slop` skill in Edit
mode. The pass covers the note as it stands - frontmatter description, every
opening, every bullet, the Elsewhere line - because the tics this note collects
are about rhythm across lines, and a pass over one bullet at a time cannot see
them.

Answer its audience question up front so it does not stall: the user's own
manager, reading the user's self review in Lattice to decide what this person
owned.

It catches this note's failure mode - bullets that would read identically on
someone else's review. "Improved system reliability" says nothing. "Made the
retry loop idempotent so a failed build no longer double-charges" says what
happened. Leave the Sources links alone; they are identifiers, not prose.

## After the note

Open the note and stop.

The user may push back on one theme - "that wasn't the point of that work", "you
missed the migration". Fix that theme in the file, and leave the rest of the
note as it stands.
