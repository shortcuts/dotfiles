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
