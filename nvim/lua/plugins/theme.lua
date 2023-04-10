return {
    {
        "EdenEast/nightfox.nvim",
        priority = 1000,
        lazy = false,
        config = function()
            require("nightfox").setup({
                transparent = true,
            })
            vim.cmd("colorscheme carbonfox")
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons", event = "VeryLazy" },
        opts = {
            options = {
                icons_enabled = true,
                theme = "auto",
                component_separators = { left = "", right = "" },
                section_separators = { left = "", right = "" },
                always_divide_middle = true,
                globalstatus = true,
                refresh = {
                    statusline = 5000,
                    tabline = 5000,
                    winbar = 5000,
                },
            },
            sections = {
                lualine_a = { "mode" },
                lualine_b = { "branch", "diff", "diagnostics" },
                lualine_c = {
                    {
                        "filename",
                        path = 1,
                    },
                },
                lualine_x = { "fileformat", "filetype" },
                lualine_y = {},
                lualine_z = { "location" },
            },
            inactive_sections = {
                lualine_x = { "location" },
            },
        },
    },
    {
        "romgrk/barbar.nvim",
        event = "VeryLazy",
        dependencies = "nvim-tree/nvim-web-devicons",
        init = function()
            vim.g.barbar_auto_setup = false
        end,
        opts = {
            animation = false,
            auto_hide = false,
            tabpages = true,
            clickable = false,
            -- Excludes buffers from the tabline
            exclude_ft = {},
            exclude_name = {},
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
            -- Sets the maximum padding width with which to surround each tab
            maximum_padding = 1,
            -- Sets the maximum buffer name length.
            maximum_length = 30,
            semantic_letters = true,
            letters = "asdfjkl;ghnmxcvbziowerutyqpASDFJKLGHNMXCVBZIOWERUTYQP",
            no_name_title = nil,
        },
    },
}
