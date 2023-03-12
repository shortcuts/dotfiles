-- treesitter default config
require("nvim-treesitter.configs").setup({
    ensure_installed = "all",
    -- Install parsers synchronously (only applied to `ensure_installed`)
    sync_install = false,
    -- Automatically install missing parsers when entering buffer
    auto_install = true,
    highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
    },
})

-- context wrapper
require("treesitter-context").setup({
    enable = true, -- Enable this plugin (Can be enabled/disabled later via commands)
    max_lines = 0, -- How many lines the window should span. Values <= 0 mean no limit.
    trim_scope = "outer", -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
    patterns = { -- Match patterns for TS nodes. These get wrapped to match at word boundaries.
        default = {
            "class",
            "function",
            "method",
            "if",
            "switch",
            "for",
            "while",
            "case",
        },
    },
    -- [!] The options below are exposed but shouldn't require your attention,
    --     you can safely ignore them.
    zindex = 20, -- The Z-index of the context window
    mode = "cursor", -- Line used to calculate context. Choices: 'cursor', 'topline'
    separator = "~", -- Separator between context and content. Should be a single character string, like '-'.
})
