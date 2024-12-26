return {
    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
    },
    {
        "nvim-telescope/telescope.nvim",
        cmd = { "Telescope" },
        version = false,
        lazy = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope-fzf-native.nvim",
        },
        config = function()
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
                            preview_cutoff = 0,
                            preview_height = 0.69,
                            results_height = 0.2,
                            width = 0.8,
                            height = 0.99,
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
                        "**deps/",
                        "**dist/",
                        "**vendor/",
                        "**nightly/",
                        "**__snapshots__/",
                        "**.pytest_cache/",
                        "**__pycache__/",
                        "**public/",
                        "**.git/",
                        "**.docusaurus/",
                        "**\\.ci/",
                        "**.nx/",
                        "**.build/",
                        "**website/build/",
                        "**bin/",
                        "**.next/",
                        "**.yarn/",
                        "list/",
                        "**.tox/",
                        "**.mypy_cache/",
                        "**build/terraform/\\.terraform/",
                        "**plugin/packer_compiled.lua",
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
                },
            })

            require("telescope").load_extension("fzf")

            vim.keymap.set(
                "n",
                "<Leader>fg",
                "<cmd>lua require'telescope.builtin'.live_grep{ search_dirs={\"%:p:h\"} }<CR>"
            ) -- open find in file
            vim.keymap.set("n", "<Leader>gfg", "<cmd>Telescope live_grep<CR>") -- open find in file
            vim.keymap.set("n", "<Leader>fr", "<cmd>Telescope lsp_references<CR>") -- open find for references
            vim.keymap.set("n", "<Leader>fh", "<cmd>Telescope help_tags<CR>") -- open help
            vim.keymap.set("n", "<Leader>ff", "<cmd>Telescope find_files<CR>") -- open find file
        end,
    },
}
