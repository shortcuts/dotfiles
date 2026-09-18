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
caching` and `AI Enrichment monitoring` are three views of one pipeline, and a
manager who reads all three still cannot say what AI Enrichment is. One heading
per system, with the layers as bullets under it.

## Open with what the thing is

Each subsection opens with two or three sentences, before any bullet. Name the
system, say what it does, say what it runs on and what it talks to, then name
the user's part. Write it from the heavy PR bodies, not from the bullets.

```markdown
### AI Enrichment

I am a core contributor of AI Enrichment, the asynchronous pipeline that enriches customer records with OpenAI before they reach an index. Jobs commit to a write-ahead log in Postgres, workers pull the oldest first, and every job reports into a perpetual run keyed to its app and index. I built the run lifecycle, the OpenAI client, the caching layer, and the on-call setup.

- I added perpetual runs, keyed by a deterministic UUID on the appID and index pair, so every enrichment event lands on one run instead of a new run per request.
- OpenAI's error surface is wide, so I wrote a custom retry client that covers the 400s, the 5xx, and the rate-limit headers the default client ignored.
- `POST /enrichments/taxonomies` OOM'd at the 200MB limit, so I streamed the embedding inserts with `CopyFrom` instead of building one `pgx.Batch`.
```

The opening states architecture no single bullet mentions - the queue, the
storage, the third-party API. Delete the bullets and it should still teach a
reader something. Two openings that read the same way mean the two systems
should merge. It carries no links, and it claims only the scope the PRs show:
describe the system in full, then name the user's part of it in the same breath.

A manager who reads only the headings and the openings can explain each system
to someone else, and say what this person built inside it.

`Maintenance` takes no opening. It is already one line.

## The bullets

One line each: one claim, active voice, first person - "I split the ingestion
pipeline", not "Clement split" and not "Split". The user pastes these straight
into Lattice, so a bullet that needs rewriting before it can be pasted has
failed.

**Vary how the lines open.** Seven bullets that all start "I built", "I added",
"I fixed" read as a form the user filled in: the eye locks onto the repeated
word and slides past the claim behind it. Let no two consecutive bullets open
the same way, with three shapes mixed:

- Plain: `I bounded the forwarding scans at the sentinel.`
- Outcome first, the user's hand named inside: `Existing BYOC sources run on the extractor now, because I shipped the algoliaIndex source end to end.`
- Condition or reason first: `Replication only failed under load, so I heartbeat the long Temporal activities.`

Four bullets opening "X is mine" is the same tic wearing a different word. A
passive line ("the source was shipped") loses who did the work, which is the one
thing a self review exists to say. Keep the user as the actor in every line, and
change the sentence around them.

**Name the work, not the position.** Ownership words - own, owned, mine, my area
- name a seat on a team, skip what the user built, and claim a scope no PR
proves. Replace the position with the work, and keep the scope checkable:

- `I own AI Enrichment's run lifecycle.` becomes `I am a core contributor of the AI Enrichment pipeline, and I built its run lifecycle: perpetual runs, cold-start pickup, and run timeouts.`
- `The Datadog monitors and PagerDuty schedules are mine.` becomes `I wrote the Datadog monitors and the PagerDuty schedules for this service, then tuned them until they stopped paging on noise.`

When the user's scope across a repo really is broad, write `I am a core
contributor of X`. A manager can check that against the PR count.

**Receipts live in Sources.** A trail of `([#7959](url), [#8012](url))` inside a
bullet lands the reader's eye on the numbers instead of the claim, which is what
turns a note into a changelog. Keep the bullets prose:

```markdown
- I split the ingestion pipeline into per-source workers, removing the global lock that capped throughput.
```

**A bullet is a claim, not a PR.** `fix: retry 400 errors` is evidence. It
belongs inside a bullet about making the OpenAI client survive its error
surface, next to the 5xx retries and the rate-limit backoff. The test: would the
manager ask a follow-up question about this line? If not, merge it into the
claim it supports, or let `Maintenance` carry it.

Two rules keep the bullets defensible, because the manager may ask about any
line:

- **Claim only what the PRs show.** "Reduced p99 by 40%" needs a number from a
  PR body, a dashboard, or a benchmark. Without one, say what changed.
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

<two or three sentences: what the system is, what it runs on and talks to, what the user built in it>

- <bullet, no links>
- ...

### <system>

<two or three sentences, same shape>

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
