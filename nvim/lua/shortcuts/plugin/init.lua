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
require("mini.test").setup()
require("mini.doc").setup()
vim.opt.rtp:append(os.getenv("HOME") .. "/Documents/no-neck-pain.nvim")

-- NNP
require("no-neck-pain").setup({
    debug = true,
    width = 80,
    enableOnVimEnter = true,
    toggleMapping = "<Leader>kz",
    buffers = {
        backgroundColor = "github-nvim-theme-dimmed",
        blend = -0.1,
        scratchPad = {
            enabled = true,
        },
        right = {
            enabled = false,
        },
    },
})
