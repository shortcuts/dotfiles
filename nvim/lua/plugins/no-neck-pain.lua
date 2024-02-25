return {
    {
        "shortcuts/no-neck-pain.nvim",
        lazy = false,
        dev = true,
        opts = {
            debug = true,
            width = 80,
            minSideBufferWidth = 0,
            fallbackOnBufferDelete = true,
            autocmds = {
                enableOnVimEnter = true,
                enableOnTabEnter = true,
                reloadOnColorSchemeChange = true,
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
