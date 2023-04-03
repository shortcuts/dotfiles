require("no-neck-pain").setup({
    -- debug = true,
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
        left = {
            bo = {
                filetype = "md",
            },
            scratchPad = {
                enabled = false,
                fileName = "notes",
                location = "~/",
            },
        },
        right = {
            enabled = false,
        },
    },
})
