require("nvchad.configs.lspconfig").defaults()

local servers = { "nixd", "lua_ls", "bashls", "pylsp" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
