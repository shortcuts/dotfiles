-- Run: rex do ~/.config/rex/agent-notify.lua --all
-- Config files get no events, so a notifier has to be a long-running script.
local last = {} -- block_id -> last state; a notification fires on a change only

local function notify(title, text)
  rex.exec{
    "osascript", "-e",
    string.format("display notification %q with title %q sound name %q", text, title, "Glass"),
  }
end

rex.on("terminal.program_status_changed", function(ctx, ev)
  local rec = ev.record
  if not rec or (ev.id or "") ~= "" then return end -- root record only, child records are workers
  local prev, state = last[ctx.block_id], rec.state
  last[ctx.block_id] = state
  if state == prev then return end

  local label = (rex.session.view{} or {}).label or "?"
  local what = rec.msg or ""
  if state == "blocked" then
    notify(label .. ": needs you", what)
  elseif prev == "working" and (state == "idle" or state == "done") then
    notify(label .. ": finished", what)
  elseif state == "error" then
    notify(label .. ": failed", what)
  end
end)

rex.on("terminal.program_status_removed", function(ctx) last[ctx.block_id] = nil end)
