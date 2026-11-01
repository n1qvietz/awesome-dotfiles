local theme_assets = require("beautiful.theme_assets")
local xresources = require("beautiful.xresources")
local rnotification = require("ruled").notification
local dpi = xresources.apply_dpi
local themes_path = require("gears.filesystem").get_themes_dir()

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

    if width * height == 0 or type(pixels) ~= "string" then
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

-- local init_color, average_red, average_green, average_blue = "#99b1d9"

if type(init_color) == "string" then
    average_red, average_green, average_blue = string.match(
        init_color,
        "#(%x%x)(%x%x)(%x%x)"
    )
    average_red = tonumber(average_red, 16)
    average_green = tonumber(average_green, 16)
    average_blue = tonumber(average_blue, 16)
else
    average_red, average_green, average_blue = wallpaper_average()
end

theme.average_color = function(multiplier)
    multiplier = multiplier or 1.0
    local function channel(value)
        return math.min(255, math.floor(value * multiplier + 0.5))
    end

    return string.format(
        "#%02x%02x%02x",
        channel(average_red),
        channel(average_green),
        channel(average_blue)
    )
end

theme.font          = "Maple Mono NF CN 8"

theme.bg_normal     = theme.average_color(0.5) or "#222222"
theme.bg_focus      = theme.average_color() or "#535d6c"
theme.bg_urgent     = theme.average_color() or "#ff0000"
theme.bg_minimize   = theme.bg_normal or "#444444"
theme.bg_systray    = theme.bg_normal
theme.hotkeys_bg    = theme.bg_normal or "#535d6c"

theme.contrast_color = function(target_color)
    target_color = target_color or theme.average_color()
    local avg_red, avg_green, avg_blue = string.match(
        target_color,
        "#(%x%x)(%x%x)(%x%x)"
    )
    avg_red = tonumber(avg_red, 16)
    avg_green = tonumber(avg_green, 16)
    avg_blue = tonumber(avg_blue, 16)
    local avg_color = math.floor(255.5 - (avg_red + avg_green + avg_blue) / 3)
    return string.format("#%02x%02x%02x", avg_color, avg_color, avg_color)
end

theme.fg_normal     = theme.contrast_color(theme.bg_normal) or "#aaaaaa"
theme.fg_focus      = theme.contrast_color(theme.bg_focus) or "#ffffff"
theme.fg_urgent     = theme.contrast_color(theme.bg_urgent) or "#ffffff"
theme.fg_minimize   = theme.contrast_color(theme.bg_minimize) or "#ffffff"
theme.hotkeys_modifiers_fg = theme.fg_focus

theme.useless_gap   = dpi(2)
theme.border_width  = dpi(2)
theme.border_normal = theme.bg_normal or "#000000"
theme.border_focus  = theme.bg_focus or "#535d6c"
theme.border_marked = theme.average_color() or "#91231c"

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

-- Set different colors for urgent notifications.
rnotification.connect_signal('request::rules', function()
    rnotification.append_rule {
        rule       = { urgency = 'critical' },
        properties = { bg = '#ff0000', fg = '#ffffff' }
    }
end)

return theme

-- vim: filetype=lua:expandtab:shiftwidth=4:tabstop=8:softtabstop=4:textwidth=80
