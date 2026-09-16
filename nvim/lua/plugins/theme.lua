return {
    {
        "projekt0n/github-nvim-theme",
        name = "github-theme",
        lazy = false, -- make sure we load this during startup if it is your main colorscheme
        priority = 1000, -- make sure to load this before all the other plugins
        opts = {
            options = {
                -- italics blur at this font size and add nothing on a TUI read all day
                styles = {
                    comments = "NONE",
                    functions = "NONE",
                    keywords = "NONE",
                    variables = "NONE",
                    conditionals = "NONE",
                    constants = "NONE",
                    numbers = "NONE",
                    operators = "NONE",
                    strings = "NONE",
                    types = "NONE",
                },
            },
        },
        config = function(_, opts)
            require("github-theme").setup(opts)
            vim.cmd("colorscheme github_dark_dimmed")

            -- orange marks the active thing, matching tmux's accent
            vim.api.nvim_set_hl(0, "BufferCurrentSign", { fg = "#e0823d", bg = "#636e7b" })
            vim.api.nvim_set_hl(0, "CursorLineNr", { fg = "#e0823d", bold = true })
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons", event = "VeryLazy" },
        opts = {
            options = {
                icons_enabled = true,
                theme = "github_dark_dimmed",
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                always_divide_middle = true,
                globalstatus = true,
                refresh = {
                    statusline = 5000,
                    tabline = 5000,
                    winbar = 5000,
                },
            },
            sections = {
                lualine_a = { { "filename", path = 1 }, "diff" },
                lualine_b = {},
                lualine_c = {},
                lualine_x = { "branch" },
                lualine_y = { "diagnostics" },
                lualine_z = {},
            },
            inactive_sections = {},
        },
    },
    {
        "romgrk/barbar.nvim",
        lazy = false,
        dependencies = "nvim-tree/nvim-web-devicons",
        init = function()
            vim.g.barbar_auto_setup = false
        end,
        opts = {
            animation = false,
            auto_hide = false,
            tabpages = true,
            clickable = false,
            icons = {
                filetype = { enabled = true },
                button = "",
                modified = {
                    button = "●",
                },
                inactive = {
                    separator = {
                        left = "▎",
                    },
                },
                separator = {
                    left = "▎",
                },
            },
            icon_custom_colors = false,
            maximum_padding = 1,
            maximum_length = 30,
            semantic_letters = true,
            letters = "asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP",
            no_name_title = nil,
        },
    },
}
