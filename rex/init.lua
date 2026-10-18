-- Floating fzf over the whitelisted directories; the pick creates its session if missing.
rex.action{
  name  = "finder",
  title = "Open Session for Directory",
  run   = function()
    local _, err = rex.session.new_layer{
      bounds = { 0.15, 0.2, 0.7, 0.5 },
      focus  = true,
      layout = rex.layout.block{
        flavor  = "com.superlogical.terminal.shell",
        options = { command = { "bash", os.getenv("HOME") .. "/.config/scripts/rex-finder" } },
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

-- Open Diff: review the source pane's repository against main in hunk.
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

-- The hunk command for dir. It compares against origin/main, which a local
-- main often lags, and uses main when there is no origin/main. It falls back
-- to the ref itself when the merge base cannot be found.
local function hunk_block(dir)
  return { block = {
    flavor = "com.superlogical.terminal.shell",
    options = {
      cwd = dir,
      command = { "sh", "-c", [[
        ref=main
        git rev-parse --verify -q origin/main >/dev/null && ref=origin/main
        base=$(git merge-base "$ref" HEAD 2>/dev/null) || base=$ref
        exec hunk diff "$base"]] },
    },
  } }
end

rex.action{name = "open_diff_pane", title = "Open Diff in Pane",
  run = function(ctx)
    local dir, err = pane_directory(ctx)
    if not dir then error("Open Diff: " .. tostring(err)) end
    return rex.call("session.new_split", {
      session_id = ctx.session_id,
      anchor_block_id = ctx.block_id,
      direction = "horizontal",
      side = "after",
      focus = true,
      layout = hunk_block(dir),
    })
  end}

rex.action{name = "open_diff_tab", title = "Open Diff in Tab",
  run = function(ctx)
    local dir, err = pane_directory(ctx)
    if not dir then error("Open Diff: " .. tostring(err)) end
    return rex.call("session.new_window", {
      session_id = ctx.session_id,
      window_label = diff_title(dir),
      focus = true,
      layout = hunk_block(dir),
    })
  end}
