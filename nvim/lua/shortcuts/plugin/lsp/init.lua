-- manager
require("mason").setup()

local LSP_SERVERS = {
    "tsserver",
    "lua_ls",
    "bashls",
    "cssls",
    "dockerls",
    "gopls",
    "dotls",
    "vimls",
    "yamlls",
    "terraformls",
    "jsonls",
    "docker_compose_language_service",
    "pylsp",
}

require("mason-lspconfig").setup({
    ensure_installed = LSP_SERVERS,
})

-- config
local M = require("shortcuts.bind")
local cmp = require("cmp")

cmp.setup({
    snippet = {
        expand = function(args)
            require("luasnip").lsp_expand(args.body)
        end,
    },
    formatting = {},
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        ["<C-u>"] = cmp.mapping.scroll_docs(-4),
        ["<C-d>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<CR>"] = cmp.mapping.confirm({ select = true }),
    }),
    sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "luasnip" },
    }, {
        { name = "buffer" },
    }),
})

-- Use buffer source for `/`.
cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
        { name = "buffer" },
    },
})

-- Use cmdline & path source for ':'.
cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
        { name = "path" },
    }, {
        { name = "cmdline" },
    }),
})

local capabilities =
    require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

local function on_attach()
    M.nnoremap("gd", function()
        vim.lsp.buf.definition()
    end)
    M.nnoremap("K", function()
        vim.lsp.buf.hover()
    end)
    M.nnoremap("<leader>vd", function()
        vim.diagnostic.open_float()
    end)
    M.nnoremap("[d", function()
        vim.diagnostic.goto_next()
    end)
    M.nnoremap("]d", function()
        vim.diagnostic.goto_prev()
    end)
    M.nnoremap("<leader>vca", function()
        vim.lsp.buf.code_action()
    end)
end

local function config(_config)
    return vim.tbl_deep_extend("force", {
        capabilities = capabilities,
        on_attach = on_attach,
    }, _config)
end

local goplsConfig = {
    cmd = { "gopls", "serve" },
    settings = {
        gopls = {
            analyses = {
                unusedparams = true,
            },
            staticcheck = true,
        },
    },
}

local luaServerConfig = {
    settings = {
        Lua = {
            diagnostics = {
                globals = { "vim", "MiniTest" },
            },
        },
    },
}

-- Enable the following language servers
for _, lsp in ipairs(LSP_SERVERS) do
    local serverConfig = {}

    if lsp == "gopls" then
        serverConfig = goplsConfig
    end

    if lsp == "lua_ls" then
        serverConfig = luaServerConfig
    end

    require("lspconfig")[lsp].setup(config(serverConfig))
end

-- signature
require("lsp_signature").setup({
    hint_enable = false,
})
