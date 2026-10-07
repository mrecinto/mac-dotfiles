return {
    {
        "nvim-treesitter/nvim-treesitter",
        lazy = false,
        build = ":TSUpdate",

        config = function()
            local ts = require("nvim-treesitter")

            -- Install parsers we want
            ts.install({
                "lua",
                "vim",
                "vimdoc",
                "markdown",
                "markdown_inline",
                "typst",
            })

            -- Enable Treesitter automatically
            vim.api.nvim_create_autocmd("FileType", {
                pattern = {
                    "lua",
                    "vim",
                    "markdown",
                    "typst",
                },

                callback = function()
                    vim.treesitter.start()
                end,
            })
        end,
    },
}
