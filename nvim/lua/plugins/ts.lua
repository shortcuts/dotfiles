return {
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                ts_ls = {
                    settings = {
                        typescript = {
                            updateImportsOnFileMove = { enabled = "always" },
                            suggest = { completeFunctionCalls = true },
                            inlayHints = {
                                enumMemberValues = { enabled = true },
                                functionLikeReturnTypes = { enabled = true },
                                parameterNames = { enabled = "literals" },
                                parameterTypes = { enabled = true },
                                propertyDeclarationTypes = { enabled = true },
                                variableTypes = { enabled = false },
                            },
                        },
                    },
                },
            },
        },
    },
}
