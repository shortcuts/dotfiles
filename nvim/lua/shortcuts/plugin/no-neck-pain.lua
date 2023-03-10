require("no-neck-pain").setup({
    debug = true,
    width = 60,
    autocmds = {
        enableOnVimEnter = true,
        enableOnTabEnter = true,
        enableScratchPadOnBufEnter = true,
    },
    mappings = {
        enabled = true,
        toggle = "<Leader>kz",
    },
    buffers = {
        colors = {
            blend = -0.1,
        },
        scratchPad = {
            enabled = false,
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
