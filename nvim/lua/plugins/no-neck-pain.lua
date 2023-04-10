return {
    {
        "shortcuts/no-neck-pain.nvim",
        lazy = false,
        dev = true,
        opts = {
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
        },
    },
}
