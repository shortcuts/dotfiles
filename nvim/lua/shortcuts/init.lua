--------------------------
-- Global
--------------------------

require("shortcuts.set")
require("shortcuts.pack")
require("shortcuts.map")
require("shortcuts.plugin")

vim.cmd("colorscheme catppuccin")

-- function to create a list of commands and convert them to autocommands
-------- This function is taken from https://github.com/norcalli/nvim_utils
local function nvim_create_augroups(definitions)
	for group_name, definition in pairs(definitions) do
		vim.api.nvim_command("augroup " .. group_name)
		vim.api.nvim_command("autocmd!")
		for _, def in ipairs(definition) do
			local command = table.concat(vim.tbl_flatten({ "autocmd", def }), " ")
			vim.api.nvim_command(command)
		end
		vim.api.nvim_command("augroup END")
	end
end

local autoCommands = {
	open_all_folds = {
		{ "BufReadPost,FileReadPost", "*", "normal zR" },
	},
}

nvim_create_augroups(autoCommands)

vim.api.nvim_create_augroup("OnVimEnter", { clear = true })
vim.api.nvim_create_autocmd({ "VimEnter" }, {
	group = "OnVimEnter",
	pattern = "*",
	callback = function()
		vim.schedule(function()
			-- enable NNP on VimEnter
			require("no-neck-pain").start()

			-- open telescope on VimEnter, inspired by https://github.com/nvim-telescope/telescope-file-browser.nvim/pull/111
			local bufname = vim.api.nvim_buf_get_name(0)
			local netrw_bufname
			if vim.fn.isdirectory(bufname) == 0 then
				netrw_bufname = vim.fn.expand("#:p:h")
				return
			end

			if netrw_bufname == bufname then
				netrw_bufname = nil
				return
			else
				netrw_bufname = bufname
			end

			require("telescope.builtin").find_files({ initial_mode = "normal" })
		end)
	end,
})
