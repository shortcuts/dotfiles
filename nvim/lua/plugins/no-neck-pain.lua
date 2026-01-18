return {
    {
        "shortcuts/no-neck-pain.nvim",
        lazy = false,
        dev = true,
        opts = {
            debug = true,
            width = 80,
            minSideBufferWidth = 0,
            autocmds = {
                enableOnTabEnter = true,
                enableOnVimEnter = true,
                reloadOnColorSchemeChange = true,
                skipEnteringNoNeckPainBuffer = true,
            },
            mappings = {
                enabled = true,
                toggle = "<Leader>kz",
                debug = "<Leader>kd",
            },
            buffers = {
                left = {
                    scratchPad = {
                        enabled = false,
                        pathToFile = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/notes/nnp.md",
                    },
                },
                right = {
                    enabled = false,
                },
            },
            integrations = {
                snacks = { position = "left" },
            }
        },
    },
-- {
--   "folke/snacks.nvim",
--         lazy = false,
--   opts = {
--     explorer = {
--             replace_netrw = true,
--       -- your explorer configuration comes here
--       -- or leave it empty to use the default settings
--       -- refer to the configuration section below
--     },
--     picker = {
--       sources = {
--         explorer = {
--           -- your explorer picker configuration comes here
--           -- or leave it empty to use the default settings
--         }
--       }
--     }
--   }
-- }
}
