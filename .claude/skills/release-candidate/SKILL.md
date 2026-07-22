---
name: release-candidate
description: |
  Audit the main branch to determine if the repository is ready for a new release.
  Runs build/lint/test checks, audits documentation consistency against changes since
  the last release, and logs every failure via radin-record to radin's BACKLOG.md.
  Returns a clear go/no-go verdict.

  Use this skill whenever the user wants to:
  - Check if the codebase is release-ready
  - Run a pre-release audit or checklist
  - Validate that docs are in sync with code changes
  - Get a release go/no-go verdict before tagging
  - Run "release checks", "pre-release audit", "is this ready to ship?"
---

# Release Candidate Auditor

Perform a structured go/no-go audit for a release. Every failure is logged, via the
`radin-record` skill, as an entry in radin's `BACKLOG.md` with enough detail that a
developer can act on it without re-running the audit. Never append to `BACKLOG.md`
directly — `radin-record` is the only writer, so route every finding through it.

---

## Step 0: Baseline

Resolve radin's per-project namespace and locate `BACKLOG_FILE` — the same shared
resolution every radin skill/agent uses, never a repo-root file. This is read-only here;
it's only used to count entries before/after, not to write:

```bash
bash "$HOME/.claude/radin-lib/radin-namespace.sh"
```

Read `BACKLOG_FILE` from its output. Record the current entry count so you can detect
net-new entries at the end:

```bash
grep -c '^### ' "$BACKLOG_FILE" 2>/dev/null || echo "0"
```

Also identify the last release tag so you know which commits are "since last release":

```bash
git describe --tags --abbrev=0 2>/dev/null || git log --oneline | tail -1 | awk '{print $1}'
```

---

## Step 1: Build pipeline — format → lint → build

Run in strict order. If any step fails, log it and stop that step (don't run lint if
format fails with non-zero exit, etc.). Each step is a hard gate.

```bash
make format 2>&1
make lint   2>&1
make build  2>&1
```

For each failure, invoke `radin-record` with an item along these lines:

> Log a fix: build pipeline failure in `make <step>`. Exit code <N>. Output:
> <relevant tail of output — last 30 lines>

If all three pass, say so clearly and continue.

---

## Step 2: Unit tests + optional smoke tests

Run unit tests:

```bash
make test 2>&1
```

On failure, invoke `radin-record`:

> Log a fix: `make test` failed. Failures: <paste the failing test names / error summary>

**Smoke tests (Android device):** Check for a connected device:

```bash
adb devices 2>/dev/null | grep -v "List of devices" | grep -v "^$"
```

If a device appears, ask the user: "A device is connected — do you want to run smoke tests
(`make smoke-test`)? They cover all navigation paths and take a few minutes."

If the user says yes, run `make smoke-test 2>&1`. On failure, invoke `radin-record`:

> Log a fix: `make smoke-test` failed. Failing tests: <paste failing test names>

---

## Step 3: Documentation consistency

The codebase is the source of truth. Every user-facing feature change since the last
release must be reflected in at least one of: README.md, AGENTS.md, docs/, docs/wiki/.

### 3a. Get changed files since last release

```bash
git diff --name-only <last-release-tag> HEAD
```

Filter to meaningful changes (exclude test files, build files, .gradle, scripts):
focus on `feature/`, `core/`, `app/` source files plus any docs already changed.

### 3b. Map changes to features

Group changed source files by feature area (map, routes, favorites, settings, joystick,
widget, location engine, etc.). For each feature area with source changes, check:

1. Is there a corresponding doc in `docs/features/`?
2. Is the relevant section in `docs/wiki/` up to date?
3. Does README.md mention the feature if it's user-visible?
4. Does AGENTS.md reflect any new services, modules, or domain model changes?

Read the relevant doc files and compare them against the changed source files. You're
looking for:
- New features with no documentation at all
- Docs that describe old behavior (e.g., references to removed fields, old flow descriptions)
- New constants, services, or domain models in AGENTS.md that aren't documented

For each gap found, invoke `radin-record`:

> Log a fix: documentation gap in <feature area>. Changed source files: <paths>.
> Gap: <describe what's missing or stale — be specific enough that the writer knows
> exactly what to add/update>. Relevant doc file: <path>.

### 3c. Check AGENTS.md domain model accuracy

Specifically verify:
- `Key Services` table matches actual services in the codebase
- Domain models in `docs/domain-models.md` match `:core:model` classes
- Any module added/removed since last release is reflected in the module table

---

## Step 4: Intermediate verdict

Count net-new items added to `BACKLOG_FILE` during this audit:

```bash
grep -c '^### ' "$BACKLOG_FILE"
```

Compare to the baseline from Step 0.

**If new items were added**, stop here and report:

> ❌ Release is NOT ready. N issue(s) were logged to the backlog during this audit.
> Resolve them before tagging a release.
>
> Issues logged:
> - [list the headings of items added during this run]

**If no new items were added**, continue to Step 5.

---

## Step 5: Thermo-nuclear code quality review

All checks passed. Now run a deep structural quality audit over every commit since the
last release.

Get the commit range:

```bash
git log <last-release-tag>..HEAD --oneline
```

Invoke the `radin-review` skill with this scope — it runs the thermo-nuclear review and
logs each finding as its own backlog entry itself, so no separate `radin-record` call is
needed here:

> Review all commits since `<last-release-tag>` (`git diff <last-release-tag> HEAD`).
> Apply the full thermo-nuclear standards and log findings to the backlog.

Only findings that meet the thermo-nuclear approval bar (structural regressions, missed
code-judo opportunities, spaghetti growth, bad abstractions, file-size explosions) should
get logged. Cosmetic nits should not.

---

## Step 6: Final verdict

Count net-new items added to `BACKLOG_FILE` (compare to baseline from Step 0 again).

**If no new items were added across Steps 1–5:**

> ✅ Release is ready. All checks passed: format, lint, build, tests, documentation
> consistency, and thermo-nuclear code quality review.

Then do Step 7 (changelog recommendation) below before finishing.

**If new items were added:**

> ❌ Release is NOT ready. N issue(s) were logged to the backlog during this audit.
> Resolve them before tagging a release.
>
> Issues logged:
> - [list the headings of all items added during this run]

---

## Step 7: Recommend changelog generation (only on ✅ verdict)

Release is ready — recommend the user generate the user-facing changelog next, and record
what that entails so future runs (and other agents) don't have to re-derive it.

Tell the user, verbatim in substance:

> Recommend generating the website changelog now (`docs/wiki/changelog.html`) for the
> upcoming version, before tagging. Also watch for the `release-please` PR — it opens
> automatically (title `chore(main): release <version>`) once these commits land on
> `main`, and its body is the authoritative source list for the changelog entry.

How to generate it (invoke `radin-record` to log this as a chore "next step" note, not a
fix — it's an action item, not a defect):

1. Diff commits since the last release tag: `git log <last-release-tag>..HEAD --oneline`,
   or once the release-please PR exists, read its body directly
   (`gh pr view <PR#> --repo <owner>/<repo> --json body`) — it's already grouped into
   Features/Bug Fixes with commit links and is the ground truth for what shipped.
2. Filter out non-user-facing commits (chore, refactor, docs, test, internal fixes with
   no user-visible effect).
3. Reword each remaining `feat`/`fix` commit into plain, non-technical prose — no code
   symbols, class names, or module names (same audience rule as the rest of `docs/wiki/`,
   see `docs/wiki/CONTRIBUTING.md`).
4. Prepend a new `<h3 id="vXYZ">` section to `docs/wiki/changelog.html`, newest release
   first, linking to `https://github.com/<owner>/<repo>/releases/tag/vX.Y.Z` (fine to add
   before the tag exists — release-please creates it when the PR merges).
5. Cross-check the final bullet list against the release-please PR body to make sure
   nothing user-visible was dropped.

Invoke `radin-record`:

> Log a chore: generate changelog for <version>. Release checks passed. Generate
> `docs/wiki/changelog.html` entry for <version> before tagging. Source:
> `git log <last-release-tag>..HEAD` and/or the release-please PR body once it opens
> (title `chore(main): release <version>`). See release-candidate SKILL.md Step 7 for the
> full procedure.

This note does not flip the verdict to ❌ — it's logged for traceability only.

---

## Notes

- Never suppress lint errors to make the check pass. If you find a suppression that's
  hiding a real issue, log it as a documentation/code-quality issue.
- The doc consistency check is a judgment call — use the feature docs in `docs/features/`
  as the expected baseline. If a doc exists and covers the change, it passes. If no doc
  exists for a user-visible feature, that's a gap.
- Don't add cosmetic or nitpick items to the backlog — only gaps that would confuse a
  developer or leave a user feature undocumented.
