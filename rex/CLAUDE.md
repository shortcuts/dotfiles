# rex

Rex is the default terminal multiplexer. It replaces Ghostty and tmux as the daily driver.
Ghostty and tmux stay as a fallback until Rex leaves beta. Do not delete their config.

## Files

- `init.lua` — the only config file. Lua 5.1. It binds keys and defines actions.
- `../scripts/rex-finder` — the program that the `finder` action runs in a floating layer.
- `../aerospace/aerospace.toml` — opens `Rex Beta.app` at login and pins it to workspace 3.
- `../fish/config.fish` — skips `tmux attach` when `REX_SESSION` is set.

## Iterate on the config

1. Edit `init.lua`.
2. Run `rex config check`. It loads the file and prints the binding and action counts.
3. Run `rex config reload`. The server reads the file again. No restart needed.
4. Test the action from the CLI: `rex do <action>` or `rex actions`.
5. Read the result with `rex capture` (screen of a terminal) or `rex ls --json`.

`rex server logs` shows Lua errors that the check does not catch.

## Docs

The docs are a read-only MCP server (`superlogical`). Use it before you guess an API:

- `search_docs` finds a topic.
- `read_doc /rex/docs/reference/lua` is the full Lua API.
- `read_doc /rex/docs/automate/cli` is the CLI.

Rex is in beta. The API changes between releases. `list_changelog` shows what changed.

## Rules

- Run commands from a Rex terminal. `REX_SESSION` and `REX_BLOCK` name the current
  session and block. Target other sessions by label.
- Close every tab and pane that you open for a test.
- Match tmux behavior where it exists. `scripts/rex-finder` copies the naming rule of
  `scripts/tmux-session-finder`, so session labels agree across both tools.
- Rex reports no working directory in `rex ls`. Match sessions by label, not by path.
- Use only paths that resolve on both Macs. Rex ships a server per machine.
- Add a new `.lua` file under `rex/` only with a `!rex/**` rule already in `.gitignore`.
  The existing rule covers it.
