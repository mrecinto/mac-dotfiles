return {
    "neovim/nvim-lspconfig",

    event = {
        "BufReadPre",
        "BufNewFile",
    },

    config = function()
        -- =================================================
        -- SHARED KEYMAPS
        -- =================================================

        local on_attach = function(_, bufnr)
            local map = function(lhs, rhs)
                vim.keymap.set("n", lhs, rhs, {
                    buffer = bufnr,
                    silent = true,
                })
            end

            map("gd", vim.lsp.buf.definition)
            map("K", vim.lsp.buf.hover)

            map("<leader>rn", vim.lsp.buf.rename)
            map("<leader>ca", vim.lsp.buf.code_action)

            map("<leader>e", vim.diagnostic.open_float)
            map("[d", vim.diagnostic.goto_prev)
            map("]d", vim.diagnostic.goto_next)
            map("<leader>q", vim.diagnostic.setloclist)
        end


        -- =================================================
        -- LUA
        -- =================================================

        vim.lsp.config("lua_ls", {
            on_attach = on_attach,
        })


        -- =================================================
        -- C / C++
        -- =================================================

        vim.lsp.config("clangd", {
            cmd = { "clangd" },
            filetypes = {
                "c",
                "cpp",
                "objc",
                "objcpp",
            },

            on_attach = on_attach,
        })


        -- =================================================
        -- TYPST
        -- =================================================

        vim.lsp.config("tinymist", {
            cmd = { "tinymist" },
            filetypes = { "typst" },

            on_attach = on_attach,

            settings = {
                formatterMode = "typstyle",
                exportPdf = "never",
            },
        })


        -- =================================================
        -- ENABLE LSP SERVERS
        -- =================================================

        vim.lsp.enable({
            "lua_ls",
            "clangd",
            "tinymist",
        })
    end,
}
