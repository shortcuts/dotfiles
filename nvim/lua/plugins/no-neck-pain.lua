return {
    {
        "shortcuts/no-neck-pain.nvim",
        lazy = false,
        dev = true,
        opts = {
            debug = false,
            width = 90,
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
                        pathToFile = "~/notes.md",
                    },
                },
                right = {
                    enabled = false,
                },
            },
        },
    },
}
