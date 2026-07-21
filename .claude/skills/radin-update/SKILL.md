---
name: radin-update
description: Refresh radin's agents/skills in ~/.claude/ from the latest published release (or main) by re-running install.sh, overwriting what's there. Use when the user asks to "update radin", "pull the latest radin", "reinstall radin", or runs /radin-update.
---
# radin: Update

`install.sh` covers fresh interactive install only. Skill re-applies against
already-installed radin so `~/.claude/agents/` and `~/.claude/skills/`
overwrite with the latest changes. Companion-tool installers in `install.sh`
already skip-if-installed, so re-run safe.

`install.sh`'s source resolution has two modes — check which one applies
before doing anything else:

- **Downloaded tarball** (the normal `curl | bash` path): source lives at
  `~/.claude/radin` (or `RADIN_ROOT_OVERRIDE`), marked by a `.radin-version`
  file, no `.git` dir. Nothing to pull — just re-run `install.sh`, which
  re-downloads the latest release (or `main`) itself.
- **Manual dev clone** (someone hacking on radin itself, ran `git clone` +
  `./install.sh`): source has a `.git` dir. Needs an explicit `git pull`
  before re-running `install.sh`.

## Step 1: Locate source

Read `~/.claude/.radin/install_root` — `install.sh` writes the resolved
source path there each run. File missing (install predates this skill): ask
user for the path instead of guessing.

## Step 2: Branch on source mode

```bash
SRC="$(cat "$HOME/.claude/.radin/install_root")"
if [ -d "$SRC/.git" ]; then
  MODE=git-clone
elif [ -f "$SRC/.radin-version" ]; then
  MODE=tarball
else
  echo "unrecognized source at $SRC, stop"; exit 1
fi
```

### git-clone mode

Confirm clean working tree before touching anything:

```bash
cd "$SRC"
git status --porcelain
```

Anything printed: stop, report — don't pull over uncommitted local changes.
Otherwise:

```bash
git pull
git log --oneline 'HEAD@{1}..HEAD'
```

Show the user the commit list before applying anything.

### tarball mode

```bash
cat "$SRC/.radin-version"
```

Note the current version/commit so it can be compared after re-running
`install.sh`. No dirty-tree check needed — this dir is disposable, wiped and
re-downloaded by `install.sh` on every run.

## Step 3: Confirm, then re-run install.sh

Ask explicit y/n confirmation before applying — overwrites files under
`~/.claude/agents/` and `~/.claude/skills/`. On yes, run:

```bash
./install.sh
```

from the source directory (`$SRC`, whichever mode). Companion-tool prompts
(rtk, caveman, code-review-graph) fire same as fresh install — expected,
no-op if already installed.

## Step 4: Report back

- git-clone mode: old commit → new commit, which `agents/*.md` /
  `skills/*/SKILL.md` files changed in the pulled range
  (`git diff --stat 'HEAD@{1}..HEAD'`).
- tarball mode: old version → new version (`cat "$SRC/.radin-version"`
  again after the run).
- Either mode: whether any companion-tool prompt ran.

## Non-goals

- Don't update rtk/caveman/code-review-graph themselves — manage own updates
  via own tooling, this skill only refreshes radin's own agents/skills.
- Don't force pull through dirty working tree — stop, report instead.
- Don't touch per-project state under `~/.claude/.radin/projects/` —
  backlog/execution data, unrelated to updating radin's own code.
