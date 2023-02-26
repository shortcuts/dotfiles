--------------------------
--     Plugin setup
--------------------------
require("shortcuts.plugin.barbar")
require("shortcuts.plugin.lsp")
require("shortcuts.plugin.nvim-autopairs")
require("shortcuts.plugin.theme")
require("shortcuts.plugin.treesitter")
require("shortcuts.plugin.telescope")

-- dev
-- require("mini.test").setup()
-- require("mini.doc").setup()
-- vim.opt.rtp:append(os.getenv("HOME") .. "/Documents/no-neck-pain.nvim")

-- NNP
require("no-neck-pain").setup({
    -- debug = true,
    width = 80,
    enableOnVimEnter = true,
    enableOnTabEnter = true,
    toggleMapping = "<Leader>kz",
    buffers = {
        blend = -0.1,
        scratchPad = {
            enabled = true,
            fileName = "notes",
            location = "~/",
        },
        bo = {
            filetype = "md",
        },
        right = {
            enabled = false,
        },
    },
})
