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

-- Floating programs (lazygit, radin) that open over the source pane's repository.

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

local FLOAT_OPEN = { 0.025, 0.025, 0.95, 0.95 }

-- Returns the floating layer that holds a block with this label, plus whether
-- its window holds block_id and the id of the window that does. It returns nil
-- when the session has no such layer. A layer's block label finds it.
local function find_float(session_id, block_id, label)
  local view = rex.call("session.view", { session_id = session_id })
  local found
  local here, window_id
  for _, window in ipairs(view and view.windows or {}) do
    local layer_found, holds
    for _, layer in ipairs(window.layers or {}) do
      for _, block in ipairs(layer.blocks or {}) do
        if block.block_id == block_id then holds = true end
        if layer.kind == "floating" and block.label == label then
          layer_found = layer
        end
      end
    end
    if holds then window_id = window.window_id end
    if layer_found then
      found = layer_found
      here = holds
    end
  end
  return found, here, window_id
end

-- Defines an action that toggles the session's one floating program: it opens
-- the program in a floating layer over the source pane's directory, then
-- minimizes and restores it on each press. The program keeps running while
-- minimized. A layer cannot move between windows, so a press from another
-- window closes it and opens a fresh one there.
local function float_toggle(label, title, script)
  rex.action{name = label, title = title,
    run = function(ctx)
      local layer, here, window_id = find_float(ctx.session_id, ctx.block_id, label)
      if layer and here then
        rex.call("session.set_layer_state", {
          session_id = ctx.session_id,
          layer_id = layer.layer_id,
          state = layer.state == "minimized" and "normal" or "minimized",
          focus = layer.state == "minimized",
        })
        return
      end
      if layer then
        rex.call("session.close_layer", { session_id = ctx.session_id, layer_id = layer.layer_id })
      end

      local dir, err = pane_directory(ctx)
      if not dir then error(title .. ": " .. tostring(err)) end
      rex.call("session.new_layer", {
        session_id = ctx.session_id,
        window_id = window_id,
        bounds = FLOAT_OPEN,
        focus = true,
        layout = { block = {
          flavor = "com.superlogical.terminal.shell",
          label = label,
          options = { cwd = dir, shell = "none", command = { "sh", "-c", script } },
        } },
      })
    end,
  }
end

float_toggle("lazygit", "Lazygit", 'export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml" PATH="$HOME/.local/share/mise/installs/lazygit/latest:$HOME/.local/share/mise/shims:$PATH"; exec lazygit')
float_toggle("radin", "Radin", 'export PATH="$HOME/.local/bin:$PATH"; exec radin')

rex.bind("cmd+shift+enter", "lazygit")
rex.bind("cmd+shift+r", "radin")
