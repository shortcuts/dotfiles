# Writing the note

Two people read it: the user, who checks that it is true and complete, and their
manager, who reads it to decide what this person owned. Write it in the user's
voice, as their words about their own work.

## One subsection per system

Each theme becomes a `###` heading inside its repository section. A reader who
scans the headings alone gets the list of systems this person worked on.

Use the name the company uses - `Crawler autoscaling`, not `scheduler refactor`
and not `Q2 work`. Sources for the real name, in order of trust: the PR labels
in the fetched records, the top-level directories the PRs touch when those map
to features rather than layers, the repo's README or CHANGELOG.

```bash
jq '[.[].labels[]] | group_by(.) | map({label: .[0], n: length}) | sort_by(-.n)' "$TMPDIR/self-review-prs.json"
```

Three bullets per system, five when the user built the whole system. A system
that needs more is two systems. A system with one bullet nobody would name in a
review belongs in the repo's `Maintenance` bullet.

Name the system, never its layers. `AI Enrichment reliability`, `AI Enrichment
caching` and `AI Enrichment monitoring` are three views of one pipeline, and
splitting them buries one large contribution under three small ones. One heading
per system, with the layers as bullets under it.

## Open with the user's part, not the product

The manager already knows what AI Enrichment is. They read this note to find
out what this person did to it. So the opening's subject is the user, in every
sentence: the decisions they made, the parts they built, and how far the system
moved while they held it.

Each subsection opens with two or three sentences, before any bullet. Write them
from the heavy PR bodies, in this order:

1. **Role and scope.** What the user led, designed or contributed to, named for
   this system.
2. **The arc.** Where the system was when they started and where it is now - POC
   to production, pre-beta to paged, one region to three. The arc is what makes
   a year of PRs one achievement, so look for it in the oldest and newest PR in
   the theme.
3. **The parts.** Two or three things they built inside it, named concretely.

```markdown
### AI Enrichment

I led the technical decisions and the core implementation of AI Enrichment, from its POC to production. I designed the run lifecycle customers read their enrichment history from, built the OpenAI client the pipeline depends on, and set up the alerting and on-call rotation the team now runs it by.

- I made enrichment history readable: every event for an app and index now lands on one run, instead of a new run per request that left customers with a list they could not scan.
- Enrichment used to stall whenever OpenAI returned anything unusual, so I rewrote the client to survive the whole error surface, and customer jobs stopped failing on transient upstream errors.
- Taxonomy uploads over roughly 200MB used to fail outright, which blocked our largest catalogs; they complete now.
```

Name the product only where the claim needs it to land - an appositive at most,
never a sentence of its own. Three sentences explaining who the customers are
and what they get is the product marketing page: the manager skips it, and the
user's year is what gets skipped with it.

The reader is an engineering manager. They do not care that the queue is
Postgres, that a cache sits in Redis, or that a retry loop reads rate-limit
headers. They care what the user decided, what shipped, and who stopped being
blocked. Architecture nouns belong in a bullet only when the choice is the
outcome - a rewrite that cut the bill, a limit that stopped losing customer
data. Otherwise cut them.

**Be proud, not boastful.** The line between them is evidence: a big claim with
the work named under it reads as confidence, and the same claim with nothing
under it reads as a brag. "I led the technical decisions and the core
implementation, from POC to production" is a strong claim, and the three parts
named after it are what make it land. Never hedge a claim the PRs support -
"helped with", "was involved in", "contributed to some of" cost the user credit
they earned. Never inflate one they do not - see the scope rules below.

Delete the bullets and the opening should still tell a manager what this person
did for the system. Two openings that read the same way mean the two systems
should merge.

`Maintenance` takes no opening. It is already one line.

## Scope claims

Three claim shapes, in descending order of what they need behind them:

- `I led the technical decisions on X` - the PRs cannot prove this, and it is
  often the truest and most valuable line in the note. Write it where the user's
  PRs introduced the designs others then built on, then flag it for them:

  ```markdown
  > [!check] Confirm before pasting
  > "I led the technical decisions on AI Enrichment" - your PRs show you introduced the run lifecycle, the settings schema and the retry client, but not that the team's decisions were yours. Keep it if that is true, otherwise cut to "I designed".
  ```

  One callout per unprovable claim, directly under the opening that carries it.
  The user deletes the callout and keeps the line, or fixes the line. Never
  silently drop the claim to stay safe, and never assert it without the flag.
- `I designed X` / `I introduced X` - the PR that first built X is the user's.
  Check the theme's oldest PR before writing it.
- `I am a core contributor of X` - the PR count in X carries it. A manager can
  check that number.

Everything below those is a build claim, and the bullets carry it.

## The bullets

One line each: one claim, active voice, first person - "I split the ingestion
pipeline", not "Clement split" and not "Split". The user pastes these straight
into Lattice, so a bullet that needs rewriting before it can be pasted has
failed.

**Vary how the lines open.** Seven bullets that all start "I built", "I added",
"I fixed" read as a form the user filled in: the eye locks onto the repeated
word and slides past the claim behind it. Let no two consecutive bullets open
the same way, with three shapes mixed:

- Plain: `I stopped duplicate records reaching customer indices.`
- Outcome first, the user's hand named inside: `Existing BYOC customers can point at an Algolia index directly now, because I shipped the algoliaIndex source end to end.`
- Condition or reason first: `Replication only failed for the biggest accounts, so I fixed the long-running jobs that dropped their data.`

Four bullets opening "X is mine" is the same tic wearing a different word. A
passive line ("the source was shipped") loses who did the work, which is the one
thing a self review exists to say. Keep the user as the actor in every line, and
change the sentence around them.

**Scope belongs in the opening, work belongs in the bullets.** A bullet says what
the user built, so a bullet that claims a seat instead - own, owned, mine, my
area - spends a line without naming anything:

- `I own AI Enrichment's run lifecycle.` becomes `I built the run lifecycle customers read their enrichment history from.`
- `The Datadog monitors and PagerDuty schedules are mine.` becomes `I set up this service's alerting and on-call rotation, then tuned it until the team stopped being paged on noise.`

The role and the arc go in the opening, once, under the rules above.

**Receipts live in Sources.** A trail of `([#7959](url), [#8012](url))` inside a
bullet lands the reader's eye on the numbers instead of the claim, which is what
turns a note into a changelog. Keep the bullets prose:

```markdown
- I split the ingestion pipeline per source, so one slow customer no longer holds up everybody else's ingestion.
```

**A bullet is a claim, not a PR.** `fix: retry 400 errors` is evidence. It
belongs inside a bullet about making the OpenAI client survive its error
surface, next to the 5xx retries and the rate-limit backoff. The test: would the
manager ask a follow-up question about this line? If not, merge it into the
claim it supports, or let `Maintenance` carry it.

Two rules keep the bullets defensible, because the manager may ask about any
line:

- **Claim only what the PRs show.** "Reduced p99 by 40%" needs a number from a
  PR body, a dashboard, or a benchmark. Without one, say who stopped being
  blocked, and by what.
- **Keep a fix a fix.** A bullet the user cannot defend costs them more than a
  bullet they never wrote.

This note covers work the user authored and merged. A PR they reviewed is a
different contribution, so leave reviews out unless the user asks for them.

## Sources

One section at the bottom, one line per system, in the same order as the
sections above. Reuse the `###` heading verbatim, so a reader can match a line
to its system without guessing.

```markdown
## Sources

- Per-source ingestion workers - [#7959](url), [#8012](url), [#8104](url)
- algoliaIndex source - [#7050](url), [#7052](url), [#7095](url)
```

Pick the three to six PRs that best show the work: the PR that introduced the
thing, the hardest one, the one that proves it shipped. A theme built from 80
PRs needs the ones a manager would open, because a wall of links is as
unreadable as none.

## Frontmatter

The vault sets its own frontmatter convention, so reuse its keys. Match its
existing tags too - the taxonomy is flat `field-subfield` kebab-case:

```bash
grep -rhE '^  - [a-z0-9-]+$' "$vault" --include='*.md' | sort -u
```

Every note this skill writes carries `self-review`, so `tag:#self-review` lists
them all.

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

## Structure

```markdown
# Self review - <window in words>

<Window as dates, PR count, repo count. One line.>

## <owner/repo> - <n> PRs

### <system>

<two or three sentences: the user's role, the arc of the system under them, the parts they built>

- <bullet, no links>
- ...

### <system>

<same shape: role, arc, parts>

- ...

### Maintenance

- <one line folding in dependency bumps, CI repair, chores>

## <owner/repo> - <n> PRs

...

## Elsewhere

- <one line folding in the repos with one or two PRs each>

## Sources

- <system heading> - [#123](url), [#124](url)
- ...
```

Lead with the repository the user put the most weight into, not the one with the
most PRs, when those differ.
