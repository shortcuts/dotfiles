-- Floating fzf over the whitelisted directories; the pick creates its session if missing.
rex.action{
  name  = "finder",
  title = "Open Session for Directory",
  run   = function()
    local _, err = rex.session.new_layer{
      bounds = { 0.15, 0.3, 0.7, 0.4 },
      focus  = true,
      layout = rex.layout.block{
        flavor  = "com.superlogical.terminal.shell",
        options = { shell = "none", command = { "bash", os.getenv("HOME") .. "/.config/scripts/rex-finder" } },
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}

rex.bind("cmd+shift+f", "finder")

rex.bind("cmd+n", "session.new")
rex.bind("cmd+shift+n", "client.window.new")

rex.bind("cmd+shift+h", "pane.focus.left")
rex.bind("cmd+shift+j", "pane.focus.down")
rex.bind("cmd+shift+k", "pane.focus.up")
rex.bind("cmd+shift+l", "pane.focus.right")

-- Origin Diff: review the source pane's repository against main in hunk.
-- The diff starts at the merge base with main, so it shows the branch's own
-- commits plus uncommitted work, as a pull request would.

-- Returns the source pane's working directory as a plain path, or nil and a
-- reason. It prefers the directory the shell reports as an OSC 7 file:// URL.
-- A shell without that integration, or a program running in the pane, reports
-- nothing, so it falls back to the working directory of the pane's foreground
-- process, then of the nearest ancestor that has one.
local function pane_directory(ctx)
  if not ctx.block_id then
    return nil, "no source pane"
  end
  local target = { session_id = ctx.session_id, block_id = ctx.block_id }

  local status = rex.block.call("com.superlogical.terminal", "pwd", target)
  local url = status and status.pwd or ""
  local path = url:match("^file://[^/]*(/.*)$") or url
  path = path:gsub("%%(%x%x)", function(hex) return string.char(tonumber(hex, 16)) end)
  if path ~= "" then
    return path
  end

  local process, err = rex.block.call("com.superlogical.terminal", "process", target)
  if not process then
    return nil, err
  end
  if process.foreground and process.foreground.cwd then
    return process.foreground.cwd
  end
  for _, ancestor in ipairs(process.ancestors or {}) do
    if ancestor.cwd then
      return ancestor.cwd
    end
  end
  return nil, "could not find the pane's working directory"
end

-- Returns the tab title for a diff of dir, such as "my-branch->main". A
-- detached HEAD shows its short commit, and a directory outside a repository
-- shows just "diff". The base is spelled main even when the diff compares
-- against origin/main.
local function diff_title(dir)
  -- Runs git in dir and returns its first line of output, or "" on failure.
  local function git(...)
    local result = rex.exec{ "git", "-C", dir, ... }
    if not (result and result.ok) then
      return ""
    end
    return (result.stdout:match("[^\n]*"))
  end
  local branch = git("rev-parse", "--abbrev-ref", "HEAD")
  if branch == "HEAD" then
    branch = git("rev-parse", "--short", "HEAD")
  end
  if branch == "" then
    return "diff"
  end
  return branch .. "->main"
end

local function hunk_block(dir, script)
  return { block = {
    flavor = "com.superlogical.terminal.shell",
    options = {
      cwd = dir,
      command = { "sh", "-c", script },
    },
  } }
end

-- The hunk command for the branch diff. It compares against origin/main, which a local
-- main often lags, and uses main when there is no origin/main. It falls back
-- to the ref itself when the merge base cannot be found.
local branch_script = [[
  ref=main
  git rev-parse --verify -q origin/main >/dev/null && ref=origin/main
  base=$(git merge-base "$ref" HEAD 2>/dev/null) || base=$ref
  exec hunk diff "$base"]]

-- The hunk command for the stacked diff. It compares against the nearest
-- local branch that HEAD contains, which is the parent in a stack. It falls
-- back to the branch diff when there is none.
local head_script = [[
  cur=$(git branch --show-current)
  best=
  for r in $(git for-each-ref --format='%(refname:short)' refs/heads); do
    [ "$r" = "$cur" ] && continue
    n=$(git rev-list --count "$r..HEAD" 2>/dev/null) || continue
    [ "$n" -gt 0 ] && git merge-base --is-ancestor "$r" HEAD || continue
    if [ -z "$best" ] || [ "$n" -lt "$bestn" ]; then best=$r; bestn=$n; fi
  done
  if [ -n "$best" ]; then
    exec hunk diff "$(git merge-base "$best" HEAD)"
  fi
  ]] .. branch_script

-- Opens hunk in a split after the source pane.
local function open_hunk(title, script)
  return function(ctx)
    local dir, err = pane_directory(ctx)
    if not dir then error(title .. ": " .. tostring(err)) end
    return rex.call("session.new_split", {
      session_id = ctx.session_id,
      anchor_block_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      focus = true,
      layout = hunk_block(dir, script),
    })
  end
end

rex.action{name = "origin_diff", title = "Origin Diff",
  run = open_hunk("Origin Diff", branch_script)}

-- Head Diff: review the repository against the PR's base branch.
rex.action{name = "head_diff", title = "Head Diff",
  run = open_hunk("Head Diff", head_script)}

-- Uncommitted Diff: uncommitted changes only.
rex.action{name = "uncommitted_diff", title = "Uncommitted Diff",
  run = open_hunk("Uncommitted Diff", "exec hunk diff")}

rex.bind("cmd+shift+enter", "origin_diff")
