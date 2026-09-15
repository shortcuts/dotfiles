return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                pyright = {},
                ruff = {
                    cmd_env = { RUFF_TRACE = "messages" },
                    init_options = {
                        settings = {
                            logLevel = "error",
                        },
                    },
                },
            },
        },
    },
}
