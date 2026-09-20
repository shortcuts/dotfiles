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

A title says a PR happened. The body says what the user decided.
`fix(ai-enrichment): retry 400 errors` and `feat(ai-enrichment): add perpetual
runs` are one line each in the search results, and nowhere near the same work.
The second body carries what a manager needs: the design the user chose, what it
replaced, and what it unblocked. A note written from titles alone lists changes
to a service without ever saying who drove them.

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

Read them for the user's hand in the work, not for how the code works. Four
questions:

- What did the user decide here, and what did the decision replace?
- What part of the system is theirs - did they introduce it, or extend someone
  else's?
- What did this let people do that they could not do before?
- Where was this system when they started, and where is it now?

A `feat:` body usually answers the first three in its motivation section, and
the fourth comes from reading the theme's oldest and newest PR together - a
service that went from POC to paged production is the claim the note is for.
The implementation nouns in the body - Redis, the retry loop, the cache - are
not the answers. They are the evidence a claim rests on, so note them and move
on.

The manager already knows what the product does, so do not spend the reading
budget on collecting product descriptions. Spend it on the two things they
cannot get anywhere else: which decisions were the user's, and how far the
system moved under them.

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

It catches this note's failure modes. One is a bullet that would read
identically on someone else's review: "improved system reliability" says
nothing, while "made the retry loop idempotent so a failed build no longer
double-charges" says what happened. The other is an opening that explains the
product back to the manager who owns it - if the first sentence of a subsection
has the system as its subject rather than the user, rewrite it. Leave the Sources links alone; they are identifiers, not prose.

## Grill the claims

Open the note, then invoke the `grilling` skill on it. The note is a draft of
how the user describes their own year to their manager, and only the user knows
which claims are true. A note written from PRs alone cannot know who led a
decision, which theme they want to be remembered for, or how hard they are
willing to push.

Grilling finds facts itself, so bring the PR evidence to each question instead
of asking the user to supply it. The first round's frontier is the three things
the note cannot settle:

- **Every `[!check]` callout, one question each.** Quote the claim, say which
  PRs stand behind it, and name what they do not show. Recommend keeping it.
- **The lead.** Name the theme you put first and why - weight, not PR count -
  and ask whether that is what they want their manager to read first.
- **The ceiling.** Ask how far up they want the claims pitched, with the same
  theme written at two heights so they pick against real sentences rather than
  an adjective:

  ```
  ➡️ "I led the technical decisions and the core implementation of AI Enrichment"
     "I designed and built the core of AI Enrichment"
  ```

Later rounds come from what their answers reshape, and nothing else. An answer
that raises one claim usually raises its neighbours - a user who led AI
Enrichment's decisions probably led the indexing extension's too - so ask about
the neighbours in the next round instead of assuming either way. An answer that
cuts a claim may collapse the theme into another, or drop it to `Maintenance`.

Stop when the frontier is empty. Do not rewrite the note mid-grill: collect the
answers, apply them in one pass, then run the changed subsections back through
the `no-ai-slop` skill, because a claim pitched higher often arrives with the
hedges and the puffery the first pass removed.

## After the grill

Save, reopen the note, and stop.

The user may still push back on one theme - "that wasn't the point of that
work", "you missed the migration". Fix that theme in the file, and leave the
rest of the note as it stands.
