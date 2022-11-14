local PREVIEWERS = require("telescope.previewers")
local ACTIONS = require("telescope.actions")

require("telescope").setup({
	defaults = {
		file_sorter = require("telescope.sorters").get_fzy_sorter,
		color_devicons = true,
		path_display = { "truncate" },

		file_previewer = PREVIEWERS.vim_buffer_cat.new,
		grep_previewer = PREVIEWERS.vim_buffer_vimgrep.new,
		qflist_previewer = PREVIEWERS.vim_buffer_qflist.new,
		mappings = {
			i = {
				["<C-x>"] = false,
				["<C-v>"] = false,
				["<S-CR>"] = ACTIONS.select_vertical,
			},
		},
		layout_config = {
			horizontal = {
				preview_width = 0.5,
				results_width = 0.85,
			},
			vertical = {
				mirror = false,
			},
			width = 0.87,
			height = 0.85,
			preview_cutoff = 150,
			preview_width = 150,
		},

		-- common files to ignore
		file_ignore_patterns = { "^.git/", "^node_modules/", "^plugged/" },

		-- default arguments with `--hidden` added to search in hidden files
		vimgrep_arguments = {
			"rg",
			"--color=never",
			"--no-heading",
			"--with-filename",
			"--line-number",
			"--column",
			"--smart-case",
			"--hidden",
		},
	},
	pickers = {
		find_files = {
			hidden = true,
		},
	},
	extensions = {
		file_browser = {
			-- disables netrw and use telescope-file-browser in its place
			hijack_netrw = true,
			initial_mode = "normal",
			path = "%:p:h",
		},
	},
})

require("telescope").load_extension("file_browser")
