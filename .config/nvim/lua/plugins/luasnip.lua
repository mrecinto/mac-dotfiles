return {
    "L3MON4D3/LuaSnip",

    config = function()
        local ls = require("luasnip")
        local s = ls.snippet
        local t = ls.text_node
        local i = ls.insert_node

        -- Enable autosnippets
        ls.config.set_config({
            enable_autosnippets = true,
        })

        -- =================================================
        -- TYPST AUTOSNIPPETS
        -- =================================================

        ls.add_snippets("typst", {

            -- mk -> $|$
            s(
                {
                    trig = "mk",
                    snippetType = "autosnippet",
                },
                {
                    t("$"),
                    i(1),
                    t("$"),
                }
            ),

            -- dm ->
            -- $
            -- |
            -- $
            s(
                {
                    trig = "dm",
                    snippetType = "autosnippet",
                },
                {
                    t({ "$", "" }),
                    i(1),
                    t({ "", "$" }),
                }
            ),

        })
    end,
}
