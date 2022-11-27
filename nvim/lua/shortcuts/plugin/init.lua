--------------------------
--     Plugin setup
--------------------------
require("shortcuts.plugin.barbar")
require("shortcuts.plugin.lsp")
require("shortcuts.plugin.nvim-autopairs")
require("shortcuts.plugin.theme")
require("shortcuts.plugin.treesitter")
require("shortcuts.plugin.telescope")
require("shortcuts.plugin.toggleterm")

-- personal use
require("mini.test").setup()
require("mini.doc").setup()
-- vim.opt.rtp:append(os.getenv("HOME") .. "/Documents/no-neck-pain.nvim")
-- require("no-neck-pain").setup({ debug = true })
require("no-neck-pain").setup()
