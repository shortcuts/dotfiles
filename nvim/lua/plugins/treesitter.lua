-- copied from https://github.com/ThePrimeagen/init.lua/blob/8905e229b3c002a020dce8eb88376a9f6c5181b3/lua/theprimeagen/lazy/treesitter.lua#L4
return {
	{
        'nvim-treesitter/nvim-treesitter',
        dependencies = { 'neovim-treesitter/treesitter-parser-registry' },
		build = ":TSUpdate",
		lazy = false,
        branch = "main",
		init = function()
			local parsers = {
				"lua",
				"vim",
				"vimdoc",
				"query",
				"javascript",
				"typescript",
				"tsx",
				"terraform",
				"sql",
				"python",
				"rust",
				"html",
				"css",
				"yaml",
				"json",
				"gitignore",
				"go",
			}

			local group = vim.api.nvim_create_augroup("ShortcutsTreesitter", { clear = true })
			vim.api.nvim_create_autocmd({ "BufEnter", "FileType" }, {
				group = group,
				callback = function()
					if vim.bo.buftype ~= "" then
						return
					end

					pcall(vim.treesitter.start, 0)
				end,
			})

			vim.api.nvim_create_autocmd("User", {
				group = group,
				pattern = "VeryLazy",
				once = true,
				callback = function()
                    require("nvim-treesitter").install(parsers)
				end,
			})
		end,
	},
    {
        "nvim-treesitter/nvim-treesitter-context",
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        event = "BufReadPre",
        opts = {
            max_lines = 2,
        },
    },
}
