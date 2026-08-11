function _G.create_UIBox_colours_selection()
    -- Malverk:update_atlas()
    -- Malverk.texture_pack_priority_area = CardArea(G.ROOM.T.w, G.ROOM.T.h, 11, G.CARD_H, 
    -- {type = 'joker', highlight_limit = 1, deck_height = 0.75, thin_draw = 1, texture_priority = true})
    -- Malverk.texture_pack_priority_area.ARGS.invisible_area_types = {joker=1}
    -- for _, texture_pack in ipairs(Malverk.config.selected) do
    --     if TexturePacks[texture_pack] then
    --         local card = create_texture_card(Malverk.texture_pack_priority_area, texture_pack)
    --         card.params.texture_priority = true
    --         Malverk.texture_pack_priority_area:emplace(card)
    --     end
    -- end
    local default_size = Palette.screen_size.x * 0.23 
    local per_row = 5
    Palette.generate_colours()
    local col = Palette.active_palette

    local function get_operator_node(scale, col)
        local t = "X"
        if SMODS then
            if SMODS.Scoring_Calculations[G.GAME.current_scoring_calculation_key] then
                t = type(SMODS.Scoring_Calculations[G.GAME.current_scoring_calculation_key].text) == "function" and SMODS.Scoring_Calculations[G.GAME.current_scoring_calculation_key]:text()
                    or SMODS.Scoring_Calculations[G.GAME.current_scoring_calculation_key].text or "X"
            end
        end
        return
        {n=G.UIT.C, config={align = "cm", id = 'hand_operator_container'}, nodes={
            {n=G.UIT.T, config={text = t, lang = G.LANGUAGES['en-us'], scale = scale*1.5, colour = col, shadow = true}},
        }}
    end

    local function gen_tooltip(col, align)
        local loc = Palette.get_palette_loc(col.key)
        return {
            align = align,
            title = loc and loc.name or col.key,
            text = loc and loc.text or "",
            filler = {
                func = function()
                    local scale = 0.15
		            local s_scale = scale/0.2
                    local mult = col.colours.MULT or col.colours.UI_MULT or col.colours.RED
                    local chips= col.colours.CHIPS or col.colours.UI_CHIPS or col.colours.BLUE
                    local badge = col:add_badge()
                    local black = col.colours.BLACK or Palette.ColourPalettes.pal_base_game.colours.BLACK
                    return {n=G.UIT.R, config={align = "m", padding = 0.05}, nodes={
                        {n=G.UIT.C, config={align = "cm", padding = 0.05}, nodes={
                            {n=G.UIT.R, config={align = "cm", padding = 0.05, colour = black, r = 0.05, minw = 2*s_scale, minh = 0.75*s_scale}, nodes={
                                {n=G.UIT.C, config={align = "cr", padding = 0.05, colour = chips,r = 0.05, minw = 1*s_scale, minh = 0.5*s_scale}, nodes={
                                    {n=G.UIT.O, config={align = "cr", text = "chips_text", type = type, scale =scale*2.3, object = DynaText({
                                        string = {{ref_table = {chips = 20}, ref_value = "chips"}},
                                        colours = {G.C.UI.TEXT_LIGHT}, font = G.LANGUAGES['en-us'].font, shadow = true, float = true, scale = scale*2.3
                                    })}},
                                    {n=G.UIT.B, config={w = 0.1, h = 0.1}},
                                }},
                                get_operator_node(0.2, mult),
                                {n=G.UIT.C, config={align = "cr", padding = 0.05, colour = mult, r = 0.05, minw = 1*s_scale, minh = 0.5*s_scale}, nodes={
                                    {n=G.UIT.O, config={text = "mult_text", type = type, scale =scale*2.3, object = DynaText({
                                        string = {{ref_table = {chips = 20}, ref_value = "chips"}},
                                        colours = {G.C.UI.TEXT_LIGHT}, font = G.LANGUAGES['en-us'].font, shadow = true, float = true, scale = scale*2.3
                                    })}},
                                    {n=G.UIT.B, config={w = 0.1, h = 0.1}},
                                }}
                            }},
                            {n=G.UIT.R, config={align = "cm", minh = 0.025*s_scale}, nodes={
                            }},
                            badge,
                        }}
                    }}
                end
            }
        }
    end
    local colors = {}
    local p = {}
    for i, v in pairs(Palette.ColourPalettes) do
        p[#p+1] = v
    end
    table.sort(p, function(a, b)
        return a.order < b.order
    end)
    for i, v in pairs(p) do
        if v.key ~= Palette.active_palette.key then
            colors[#colors] = colors[#colors] or {n=G.UIT.R, config = {align = 'lm', padding = 0.1}, nodes ={}}
            local row = colors[#colors]
            local col = v
            if #row.nodes > 7 then
                colors[#colors+1] = colors[#colors+1] or {n=G.UIT.R, config = {align = 'lm', padding = 0.1}, nodes ={}}
                row = colors[#colors]
            end
            row.nodes[#row.nodes+1] = {n=G.UIT.C, config = {align = 'cm', padding = 0.1}, nodes = {
                {
                    n = G.UIT.B,
                    config = {
                        colour = col.main_colour,
                        colour_key = col.key,
                        w = default_size / per_row,
                        h = default_size / per_row,
                        r = 0.01,
                        refresh_movement = true,
                        padding = 0.1,
                        shadow = true,
                        outline_colour = G.C.WHITE,
                        outline = 0.5,
                        palette_tooltip = gen_tooltip(col, "bm"),
                        palette_callback = function()
                            Palette.load_palette(col.key)
                            G.FUNCS.exit_overlay_menu()
                            G.FUNCS.overlay_menu {
                                definition = create_UIBox_colours_selection()
                            }
                        end
                    },
                }
            }}
        end
    end
    local t = create_UIBox_generic_options({ back_func = 'options', contents = {
        {n=G.UIT.R, config = {colour = G.C.CLEAR, align = 'cm', minw = 12, minh = 10}, nodes = {
            {n=G.UIT.C, config={align = "cm", padding = 0.15, r = 0.1, minw = 12}, nodes={
                {n=G.UIT.R, config = {colour = G.C.BLACK, r = 0.1, minh = 2.5, minw = 12, align = 'cm'}, nodes = {
                    {n=G.UIT.C, config = {align = 'cm', padding = 0.1, minw = 0.5}, nodes = {{n=G.UIT.T, config = {text = localize('palette_enabled'), scale = 0.5, vert = true, colour = G.C.L_BLACK}}}},
                    {n=G.UIT.C, config = {align = 'cm', minw = 11}, nodes = {
                         {
                            n = G.UIT.B,
                            config = {
                                colour = col.main_colour,
                                colour_key = col.key,
                                w = default_size / per_row,
                                h = default_size / per_row,
                                r = 0.01,
                                refresh_movement = true,
                                padding = pad,
                                shadow = true,
                                outline_colour = G.C.WHITE,
                                outline = 0.5,
                                palette_tooltip = gen_tooltip(col, "bm"),
                                palette_callback = function()
                                    if col.key ~= "pal_base_game" then
                                        Palette.load_palette("pal_base_game")
                                        G.FUNCS.exit_overlay_menu()
                                        G.FUNCS.overlay_menu {
                                            definition = create_UIBox_colours_selection()
                                        }
                                    end
                                end
                            },
                        }
                    }},
                }},
                {n=G.UIT.R, config = {colour = G.C.BLACK, r = 0.1, minh = 7.5, minw = 12, align = 'tm'}, nodes = colors},
            }},
        }}
    }})
    return t

end