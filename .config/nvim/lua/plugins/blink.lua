return {
    "saghen/blink.cmp",
    version = "*",

    dependencies = {
        "L3MON4D3/LuaSnip",
        "rafamadriz/friendly-snippets",
    },

    opts = {
        -- =================================================
        -- LUASNIP
        -- =================================================
        snippets = {
            preset = "luasnip",
        },

        -- =================================================
        -- KEYMAPS
        -- =================================================
        keymap = {
            preset = "default",

            -- Accept completion
            ["<M-y>"] = { "accept", "fallback" },

            -- Navigate completion menu
            ["<Tab>"] = { "select_next", "fallback" },
            ["<S-Tab>"] = { "select_prev", "fallback" },

            -- Manually trigger completion
            ["<C-Space>"] = { "show" },
        },

        -- =================================================
        -- APPEARANCE
        -- =================================================
        appearance = {
            use_nvim_cmp_as_default = false,
        },

        -- =================================================
        -- SOURCES
        -- =================================================
        sources = {
            providers = {
                lsp = {
                    name = "lsp",
                },

                buffer = {
                    name = "buffer",
                },

                snippets = {
                    name = "snippets",
                },
            },

            per_filetype = {
                typst = {
                    "lsp",
                    "snippets",
                    "buffer",
                },

                markdown = {
                    "snippets",
                    "buffer",
                },

                markdown_inline = {
                    "snippets",
                    "buffer",
                },
            },

            default = {
                "lsp",
                "snippets",
                "buffer",
            },
        },

        -- =================================================
        -- COMMAND LINE COMPLETION
        -- =================================================
        cmdline = {
            sources = {
                "cmdline",
                "path",
            },
        },
    },
}
