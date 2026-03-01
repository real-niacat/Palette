---@type Mod
Palette = SMODS.current_mod

-- mod heavily inspired by TMJ by cg223
-- mod code too was inspired


Palette.screen_size = {
    x = SMODS.pixels_to_unit(love.graphics.getWidth()),
    y = SMODS.pixels_to_unit(love.graphics.getHeight()),
}

Palette.scroll_progress = 1

function Palette.print(...)
    if Palette.debug then
        print(...)
    end
end

SMODS.Keybind {
    key = "palette_toggle_ui",
    key_pressed = "p",
    action = function(self)
        Palette.toggle_ui()
    end
}

function Palette.toggle_ui()
    if G.palettes then
        G.palettes:remove()
        G.palettes = nil
    else
        G.palettes = Palette.create_UIBox()
    end
end

local love_resize_hook = love.resize
function love.resize(w, h)
    love_resize_hook(w, h)
    Palette.screen_size = {
        x = SMODS.pixels_to_unit(w),
        y = SMODS.pixels_to_unit(h),
    }
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
                            config = { text = "Colours", scale = 0.6, shadow = true },
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

function Palette.generate_colours()
    Palette.colours = {}
    local function add_colours(t, name)
        for key, val in pairs(t) do
            if type(val) == "table" and (type(val[1]) ~= "number") then
                -- print(name, key, "is a table containing more colours?, recursing...")
                add_colours(val, name .. "." .. key)
            else
                -- print(name, key, "is a colour, adding...")
                if type(val) ~= "number" then
                    table.insert(Palette.colours, { key = tostring(key), colour = val, origin = name })
                end
            end
        end
    end
    add_colours(G.C, "G.C")
    add_colours(SMODS.Gradients, "SMODS.Gradients")
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
                "Path: " .. col.origin .. "." .. col.key
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

local set_values_hook = UIElement.set_values
function UIElement.set_values(self, t, recalculate)
    set_values_hook(self, t, recalculate)
    if self.config.palette_tooltip then
        self.states.collide.can = true
    end

    if self.config.copy_path then
        self.states.click.can = true
    end
end

local hover_hook = UIElement.hover
function UIElement.hover(self)
    if self.config.palette_tooltip then
        self.config.h_popup = Palette.generate_tooltip(self.config.palette_tooltip)
        self.config.h_popup_config = { align = "tm", offset = { x = 0, y = -0.1 }, parent = self }
    end
    hover_hook(self)
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
                nodes = SMODS.localize_box(
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

local ourref = love.wheelmoved or function() end
function love.wheelmoved(x, y)
    ourref(x, y)
    if y and G.palettes then
        Palette.scroll_progress = Palette.scroll_progress - y
        Palette.toggle_ui()
        Palette.toggle_ui()
    end
end

local uielement_click_hook = UIElement.click
function UIElement.click(self)
    if self.config.copy_path then
        love.system.setClipboardText(self.config.copy_path)
        self:juice_up()
    end
    uielement_click_hook(self)
end

SMODS.Atlas {
    key = "modicon",
    path = "palettetag.png",
    px = 34,
    py = 34,
}