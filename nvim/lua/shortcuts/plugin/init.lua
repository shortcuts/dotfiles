--------------------------
--     Plugin setup
--------------------------
require("shortcuts.plugin.barbar")
require("shortcuts.plugin.lsp")
require("shortcuts.plugin.nvim-autopairs")
require("shortcuts.plugin.theme")
require("shortcuts.plugin.treesitter")
require("shortcuts.plugin.telescope")

-- personal
require("no-neck-pain").setup()
-- vim.opt.rtp:append(os.getenv("HOME") .. "/Documents/no-neck-pain.nvim")
