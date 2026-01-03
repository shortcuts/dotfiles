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
        },
    },
}
