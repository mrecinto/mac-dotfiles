return {
    {
        "chomosuke/typst-preview.nvim",

        ft = "typst",

        opts = {
            -- Open Typst Preview in Zen Browser
            open_cmd = "open -a 'Zen' %s",
        },

        config = function(_, opts)
            require("typst-preview").setup(opts)

            -- =================================================
            -- TYPST KEYBINDS
            -- =================================================

            vim.api.nvim_create_autocmd("FileType", {
                pattern = "typst",

                callback = function(args)

                    -- -------------------------------------------------
                    -- Format
                    -- Space + f
                    -- -------------------------------------------------

                    vim.keymap.set("n", "<leader>f", function()
                        vim.lsp.buf.format({
                            async = true,
                        })
                    end, {
                        buffer = args.buf,
                        desc = "Format Typst",
                    })


                    -- =================================================
                    -- TYPST PREVIEW
                    --
                    -- Space + t + p
                    -- Opens in Zen Browser
                    -- =================================================

                    vim.keymap.set("n", "<leader>tp", function()
                        vim.cmd("TypstPreviewToggle")
                    end, {
                        buffer = args.buf,
                        desc = "Toggle Typst Preview",
                    })


                    -- =================================================
                    -- ZATHURA LIVE PREVIEW
                    --
                    -- Space + t + o
                    -- =================================================

                    vim.keymap.set("n", "<leader>to", function()

                        vim.cmd("write")

                        local file = vim.fn.expand("%:p")

                        vim.fn.jobstart({
                            vim.fn.expand(
                                "~/.config/nvim/scripts/typst-zathura.sh"
                            ),
                            file,
                        }, {
                            detach = true,
                        })

                    end, {
                        buffer = args.buf,
                        desc = "Toggle Typst Zathura Preview",
                    })
                end,
            })
        end,
    },
}
