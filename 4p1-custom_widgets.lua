local awful = require("awful")
local vicious = require("vicious")
local wibox = require("wibox")
local icons = require("4p2-custom_icons") -- file:///home/nqvietz/.config/awesome/4p2-custom_icons.lua

local widgets = {}

local function fix(usage, unit_level)
    usage = tonumber(usage) or 0
    local units = {"B", "K", "M", "G", "T", "P", "E", "Z", "Y"}
    while(usage >= 1024 and unit_level < #units) do
        usage = usage / 1024
        unit_level = unit_level + 1
    end
    return string.format("%.1f%s", usage, units[unit_level + 1])
end

-- Ram usage widget
widgets.memwidget = wibox.widget.textbox()
vicious.cache(vicious.widgets.mem)
vicious.register(
    widgets.memwidget,
    vicious.widgets.mem,
    function(_, data)
        return string.format(
            " %s %d%%(%s/%s)",
            icons.memory,
            data[1],
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
    " " .. icons.cpu .. "$1%",
    1
)

-- Battery widget
widgets.batwidget = wibox.widget.textbox()
vicious.register(
    widgets.batwidget,
    vicious.widgets.bat,
    " " .. icons.battery .. "$2%",
    10,
    "BAT0"
)

-- Network usage widget
widgets.netwidget = wibox.widget.textbox()
vicious.register(
    widgets.netwidget,
    vicious.widgets.net,
    function(_, data)
        return string.format(
            " %s %s/s | %s %s/s",
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
        return string.format(
            " %s %s%%(%s)",
            icons.disk,
            data["{/ used_p}"],
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
        local volume = data[1]
        local status = data[2]
        if status == "🔈" or status == "♩" or status == "off" then
            return " " .. icons.volume .. "Mute"
        else
            return " " .. icons.volume .. volume .. "%"
        end
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
            widget:set_text(" " .. icons.bright .. brightness)
        end
    end,
    wibox.widget.textbox()
)

-- Clock widget
widgets.clockwidget = wibox.widget.textclock(" " .. icons.clock .. "%a %b %d, %H:%M:%S  ", 1)

-- Music widget (using playerctl)
widgets.musicwidget = awful.widget.watch(
    "playerctl metadata --format '{{ artist }} - {{ title }}'",
    1,
    function(widget, stdout)
        local music_info = stdout:gsub("\n", "")
        if music_info == "" then
            widget:set_text(" " .. icons.music .. " No music playing ")
        else
            widget:set_text(" " .. icons.music .. " " ..music_info .. " ")
        end
    end,
    wibox.widget.textbox()
)

return widgets, icons