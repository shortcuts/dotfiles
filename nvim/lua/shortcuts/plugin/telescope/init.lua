local PREVIEWERS = require("telescope.previewers")

require("telescope").setup({
    defaults = {
        -- theme
        color_devicons = true,
        sorting_strategy = "descending",
        path_display = { "truncate" },
        layout_strategy = "vertical",
        layout_config = {
            vertical = {
                height = 0.9,
                preview_cutoff = 0,
                preview_height = 0.6,
                results_height = 0.3,
                width = 0.7,
            },
        },

        -- previewers
        file_previewer = PREVIEWERS.cat.new,
        grep_previewer = PREVIEWERS.vimgrep.new,
        qflist_previewer = PREVIEWERS.qflist.new,

        -- common files to ignore
        file_ignore_patterns = {
            -- folders, wherever they are
            "**node_modules/",
            "**lib/",
            "**deps/",
            "**build/",
            "**dist/",
            "**__snapshots__/",
            "**public/",
            "**.git/",
            "**.next/",
            "**.yarn/",
            "**.tox/",
            "**.mypy_cache/",
            "**.terraform/",
            -- files
            "**plugin/packer_compiled.lua",
            "**yarn.lock",
            "**yarn-error.log",
            "**install_module.log",
            "**algoliasearch.egg-info/",
        },

        -- default arguments with `--hidden` added to search in hidden files
        vimgrep_arguments = {
            "rg",
            "--no-ignore",
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
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
        },
        file_browser = {
            initial_mode = "normal",
            path = "%:p:h",
            hidden = true,
        },
    },
})

require("telescope").load_extension("file_browser")
require("telescope").load_extension("fzf")
