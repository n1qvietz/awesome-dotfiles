local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local widgets = require("3p1-custom_widgets")      -- file:///home/nqvietz/.config/awesome/3p1-custom_widgets.lua
local icons = require("3p2-custom_icons")          -- file:///home/nqvietz/.config/awesome/3p2-custom_icons.lua

-- {{{ Wallpaper
screen.connect_signal("request::wallpaper", function(s)
    awful.wallpaper {
        screen = s,
        widget = {
            {
                image     = beautiful.wallpaper,
                upscale   = true,
                downscale = true,
                widget    = wibox.widget.imagebox,
            },
            valign = "center",
            halign = "center",
            tiled  = false,
            widget = wibox.container.tile,
        }
    }
end)
-- }}}

-- {{{ Wibar
screen.connect_signal("request::desktop_decoration", function(s)
    -- Padding for the wibar to avoid overlapping with the window borders
    s.padding = { top = 2, right = 2, bottom = 2, left = 2 }

    -- Each screen has its own tag table.
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" }, s, awful.layout.suit.fair)

    -- Create a taglist widget
    s.mytaglist = awful.widget.taglist {
        screen  = s,
        filter  = awful.widget.taglist.filter.all,
        buttons = {
            awful.button({ }, 1, function(t) t:view_only() end),
            awful.button({ modkey }, 1, function(t)
                                            if client.focus then
                                                client.focus:move_to_tag(t)
                                            end
                                        end),
            awful.button({ }, 3, awful.tag.viewtoggle),
            awful.button({ modkey }, 3, function(t)
                                            if client.focus then
                                                client.focus:toggle_tag(t)
                                            end
                                        end),
            awful.button({ }, 4, function(t) awful.tag.viewprev(t.screen) end),
            awful.button({ }, 5, function(t) awful.tag.viewnext(t.screen) end),
        }
    }

    -- Create the wibox
    s.mywibox = awful.wibar {
        position = "top",
        screen   = s,
        widget   = {
            layout = wibox.layout.align.horizontal,
            { -- Left widgets
                layout = wibox.layout.fixed.horizontal,
                s.mytaglist,
                -- widgets.average_color,
                widgets.clipwidget,
                widgets.musicwidget,
                widgets.taskwidget(s),
                widgets.focuswidget,
            },
            wibox.widget.textbox(), -- Middle space
            { -- Right widgets
                layout = wibox.layout.fixed.horizontal,
                wibox.widget.systray(),
                widgets.cpuwidget,
                widgets.memwidget,
                widgets.netwidget,
                widgets.diskwidget,
                widgets.btwidget,
                widgets.voicewidget,
                widgets.volwidget,
                widgets.brightwidget,
                widgets.batwidget,
                widgets.clockwidget,
            }
        }
    }
end)
-- }}}