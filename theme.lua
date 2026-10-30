local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local dpi = xresources.apply_dpi

local gfs = require("gears.filesystem")
local themes_path = gfs.get_themes_dir()

local theme = {}

theme.wallpaper = os.getenv("HOME") .. "/Pictures/Wallpapers/_.png"

local function wallpaper_average()
    local pixbuf, err = require("lgi").GdkPixbuf.Pixbuf.new_from_file(theme.wallpaper)

    if not pixbuf then
        return nil, err or ("Unable to load wallpaper: " .. theme.wallpaper)
    end

    local width = pixbuf:get_width()
    local height = pixbuf:get_height()
    local channels = pixbuf:get_n_channels()
    local rowstride = pixbuf:get_rowstride()
    local pixels = pixbuf:get_pixels()

    if width * height == 0 or not pixels then
        return nil, "Wallpaper contains no pixels: " .. theme.wallpaper
    end

    local red, green, blue = 0, 0, 0

    for y = 0, height - 1 do
        local row = y * rowstride
        for x = 0, width - 1 do
            local pixel = row + x * channels
            red = red + string.byte(pixels, pixel + 1)
            green = green + string.byte(pixels, pixel + 2)
            blue = blue + string.byte(pixels, pixel + 3)
        end
    end

    local pixel_count = width * height
    return red / pixel_count, green / pixel_count, blue / pixel_count
end

-- Calculate the average color of the wallpaper
local average_red, average_green, average_blue = wallpaper_average()

theme.average_color = function(multiplier)
    if not average_red then
        return nil
    end

    multiplier = multiplier or 1.0
    return string.format(
        "#%02x%02x%02x",
        math.floor(average_red * multiplier + 0.5),
        math.floor(average_green * multiplier + 0.5),
        math.floor(average_blue * multiplier + 0.5)
    )
end

theme.font          = "Maple Mono NF CN 8"

theme.bg_normal     = theme.average_color(0.5) or "#222222"
theme.bg_focus      = theme.average_color(1.2) or "#535d6c"
theme.bg_urgent     = theme.average_color(1.2) or "#ff0000"
theme.bg_minimize   = theme.bg_normal or "#444444"
theme.bg_systray    = theme.bg_normal
theme.hotkeys_bg    = theme.average_color(0.5) or "#535d6c"

theme.fg_normal     = "#aaaaaa"
theme.fg_focus      = "#ffffff"
theme.fg_urgent     = "#ffffff"
theme.fg_minimize   = "#ffffff"
theme.hotkeys_modifiers_fg = theme.fg_focus

theme.useless_gap   = dpi(2)
theme.border_width  = dpi(2)
theme.border_normal = theme.average_color(0.8) or "#000000"
theme.border_focus  = theme.bg_focus or "#535d6c"
theme.border_marked = theme.average_color(1.2) or "#91231c"

-- There are other variable sets
-- overriding the default one when
-- defined, the sets are:
-- taglist_[bg|fg]_[focus|urgent|occupied|empty|volatile]
-- tasklist_[bg|fg]_[focus|urgent]
-- titlebar_[bg|fg]_[normal|focus]
-- tooltip_[font|opacity|fg_color|bg_color|border_width|border_color]
-- mouse_finder_[color|timeout|animate_timeout|radius|factor]
-- prompt_[fg|bg|fg_cursor|bg_cursor|font]
-- hotkeys_[bg|fg|border_width|border_color|shape|opacity|modifiers_fg|label_bg|label_fg|group_margin|font|description_font]
-- Example:
-- theme.taglist_bg_focus = "#ff0000"

-- Generate taglist squares:
local taglist_square_size = dpi(4)
theme.taglist_squares_sel = theme_assets.taglist_squares_sel(
    taglist_square_size, theme.fg_normal
)
theme.taglist_squares_unsel = theme_assets.taglist_squares_unsel(
    taglist_square_size, theme.fg_normal
)

-- Variables set for theming notifications:
-- notification_font
-- notification_[bg|fg]
-- notification_[width|height|margin]
-- notification_[border_color|border_width|shape|opacity]

-- Variables set for theming the menu:
-- menu_[bg|fg]_[normal|focus]
-- menu_[border_color|border_width]
theme.menu_submenu_icon = themes_path.."default/submenu.png"
theme.menu_height = dpi(15)
theme.menu_width  = dpi(100)

-- You can add as many variables as
-- you wish and access them by using
-- beautiful.variable in your rc.lua
-- theme.bg_widget = "#cc0000"

-- Generate Awesome icon:
theme.awesome_icon = theme_assets.awesome_icon(
    theme.menu_height, theme.bg_focus, theme.fg_focus
)

-- Define the icon theme for application icons. If not set then the icons
-- from /usr/share/icons and /usr/share/icons/hicolor will be used.
theme.icon_theme = nil

return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
