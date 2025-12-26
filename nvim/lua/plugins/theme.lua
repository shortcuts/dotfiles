return {
    {
        "Shatur/neovim-ayu",
        priority = 1000,
        lazy = false,
        config = function()
            require("ayu").setup({
                dark = true,
                terminal = true,
            })
            vim.cmd("colorscheme ayu")
        end,
    },
    {
        "nvim-lualine/lualine.nvim",
        lazy = false,
        dependencies = { "nvim-tree/nvim-web-devicons", event = "VeryLazy" },
        opts = {
            options = {
                icons_enabled = true,
                theme = {
                    normal = {
                        a = { bg = "NONE" },
                        b = { bg = "NONE" },
                        c = { bg = "NONE" },
                        z = { bg = "NONE" },
                    },
                    insert = {
                        a = { bg = "NONE" },
                        b = { bg = "NONE" },
                        c = { bg = "NONE" },
                        z = { bg = "NONE" },
                    },
                    visual = {
                        a = { bg = "NONE" },
                        b = { bg = "NONE" },
                        c = { bg = "NONE" },
                        z = { bg = "NONE" },
                    },
                    replace = {
                        a = { bg = "NONE" },
                        b = { bg = "NONE" },
                        c = { bg = "NONE" },
                        z = { bg = "NONE" },
                    },
                    command = {
                        a = { bg = "NONE" },
                        b = { bg = "NONE" },
                        c = { bg = "NONE" },
                        z = { bg = "NONE" },
                    },
                    inactive = {
                        a = { bg = "NONE" },
                        b = { bg = "NONE" },
                        c = { bg = "NONE" },
                        z = { bg = "NONE" },
                    },
                },
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
                lualine_z = { require("opencode").statusline },
            },
            inactive_sections = {},
        },
    },
    {
        "romgrk/barbar.nvim",
        priority = 1000,
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
