--------------------------
-- Global
--------------------------

require("shortcuts.set")
require("shortcuts.pack")
require("shortcuts.map")
require("shortcuts.plugin")

vim.cmd("colorscheme catppuccin")

-- executes on file open
vim.api.nvim_create_augroup("OnFileOpen", { clear = true })
vim.api.nvim_create_augroup("OnWinEnter", { clear = true })
vim.api.nvim_create_autocmd({ "BufReadPost", "FileReadPost", "BufEnter" }, {
	group = "OnFileOpen",
	pattern = "*",
	callback = function()
		vim.cmd("normal zR")
	end,
})

-- -- enables NNP on WinEnter if it's not the case yet
-- vim.api.nvim_create_augroup("OnWinEnter", { clear = true })
-- vim.api.nvim_create_autocmd({ "WinEnter" }, {
-- 	group = "OnWinEnter",
-- 	pattern = "*",
-- 	callback = function()
-- 		require("no-neck-pain").start()
-- 	end,
-- })
