require("no-neck-pain").setup({
    debug = true,
    width = 70,
    autocmds = {
        enableOnVimEnter = true,
        enableOnTabEnter = true,
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
