---
name: radin-review
description: |
  Run a thermo-nuclear code quality review over a given scope (commit hash, PR,
  directory, or a natural-language range like "last commits since yesterday") and
  log every finding as a structured entry in ISSUES.md. Use whenever the user invokes
  /radin-review, or asks to "review and log to issues", "audit this commit/PR/
  directory and file issues", "turn this review into a backlog", or wants thermo-nuclear
  findings persisted instead of just printed to the terminal.
---
# Review to Issues

Run `/thermo-nuclear` code quality review against caller-specified scope, persist every finding as structured entry in `ISSUES.md` instead of just printing to terminal. Turns one-off strict review into durable backlog `radin-orchestrator` (or human) can work through later.

## Step 1: Resolve scope argument

User passes one argument, can be any of:

- **Commit hash** (e.g. `a1b2c3d`) — review that single commit's changes:
  `git show <hash>` / `git diff <hash>^..<hash>`.
- **PR reference** (e.g. `#123`, `123`, or GitHub PR URL) — resolve via
  `gh pr diff <number>` (add `--repo <owner>/<repo>` if URL points elsewhere than
  current repo's remote).
- **Directory path** — review current state of everything under that path (not diff —
  read files as they stand today).
- **Natural-language range** (e.g. `"last commits since yesterday"`,
  `"commits since Monday"`, `"the last 5 commits"`) — translate into concrete
  `git log` / `git diff` invocation, e.g. `git log --since=yesterday --oneline` then
  `git diff <oldest-of-those>^..HEAD`.
- **No argument** — default to working branch's diff against its base
  (`git merge-base main HEAD` or `master`, whichever exists), same default `/code-review`
  would use.

Argument ambiguous (e.g. could be commit hash or directory name, or PR number doesn't
resolve via `gh`) — ask user, don't guess.

State resolved scope back in one line before proceeding, e.g.:
`Scope: commit a1b2c3d` or `Scope: PR #123 (algolia/foo)` or `Scope: directory src/auth/`.

## Step 2: Resolve project namespace, locate ISSUES_FILE

Radin never writes backlog/state files into target repo. Resolve canonical,
per-project namespace under `~/.claude/.radin/` first:

```bash
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if command -v md5 >/dev/null 2>&1; then
  HASH_CMD="md5"
else
  HASH_CMD="md5sum"
fi
if [ -n "$REPO_ROOT" ]; then
  SLUG="$(basename "$REPO_ROOT")-$(printf '%s' "$REPO_ROOT" | $HASH_CMD | cut -c1-8)"
else
  SLUG="no-repo-$(printf '%s' "$PWD" | $HASH_CMD | cut -c1-8)"
fi
NAMESPACE_DIR="$HOME/.claude/.radin/projects/$SLUG"
mkdir -p "$NAMESPACE_DIR/state" "$NAMESPACE_DIR/plans" "$NAMESPACE_DIR/reviews"
ISSUES_FILE="$NAMESPACE_DIR/ISSUES.md"

REGISTRY="$HOME/.claude/.radin/registry.json"
[ -f "$REGISTRY" ] || echo '{}' > "$REGISTRY"
TMP="$REGISTRY.tmp.$$"   # same dir as $REGISTRY -- required for atomic mv
if command -v jq >/dev/null 2>&1; then
  jq --arg k "$SLUG" --arg p "$REPO_ROOT" --arg t "$(date -u +%FT%TZ)" \
     '.[$k] = {path: $p, updated_at: $t}' "$REGISTRY" > "$TMP" && mv "$TMP" "$REGISTRY"
elif command -v python3 >/dev/null 2>&1; then
  python3 -c "
import json
r = json.load(open('$REGISTRY'))
r['$SLUG'] = {'path': '$REPO_ROOT', 'updated_at': __import__('datetime').datetime.utcnow().isoformat()+'Z'}
json.dump(r, open('$TMP', 'w'), indent=2)
" && mv "$TMP" "$REGISTRY"
else
  echo "note: no jq/python3 found, skipping registry.json index update (non-critical)" >&2
fi
```

`registry.json` best-effort index — skipped upsert never blocks `$ISSUES_FILE`
from being written correctly.

- Record baseline line count (`wc -l "$ISSUES_FILE" 2>/dev/null || echo 0`) so you
  can report net-new findings at end.

## Step 3: Run reviews

If `code-review-graph` is installed and wired for this repo (`command -v code-review-graph`
succeeds, and its MCP tools are available) use `detect_changes` + `get_review_context`
against the resolved scope first — risk-scored, token-efficient source context beats
reading raw diffs/files cold. Not installed or not wired here: fall back to
`git show`/`git diff`/reading the files directly, same as Step 1's scope resolution.

Invoke `/thermo-nuclear` against the resolved scope. Apply full standards: ambitious
code-judo restructuring, 1k-line file smell, spaghetti branching, boundary/type
cleanliness, canonical-layer leaks, orchestration atomicity — see that skill for
complete rubric. Don't water down for this skill.

Then invoke the ponytail complexity pass over the same scope — `/ponytail-review` for a
commit/PR/range (diff scope), `/ponytail-audit` for a directory (whole-tree scope). It
hunts a different axis than thermo-nuclear (over-engineering, dead flexibility,
reinvented stdlib/native code) and is meant to complement it, not duplicate it.

## Step 4: Log every finding to ISSUES.md

`ISSUES_FILE` is organized into top-level category sections — `## feat`,
`## fix`, `## chore`, `## refactor` — same vocabulary as a conventional-commit
type. Create the file with a `# Issues` heading first if it doesn't exist yet.

For each finding review surfaces, classify it:

- **fix** — the finding is an actual bug: incorrect behavior, not just
  structure.
- **refactor** — the finding is structural: spaghetti branching, a canonical-
  layer leak, a 1k-line-file smell, orchestration atomicity, or any other
  restructuring thermo-nuclear calls for that doesn't change behavior. Every
  ponytail-pass finding (`delete:`/`stdlib:`/`native:`/`yagni:`/`shrink:`) is
  structural by definition — classify these as refactor too.

If the section for that category doesn't exist yet, create it (in canonical
order feat → fix → chore → refactor relative to whichever sections already
exist), then append the entry under it:

```
### <short title>
**Scope:** <what was reviewed — commit hash / PR / directory / range from Step 1>
**Location:** <file path(s) and function/line if applicable>
**Finding:**
<the structural problem, stated the way the thermo-nuclear skill states it — direct,
specific, no hedging>
**Preferred remedy:**
<the concrete restructuring suggested — extract helper, delete wrapper, split file,
reframe state model, etc.>
```

The description under the title should be as exhaustive as the finding
warrants — `Scope`/`Location`/`Finding`/`Preferred remedy` are that
description's internal structure, not a separate schema.

Log every finding clearing either pass's bar — thermo-nuclear's or ponytail's — don't
filter down to only the scariest one, but also don't pad the file with cosmetic nits
neither skill would have raised itself. One entry per finding, appended in order the
reviews produced them.

## Step 5: Report back

Tell user:

- Resolved scope reviewed.
- How many findings logged (net-new lines/entries vs. Step 2 baseline).
- Path to `ISSUES.md` written.
- Zero findings: say clearly the review passed both thermo-nuclear's and ponytail's
  approval bar with no logged issues — don't write an empty entry just to prove the
  skill ran.
