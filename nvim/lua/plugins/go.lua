return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                gopls = {
                    settings = {
                        gopls = {
                            gofumpt = true,
                            codelenses = {
                                gc_details = false,
                                generate = true,
                                regenerate_cgo = true,
                                run_govulncheck = true,
                                test = true,
                                tidy = true,
                                upgrade_dependency = true,
                                vendor = true,
                            },
                            hints = {
                                assignVariableTypes = false,
                                compositeLiteralFields = false,
                                compositeLiteralTypes = false,
                                constantValues = false,
                                functionTypeParameters = false,
                                parameterNames = false,
                                rangeVariableTypes = false,
                            },
                            analyses = {
                                nilness = true,
                                unusedparams = true,
                                unusedwrite = true,
                                useany = true,
                            },
                            usePlaceholders = true,
                            completeUnimported = true,
                            -- runs the full SA suite before the first diagnostic; flip on if you want the extra lints
                            staticcheck = false,
                            buildFlags = { "-tags=integration" },
                            directoryFilters = {
                                "-.git",
                                "-.direnv",
                                "-.idea",
                                "-.vscode",
                                "-.vscode-test",
                                "-build",
                                "-dist",
                                "-node_modules",
                                "-vendor",
                            },
                            -- treesitter already highlights Go; semantic tokens only add per-edit round trips
                            semanticTokens = false,
                        },
                    },
                },
            },
        },
    },
    {
        "mason-org/mason.nvim",
        opts = { ensure_installed = { "goimports", "gofumpt" } },
    },
}
