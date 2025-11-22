return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
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
    {
        "neovim/nvim-lspconfig",
        opts = function(_, opts)
            local servers = { "pyright", "ruff" }
            for _, server in ipairs(servers) do
                opts.servers[server] = opts.servers[server] or {}
                opts.servers[server].enabled = server == "pyright" or server == "ruff"
            end
        end,
    },
    {
        "hrsh7th/nvim-cmp",
        optional = true,
        opts = function(_, opts)
            opts.auto_brackets = opts.auto_brackets or {}
            table.insert(opts.auto_brackets, "python")
        end,
    },
}
