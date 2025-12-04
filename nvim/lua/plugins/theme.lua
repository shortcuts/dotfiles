return {
    {
        "EdenEast/nightfox.nvim",
        priority = 1000,
        lazy = false,
        config = function()
            local carbonfox = require("nightfox.palette.carbonfox")
            require("nightfox").setup({
                options = {
                    transparent = true,
                },
                palettes = {
                    duskfox = {
                        bg0 = carbonfox.palette.bg0,
                        bg1 = "#030100",
                        bg2 = carbonfox.palette.bg2,
                        bg3 = carbonfox.palette.bg3,
                        bg4 = carbonfox.palette.bg4,
                    },
                },
            })
            vim.cmd("colorscheme duskfox")

            -- Transparent support
            for _, hl_group in pairs({
                "NormalFloat",
                "StatusLine",
                "StatusLineNC",
                "Tabline",
                "TabLineFill",
                "TabLineSel",
                "Winbar",
                "WinbarNC",
                "BufferTabpageFill",
                "FzfLuaBorder",
                "TreesitterContext",
                "BufferCurrentADDED",
                "BufferCurrentCHANGED",
                "BufferCurrentDELETED",
                "BufferCurrentERROR",
                "BufferCurrentHINT",
                "BufferCurrentIcon",
                "BufferCurrentIndex",
                "BufferCurrentINFO",
                "BufferCurrentMod",
                "BufferCurrentNumber",
                "BufferCurrentSign",
                "BufferCurrentSignRight",
                "BufferCurrentTarget",
                "BufferCurrentWARN",
                "BufferInactive",
                "BufferInactiveADDED",
                "BufferInactiveCHANGED",
                "BufferInactiveDELETED",
                "BufferInactiveERROR",
                "BufferInactiveHINT",
                "BufferInactiveIcon",
                "BufferInactiveIndex",
                "BufferInactiveINFO",
                "BufferInactiveMod",
                "BufferInactiveNumber",
                "BufferInactiveSign",
                "BufferInactiveSignRight",
                "BufferInactiveTarget",
                "BufferInactiveWARN",
                "TreesitterContext",
            }) do
                vim.api.nvim_set_hl(0, hl_group, { bg = "none" })
            end

            -- Accent support
            local accent = "#e08543"
            vim.api.nvim_set_hl(0, "FloatBorder", { fg = accent })
            vim.api.nvim_set_hl(0, "FzfLuaBorder", { fg = accent })
            vim.api.nvim_set_hl(0, "TreesitterContextLineNumber", { fg = accent })
            vim.api.nvim_set_hl(0, "BufferCurrent", { bg = "none", fg = accent })
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
