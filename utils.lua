if not SMODS then
    function Palette.get_loc_colour(ctrl, vars)
        if type(ctrl) == 'table' then ctrl = ctrl.c end
        if not ctrl then return end
        if (#ctrl == 6 or #ctrl == 8) and not string.find(ctrl, "%X") then
            if next(loc_colour(ctrl, {})) then
                sendWarnMessage(("Interpreting colour identifier '%s' as a hex code. A named `loc_colour` entry with the same name exists and was ignored"):format(ctrl),"SMODS.get_loc_colour")
            end
            return HEX(ctrl)
        end
        return (vars or {})[tonumber(ctrl) or {}] or loc_colour(ctrl)
    end
    function Palette.merge_defaults(t, defaults)
        if t == false then return false end
        if defaults == false then return false end

        -- Add in the keys from `defaults`, returning a table
        if defaults == nil then return t end
        if t == nil then t = {} end
        for k, v in pairs(defaults) do
            if t[k] == nil then
                t[k] = v
            end
        end
        return t
    end

    local init_localization_ref = init_localization
    function init_localization(...)
        if not G.localization.__overflow_injected then
            local en_loc = require("palette/localization/en-us")
            Palette.table_merge(G.localization, en_loc)
            if G.SETTINGS.language ~= "en-us" then
                local success, current_loc = pcall(function()
                    return require("palette/localization/" .. G.SETTINGS.language)
                end)
                if success and current_loc then
                    Palette.table_merge(G.localization, current_loc)
                end
            end
            G.localization.__overflow_injected = true
        end
        return init_localization_ref(...)
    end
end

Palette.merge_defaults = Palette.merge_defaults or SMODS.merge_defaults
Palette.get_loc_colour = Palette.get_loc_colour or SMODS.get_loc_colour
Palette.localize_box = SMODS and SMODS.localize_box or function(lines, args)
    args.vars = args.vars or {}
    local final_line = {}
    for _, part in ipairs(lines) do
        if part.control.element then
            local elem = (args.vars.elements or {})[tonumber(part.control.element)]
            if elem and elem.is and elem:is(Node) then
                elem = { n=G.UIT.O, config = { object = elem }}
            end
            final_line[#final_line+1] = elem
        end
        local assembled_string = ''
        for _, subpart in ipairs(part.strings) do
            assembled_string = assembled_string..(type(subpart) == 'string' and subpart or format_ui_value(args.vars[tonumber(subpart[1])]) or 'ERROR')
        end

        local thunk = {
            bg_col = Palette.get_loc_colour(part.control.B or part.control.X, args.vars.colours),
            text_col = Palette.get_loc_colour(part.control.V or part.control.C, args.vars.colours),
            underline = Palette.get_loc_colour(part.control.u, args.vars.colours),
            underline_scale = type(part.control.u) == 'table' and part.control.u.s,
            overline = Palette.get_loc_colour(part.control.ov, args.vars.colours),
            overline_scale = type(part.control.ov) == 'table' and part.control.ov.s,
            strikethrough = Palette.get_loc_colour(part.control.st, args.vars.colours),
            strikethrough_scale = type(part.control.st) == 'table' and part.control.st.s,
            text_outline = Palette.get_loc_colour(part.control.O, args.vars.colours),
            text_outline_scale = type(part.control.O) == 'table' and part.control.O.s,
            font = SMODS and SMODS.Fonts[part.control.f] or G.FONTS[tonumber(part.control.f)] or args.font,
            scale_mod = part.control.s and tonumber(part.control.s) or args.scale or 1,
        }
        local desc_scale = (thunk.font or G.LANG.font).DESCSCALE
        if G.F_MOBILE_UI then desc_scale = desc_scale*1.5 end

        local base_config = function(t)
            return Palette.merge_defaults(t, {
                button = part.control.button,
                underline = thunk.underline,
                underline_scale = thunk.underline_scale,
                overline = thunk.overline,
                overline_scale = thunk.overline_scale,
                strikethrough = thunk.strikethrough,
                strikethrough_scale = thunk.strikethrough_scale,
                text_outline = thunk.text_outline,
                text_outline_scale = thunk.text_outline_scale,
                font = thunk.font,
                scale = 0.32*thunk.scale_mod*desc_scale,
                text = assembled_string,
                detailed_tooltip = part.control.T and (
                    G.P_CENTERS[part.control.T]
                    or G.P_TAGS[part.control.T]
                    or {
                        set = part.control.T_set or 'Other',
                        key = part.control.T,
                        vars = part.control.T_vars and parse_tooltip_vars(part.control.T_vars) or {}
                    }
                ) or nil,
            })
        end
        
        if args.type == 'name' then
            local final_name_assembled_string = ''
            for _, part in ipairs(lines) do
                local assembled_string_part = ''
                for _, subpart in ipairs(part.strings) do
                    assembled_string_part = assembled_string_part..(type(subpart) == 'string' and subpart or format_ui_value(format_ui_value(args.vars[tonumber(subpart[1])])) or 'ERROR')
                end
                final_name_assembled_string = final_name_assembled_string..assembled_string_part
            end
            final_line[#final_line+1] = {n=G.UIT.C, config={align = "m", colour = thunk.bg_col, r = 0.05, padding = 0.03, res = 0.15}, nodes={}}
            final_line[#final_line].nodes[1] = {n=G.UIT.O, config=base_config{
                object = DynaText(base_config{
                    string = {assembled_string},
                    colours = {thunk.text_col or args.text_colour or G.C.UI.TEXT_LIGHT},
                    bump = not args.no_bump,
                    silent = not args.no_silent,
                    pop_in = (not args.no_pop_in and (args.pop_in or 0)) or nil,
                    pop_in_rate = (not args.no_pop_in and (args.pop_in_rate or 4)) or nil,
                    maxw = args.maxw or 5,
                    shadow = not args.no_shadow,
                    y_offset = args.y_offset or -0.6,
                    spacing = (not args.no_spacing and math.max(0, 0.32*(17 - #(final_name_assembled_string or assembled_string)))) or nil,
                    scale = (0.55 - 0.004*#(final_name_assembled_string or assembled_string))*thunk.scale_mod*(args.fixed_scale or 1),
                })
            }}
        elseif part.control.E then
            local _float, _silent, _pop_in, _bump, _spacing = nil, true, nil, nil, nil
            local text_effects
            if part.control.E == '1' then
                _float = true; _silent = true; _pop_in = 0
            elseif part.control.E == '2' then
                _bump = true; _spacing = 1
            end
            final_line[#final_line+1] = {n=G.UIT.C, config={align = "m", colour = thunk.bg_col, r = 0.05, padding = 0.03, res = 0.15}, nodes={}}
            final_line[#final_line].nodes[1] = {n=G.UIT.O, config=base_config{
                object = DynaText(base_config{
                    string = {assembled_string},
                    colours = {thunk.text_col or loc_colour()},
                    float = _float,
                    silent = _silent,
                    pop_in = _pop_in,
                    bump = _bump,
                    text_effect = text_effects,
                    spacing = _spacing
                })
            }}
        elseif part.control.X or part.control.B then
            final_line[#final_line+1] = {n=G.UIT.C, config={align = "m", colour = thunk.bg_col, r = 0.05, padding = 0.03, res = 0.15}, nodes={
                {n=G.UIT.T, config=base_config{
                    colour = thunk.text_col or loc_colour(),
                }},
            }}
        else
            final_line[#final_line+1] = {n=G.UIT.T, config=base_config{
                shadow = args.shadow,
                colour = thunk.text_col or args.text_colour or loc_colour(nil, args.default_col),
            }}
        end
    end
    return final_line
end

function Palette.table_merge(target, source, ...)
	assert(type(target) == "table", "Target is not a table")
	local tables_to_merge = { source, ... }
	if #tables_to_merge == 0 then
		return target
	end

	for k, t in ipairs(tables_to_merge) do
		assert(type(t) == "table", string.format("Expected a table as parameter %d", k))
	end

	for i = 1, #tables_to_merge do
		local from = tables_to_merge[i]
		for k, v in pairs(from) do
			if type(v) == "table" then
				target[k] = target[k] or {}
				target[k] = Palette.table_merge(target[k], v)
			else
				target[k] = v
			end
		end
	end

	return target
end

function Palette.generate_tooltip(tooltip)
    local title = tooltip.title or nil
    local text = tooltip.text or {}
    local rows = {}
    if title then
        local r = {
            n = G.UIT.R,
            config = { align = "cm" },
            nodes = {
                {
                    n = G.UIT.C,
                    config = { align = "cm" },
                    nodes = {
                        { n = G.UIT.T, config = { text = title, colour = G.C.UI.TEXT_DARK, scale = 0.4 } } }
                } }
        }
        table.insert(rows, r)
    end
    for i = 1, #text do
        if type(text[i]) == 'table' then
            local r = {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.03 },
                nodes = {
                    { n = G.UIT.T, config = { ref_table = text[i].ref_table, ref_value = text[i].ref_value, colour = G.C.UI.TEXT_DARK, scale = 0.4 } } }
            }
            table.insert(rows, r)
        else
            local r = {
                n = G.UIT.R,
                config = { align = "cm", padding = 0.03 },
                nodes = Palette.localize_box(
                    loc_parse_string(text[i]), { scale = 1 })
            }
            table.insert(rows, r)
        end
    end
    if tooltip.filler then
        table.insert(rows, tooltip.filler.func(tooltip.filler.args))
    end
    local t = {
        n = G.UIT.ROOT,
        config = { align = "cm", padding = 0.05, r = 0.1, colour = G.C.L_BLACK, emboss = 0.01 },
        nodes =
        { { n = G.UIT.C, config = { align = "cm", padding = 0.05, r = 0.1, colour = G.C.WHITE, emboss = 0.01 }, nodes = rows } }
    }
    return t
end

function Palette.generate_colours()
    Palette.colours = {}
    local function add_colours(t, name, gradients)
        for key, val in pairs(t or {}) do
            if type(val) == "table" and (type(val[1]) ~= "number") then
                -- print(name, key, "is a table containing more colours?, recursing...")
                add_colours(val, name .. "." .. key, gradients)
            else
                -- print(name, key, "is a colour, adding...")
                local is_gradient = SMODS and (getmetatable(val) == SMODS.Gradient) or nil
                if type(val) == "table" and ((is_gradient and gradients) or not is_gradient) then
                    table.insert(Palette.colours, { key = tostring(key), colour = val, origin = name })
                end
            end
        end
    end
    add_colours(G.C, "G.C")
    
    add_colours(G.ARGS.LOC_COLOURS, "G.ARGS.LOC_COLOURS")
    if SMODS then
        add_colours(SMODS.Gradients, "SMODS.Gradients", true)
    end
    table.sort(Palette.colours, function(a, b)
        return a.key < b.key
    end)

    local per_row = 5
    local default_size = Palette.screen_size.x * 0.23
    local total_colours = #Palette.colours
    local total_rows = math.ceil(total_colours / per_row)
    local pad = 0.06
    local rows_on_screen = 8
    Palette.scroll_progress = math.max(Palette.scroll_progress, 0)
    Palette.scroll_progress = math.min(Palette.scroll_progress, total_rows - (rows_on_screen + 1))

    local function get_col(row, col)
        return Palette.colours[(row * per_row) + col]
    end

    local function gen_tooltip(col)
        local function rgba_string(rgba)
            return string.format("(%d, %d, %d, %d)", rgba[1] * 255, rgba[2] * 255, rgba[3] * 255, rgba[4] * 255)
        end

        return {
            title = col.key,
            text = {
                "RGBA: " .. rgba_string(col.colour),
                localize("k_palette_path_col") .. col.origin .. "." .. col.key
            }
        }
    end

    local function gen_boxes(row)
        local t = {}
        for i = 1, per_row do
            local col = get_col(row, i)
            if col then
                table.insert(t, {
                    n = G.UIT.B,
                    config = {
                        colour = col.colour,
                        colour_key = col.key,
                        w = default_size / per_row,
                        h = default_size / per_row,
                        r = 0.01,
                        refresh_movement = true,
                        padding = pad,
                        shadow = true,
                        outline_colour = G.C.WHITE,
                        outline = 0.5,
                        palette_tooltip = gen_tooltip(col),
                        copy_path = (col.origin .. "." .. col.key),
                    },
                })
            end
        end
        return t
    end

    local t = {}

    local starting_row = Palette.scroll_progress
    local ending_row = Palette.scroll_progress + rows_on_screen

    for i = starting_row, ending_row do
        table.insert(t, {
            n = G.UIT.R,
            config = { padding = pad },
            nodes = gen_boxes(i),
        })
    end

    return t
end

function Palette.create_UIBox()
    return UIBox {
        definition = { n = G.UIT.ROOT, config = { align = 'cm', r = 0.01, }, nodes = { UIBox_dyn_container(Palette.inner_UIBox()) } },
        config = { align = 'cli', offset = { x = -1, y = G.ROOM.T.h - 2.333 }, instance_type = "POPUP", major = G.ROOM_ATTACH, bond = 'Weak' }
    }
end

function Palette.inner_UIBox()
    return {
        {
            n = G.UIT.C,
            config = { minw = Palette.screen_size.x * 0.25, minh = Palette.screen_size.y * 0.8, align = "cm" },
            nodes = {
                {
                    n = G.UIT.R,
                    config = { align = "cm", padding = 0.05, },
                    nodes = {
                        {
                            n = G.UIT.T,
                            config = { text = localize("k_palette_colours"), scale = 0.6, shadow = true },
                        },
                    },
                },
                {
                    n = G.UIT.R,
                    config = { align = "cm", padding = 0.05, },
                    nodes = {
                        {
                            n = G.UIT.C,
                            config = { r = 0.01, colour = lighten(G.C.BLACK, 0.1), minw = Palette.screen_size.x * 0.24, minh = Palette.screen_size.y * 0.7 },
                            nodes = Palette.generate_colours(),
                        },
                    },
                },

            },
        }
    }
end

function Palette.toggle_ui()
    if G.palettes then
        G.palettes:remove()
        G.palettes = nil
    else
        G.palettes = Palette.create_UIBox()
    end
end

function Palette.pixels_to_unit(value)
    return value / (G.TILESCALE * G.TILESIZE)
end

function Palette.save_config() 
    local serialized = "return { active_palette = \""..Palette.active_palette.key.."\"}"
    love.filesystem.write("config/Palette.lua", serialized)
end