--------------------------
--     Plugin setup
--------------------------
require("shortcuts.plugin.barbar")
require("shortcuts.plugin.lsp")
require("shortcuts.plugin.nvim-autopairs")
require("shortcuts.plugin.theme")
require("shortcuts.plugin.treesitter")
require("shortcuts.plugin.telescope")

-- dev
-- require("mini.test").setup()
-- require("mini.doc").setup()
-- vim.opt.rtp:append(os.getenv("HOME") .. "/Documents/no-neck-pain.nvim")
-- require("no-neck-pain").setup({
-- 	debug = true,
-- 	width = 80,
-- 	buffers = {
-- 		right = false,
-- 		background = {
-- 			colorCode = "#2a273f",
-- 		},
-- 	},
-- })

-- main
require("no-neck-pain").setup({
	width = 80,
	right = false,
	background = {
		colorCode = "#2a273f",
	},
})
