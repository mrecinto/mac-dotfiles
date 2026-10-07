return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },

        config = function()
            require("neo-tree").setup({
                filesystem = {
                    follow_current_file = {
                        enabled = true,
                    },
                },

                window = {
                    position = "float",
                },
            })

            -- Ctrl + E toggles floating file explorer
-- vim.keymap.set("n", "<D-;>", "<cmd>Neotree toggle float<CR>", {
--     desc = "Toggle Neo-tree",
-- })
vim.keymap.set("n", "\\", "<cmd>Neotree toggle float<CR>", {
desc = "Toggle Neo-tree",
})

-- Previous / next buffer
vim.keymap.set("n", "<C-h>", "<cmd>BufferLineCyclePrev<CR>")
vim.keymap.set("n", "<C-l>", "<cmd>BufferLineCycleNext<CR>")

-- Jump to buffer 1-9
for i = 1, 9 do
    vim.keymap.set("n", "<C-" .. i .. ">", "<cmd>BufferLineGoToBuffer " .. i .. "<CR>")
end
        end,
    },
    vim.keymap.set("n", "<C-w>", "<cmd>bdelete<CR>", {
    desc = "Close current buffer",
})
}
