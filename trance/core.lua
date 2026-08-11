Palette.ColourPalettes = {}
Palette.ColourPalette = function(args)
    Palette.ColourPalettesOrder = Palette.ColourPalettesOrder or 0
    --TODO: other stuff

    local required_params = {
        "key", "colours"
    }
    args.mod = SMODS and SMODS.current_mod or Palette.mod or {prefix = "pal"}
    args.key = args.mod.prefix.."_"..args.key
    if not Palette.ColourPalettes[args.key] then
        args.order = args.key == "pal_base_game" and -9999 or Palette.ColourPalettesOrder
        Palette.ColourPalettesOrder = Palette.ColourPalettesOrder + 1
        args.colours = args.colors or args.colours
        args.main_colour = args.main_colour or args.colours.MULT
        args.set = "ColourPalette"
        for i, v in pairs(required_params) do
            assert(not (args[v] == nil), ('Missing required parameter for %s declaration: %s'):format("ColourPalette", v))
        end

        Palette.ColourPalettes[args.key] = args
    end
end


function Palette.load_file(primary_path)
    local f = Palette.nativefs.read(primary_path)
    local success, result = pcall(function() return assert(load(f))() end)
    if success then
        return result
    end
end

function Palette.load_file_with_fallback(primary_path, fallback_path, reset_config)
    local result = Palette.load_file(primary_path)
    if reset_config then
        reset_config()
    end
    if not result then
        result = Palette.load_file(fallback_path)
    end
    return result
end

function Palette.load_palettes()
    local info = Palette.nativefs.getDirectoryItemsInfo(Palette.path .. "colours")
    for i, v in pairs(info) do
        local res = Palette.load_file(Palette.path .. "colours/"..v.name)
        if res then
            res = {
                key = (string.lower(v.name):gsub(" ", "_")),
                colours = res,
                loc_txt = {
                    name = v.name:gsub(".lua", ""),
                    text = {
                        "???"
                    }
                }
            }
            Palette.ColourPalette(res)
        end
    end
end

function Palette.get_palette_loc(key)
    if Palette.ColourPalettes.loc_txt then
        return Palette.ColourPalettes.loc_txt
    end
    return G.localization.descriptions.ColorPalette[key]
end

function Palette.post_load()
    Palette.active_palette = Palette.ColourPalettes[Palette.config.active_palette]
end

local function is_color(v)
    return type(v) == 'table' and #v == 4 and type(v[1]) == "number" and type(v[2]) == "number" and type(v[3]) == "number" and type(v[4]) == "number"
end

function Palette.load_colour_table(c, t, d)
    t = t or Palette.loaded_colours
    d = d or Palette.ColourPalettes.pal_base_game.colours
    for k, v in pairs(c or {}) do
        if is_color(v) then
            d[k] = d[k] or copy_table(v)
            t[k] = v
        elseif type(v) == 'table' then
            t[k] = t[k] or {}
            d[k] = d[k] or {}
            Palette.load_colour_table(v, t[k], d[k])
        end
    end
end

function Palette.load_palette(key)
    Palette.loaded_colours = {}
    Palette.load_colour_table(Palette.ColourPalettes.pal_base_game.colours)
    Palette.load_colour_table(Palette.ColourPalettes[key].colours)
    Palette.active_palette = Palette.ColourPalettes[key]
    Palette.set_globals()
end

function Palette.set_colors(v, t)
    v = v or Palette.loaded_colours
    t = t or G.C
    for k, v in pairs(v) do
        if is_color(v) then 
            if is_color(G.C[k]) then ease_colour(G.C[k],v,dt) else G.C[k] = v end
        elseif type(v) == 'table' then
            G.C[k] = G.C[k] or {}
            Palette.set_colors(v, G.C[k])
        end
    end
end

function Palette.set_globals()
    Palette.set_colors()
    if Palette.loaded_colours.MULT then ease_colour(G.C.UI_MULT,Palette.loaded_colours.MULT) end
    if Palette.loaded_colours.CHIPS then ease_colour(G.C.UI_CHIPS,Palette.loaded_colours.CHIPS) end
    if Palette.active_palette.colours.SPLASH then
        G.C.SPLASH = copy_table(Palette.active_palette.colours.SPLASH)
    else
        G.C.SPLASH = {Palette.active_palette.colours.RED or Palette.active_palette.colours.MULT or Palette.loaded_colours.RED, Palette.active_palette.colours.BLUE or Palette.active_palette.colours.CHIPS or Palette.loaded_colours.RED}
    end
    if G.SPLASH_BACK then
        G.SPLASH_BACK:define_draw_steps({{
            shader = 'splash',
            send = {
                {name = 'time', ref_table = G.TIMERS, ref_value = 'REAL_SHADER'},
                {name = 'vort_speed', val = 0.4},
                {name = 'colour_1', ref_table = G.C.SPLASH, ref_value = 1},
                {name = 'colour_2', ref_table = G.C.SPLASH, ref_value = 2},
            }
        }})
    end
    if G.P_BLINDS then
        for k, v in pairs(Palette.loaded_colours.BOSSES or {}) do
            if G.P_BLINDS[k] and G.P_BLINDS[k].boss_colour then G.P_BLINDS[k].boss_colour = v end
        end
    end
end