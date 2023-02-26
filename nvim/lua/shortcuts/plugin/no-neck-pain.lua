require("no-neck-pain").setup({
    debug = true,
    width = 70,
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
