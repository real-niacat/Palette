Palette = {
    loaded_colours = {},
    config = {active_palette = "pal_base_game"}
}
-- mod heavily inspired by TMJ by cg223

Palette.scroll_progress = 1
Palette.nativefs = SMODS and SMODS.NFS or require("nativefs")
if not SMODS then
    local lovely = require("lovely")

    local info = Palette.nativefs.getDirectoryItemsInfo(lovely.mod_dir)
    local palette_path = ""
    for i, v in pairs(info) do
    if v.type == "directory" and Palette.nativefs.getInfo(lovely.mod_dir .. "/" .. v.name .. "/palette.lua") then palette_path = lovely.mod_dir .. "/" .. v.name end
    end

    if not Palette.nativefs.getInfo(palette_path) then
        error(
            'Could not find proper Palette folder.\nPlease make sure that Palette is installed correctly and the folders arent nested.')
    end
    Palette.path = palette_path
end


function Palette.print(...)
    if Palette.debug then
        print(...)
    end
end

local palette_kp = love.keypressed
function love.keypressed(key, ...)
    if key == "escape" and G.palettes then
        Palette.toggle_ui()
        return
    end
    palette_kp(key, ...)
    if key == "p" then
        Palette.toggle_ui()
    end
end

local love_resize_hook = love.resize
function love.resize(w, h)
    love_resize_hook(w, h)
    Palette.screen_size = {
        x = Palette.pixels_to_unit(w),
        y = Palette.pixels_to_unit(h),
    }
end

local palette_sv = UIElement.set_values
function UIElement.set_values(self, t, recalculate)
    palette_sv(self, t, recalculate)
    if self.config.palette_tooltip then
        self.states.collide.can = true
    end

    if self.config.copy_path then
        self.states.click.can = true
    end
    if self.config.palette_callback then
        self.states.click.can = true
    end
end

local palette_hover = UIElement.hover
function UIElement.hover(self)
    if self.config.palette_tooltip then
        self.config.h_popup = Palette.generate_tooltip(self.config.palette_tooltip)
        self.config.h_popup_config = { align = self.config.palette_tooltip.align or "tm", offset = { x = 0, y = -0.1 }, parent = self }
    end
    palette_hover(self)
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
    if self.config.palette_callback then
        self:juice_up()
        self.config:palette_callback(self)
    end
    uielement_click_hook(self)
end

for i, v in pairs( {
    "palette/utils",
    "palette/trance/core",
    "palette/trance/ui"
}) do
    require(v)
end

Palette.screen_size = {
    x = Palette.pixels_to_unit(love.graphics.getWidth()),
    y = Palette.pixels_to_unit(love.graphics.getHeight()),
}

function Palette.load_config() 
    if love.filesystem.exists("config/Palette.lua") then
    local str = ""
    for line in love.filesystem.lines("config/Palette.lua") do
        str = str..line
    end
        return loadstring(str)()
    else    
        return {
            active_palette = "pal_base_game"
        }
    end
end
Palette.load_config()
if not SMODS then
    Palette.load_palettes()
end
