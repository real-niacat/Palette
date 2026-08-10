Palette = {}

-- mod heavily inspired by TMJ by cg223

Palette.scroll_progress = 1

function Palette.print(...)
    if Palette.debug then
        print(...)
    end
end

local palette_kp = love.keypressed
function love.keypressed(key, ...)
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
end

local palette_hover = UIElement.hover
function UIElement.hover(self)
    if self.config.palette_tooltip then
        self.config.h_popup = Palette.generate_tooltip(self.config.palette_tooltip)
        self.config.h_popup_config = { align = "tm", offset = { x = 0, y = -0.1 }, parent = self }
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
    uielement_click_hook(self)
end

for i, v in pairs( {
    "palette/utils"
}) do
    require(v)
end

Palette.screen_size = {
    x = Palette.pixels_to_unit(love.graphics.getWidth()),
    y = Palette.pixels_to_unit(love.graphics.getHeight()),
}