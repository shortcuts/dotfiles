# Neovim architecture

- `nvim/init.lua` — bootstraps lazy.nvim and loads `plugins/` directory
- `nvim/lua/plugins/` — one file per plugin group (lsp, git, fzf, treesitter, etc.)
- `nvim/lua/shortcuts/set.lua` — vim options
- `nvim/lua/shortcuts/map.lua` — keymaps
- `nvim/lua/shortcuts/autocmd.lua` — autocommands
- Plugin dev path is `~/Documents` (local plugin overrides before falling back to GitHub)
- Formatter config: `stylua.toml` at repo root (for Lua formatting)
