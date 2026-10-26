local awful = require("awful")
local gears = require("gears")
local naughty = require("naughty")
local vicious = require("vicious")
local wibox = require("wibox")
local beautiful = require("beautiful")
local icons = require("3p2-custom_icons") -- file:///home/nqvietz/.config/awesome/3p2-custom_icons.lua

local widgets = {}

local function fix(usage, unit_level)
    usage = tonumber(usage) or 0
    local units = { "B", "K", "M", "G", "T", "P", "E", "Z", "Y" }
    while(usage >= 1024 and unit_level < #units) do
        usage = usage / 1024
        unit_level = unit_level + 1
    end
    return string.format("%.1f%s", usage, units[unit_level + 1])
end

local function colored_icon(icon, color)
    return string.format('<span foreground="%s">%s</span>', color, icon)
end

-- Ram usage widget
widgets.memwidget = wibox.widget.textbox()
vicious.cache(vicious.widgets.mem)
vicious.register(
    widgets.memwidget,
    vicious.widgets.mem,
    function(_, data)
        local usage = tonumber(data[1]) or 0
        local icon_color = usage >= 80 and "#ff0000" or beautiful.fg_normal
        return string.format(
            " %s %d%%(%s/%s)",
            colored_icon(icons.memory, icon_color),
            usage,
            fix(data[2], 2),
            fix(data[3], 2)
        )
    end,
    1
)

-- CPU usage widget
widgets.cpuwidget = wibox.widget.textbox()
vicious.register(
    widgets.cpuwidget,
    vicious.widgets.cpu,
    function(_, data)
        local usage = tonumber(data[1]) or 0
        local icon_color = usage >= 80 and "#ff0000" or beautiful.fg_normal
        return string.format(
            " %s%d%%",
            colored_icon(icons.cpu, icon_color),
            usage
        )
    end,
    1
)

-- Battery widget
widgets.batwidget = wibox.widget.textbox()
widgets.batwidget:set_font(icon_font)
vicious.register(
    widgets.batwidget,
    vicious.widgets.bat,
    function(_, data)
        local battery_icon = icons.battery_empty
        local battery_level = tonumber(data[2]) or 0
        local icon_color = battery_level < 20 and "#ff0000" or beautiful.fg_normal
        if data[1] ~= "-" then
            battery_icon = icons.battery_charging
            battery_icon = colored_icon(battery_icon, "#00ff00")
        elseif battery_level >= 80 then
            battery_icon = icons.battery_full
        elseif battery_level >= 60 then
            battery_icon = icons.battery_3p4
        elseif battery_level >= 40 then
            battery_icon = icons.battery_half
        elseif battery_level >= 20 then
            battery_icon = icons.battery_1p4
        end
        return " " .. colored_icon(battery_icon, icon_color) .. battery_level .. "%"
    end,
    1,
    "BAT0"
)

-- Network usage widget
widgets.netwidget = wibox.widget.textbox()
vicious.register(
    widgets.netwidget,
    vicious.widgets.net,
    function(_, data)
        return string.format(
            " %s %s/s|%s %s/s",
            icons.net_up,
            fix(data["{wlan0 up_b}"], 0),
            icons.net_down,
            fix(data["{wlan0 down_b}"], 0)
        )
    end,
    1
)

-- Disk usage widget
widgets.diskwidget = wibox.widget.textbox()
vicious.register(
    widgets.diskwidget,
    vicious.widgets.fs,
    function(_, data)
        local usage = tonumber(data["{/ used_p}"]) or 0
        local icon_color = usage >= 80 and "#ff0000" or beautiful.fg_normal
        return string.format(
            " %s %s%%(%s)",
            colored_icon(icons.disk, icon_color),
            usage,
            fix(data["{/ avail_mb}"], 2)
        )
    end,
    1
)

-- Volume widget
widgets.volwidget = wibox.widget.textbox()
vicious.register(
    widgets.volwidget,
    vicious.widgets.volume,
    function(_, data)
        local volume_icon = icons.volume_mute
        if data[2] == "🔈" then
            return " " .. volume_icon .. "Mute"
        elseif data[1] > 50 then
            volume_icon = icons.volume_high
        elseif data[1] > 0 then
            volume_icon = icons.volume_low
        end
        return " " .. volume_icon .. data[1] .. "%"
    end,
    0.05,
    "Master"
)

-- Brightness widget
widgets.brightwidget = awful.widget.watch(
    "brightnessctl -m",
    0.05,
    function(widget, stdout)
        local brightness = stdout:match("^[^,]*,[^,]*,[^,]*,([^,]+)")
        if brightness then
            local brightness_value = tonumber(brightness:match("%d+"))
            local brightness_icon = brightness_value and brightness_value >= 50 and
                                    icons.brightness_high or icons.brightness_low
            widget:set_text(" " .. brightness_icon .. brightness)
        end
    end,
    wibox.widget.textbox()
)

-- Clock widget
widgets.clockwidget = wibox.widget.textclock(" " .. icons.clock .. "%a %d %b, %H:%M:%S ", 1)

-- Music widget
widgets.musicwidget = awful.widget.watch(
    "playerctl metadata --format '{{ status }}{{ artist }} - {{ title }}'",
    0.05,
    function(widget, stdout)
        local music_info = stdout:gsub("\n", "")
        if music_info:sub(1, 7) == "Playing" then
            widget:set_text(" " .. icons.playing .. music_info:sub(7 + 1, 7 + 25) .. " ")
        elseif music_info:sub(1, 6) == "Paused" then
            widget:set_text(" " .. icons.paused .. music_info:sub(6 + 1, 6 + 25) .. " ")
        else
            widget:set_text(" " .. icons.music .. "No music playing ")
        end
    end,
    wibox.widget.textbox()
)

-- Clipboard widget
widgets.clipwidget = awful.widget.watch(
    "xclip -o -selection clipboard",
    1,
    function(widget, stdout)
        local clipboard_content = stdout:gsub("\n", "")
        if clipboard_content == "" then
            widget:set_text(" " .. icons.clipboard .. "Clipboard empty")
        else
            widget:set_text(" " .. icons.clipboard .. clipboard_content:sub(1, 25))
        end
    end,
    wibox.widget.textbox()
)

return widgets

-- file:///home/nqvietz/.config/awesome/3-wibar.lua

-- Remaining: notification widget.
-- Next, convert wibar to wibox instead.
-- Final, add the popup icons for each widgets.