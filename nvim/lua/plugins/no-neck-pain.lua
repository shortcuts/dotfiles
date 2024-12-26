return {
    {
        "shortcuts/no-neck-pain.nvim",
        lazy = false,
        dev = true,
        opts = {
            -- debug = true,
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
