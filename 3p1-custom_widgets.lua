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

local function truncate(str, length)
    length = tonumber(length) or 25
    if #str > length then
        return str:sub(1, length - 4) .. " ..."
    else
        return str
    end
end

local function launcher_widget(command, label, icon)
    local widget = wibox.widget.textbox()
    widget:set_markup(string.format(" %s%s ", icon or "", label))
    widget:buttons(gears.table.join(
        awful.button({}, 1, function()
            awful.spawn(command)
        end)
    ))
    return widget
end

-- Ram usage widget
widgets.memwidget = wibox.widget.textbox()
vicious.cache(vicious.widgets.mem)
vicious.register(
    widgets.memwidget,
    vicious.widgets.mem,
    function(_, data)
        local usage = tonumber(data[1]) or 0
        local ram_icon = ""
        if usage >= 80 then
            ram_icon = colored_icon(icons.memory, "#ff0000")
        else
            ram_icon = colored_icon(icons.memory, "#ffffff")
        end
        return string.format(
            " %s %d%%(%s/%s)",
            ram_icon,
            usage,
            fix(data[2], 2),
            fix(data[3], 2))
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
        local cpu_icon = ""
        if usage >= 80 then
            cpu_icon = colored_icon(icons.cpu, "#ff0000")
        else
            cpu_icon = colored_icon(icons.cpu, "#ffffff")
        end
        return string.format(" %s%d%%", cpu_icon, usage)
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
        local battery_icon = ""
        local battery_level = tonumber(data[2]) or 0
        if data[1] ~= "-" then
            battery_icon = colored_icon(icons.battery_charging, "#00ff00")
        elseif battery_level >= 80 then
            battery_icon = colored_icon(icons.battery_full, "#00ff00")
        elseif battery_level >= 60 then
            battery_icon = colored_icon(icons.battery_3p4, "#00ff00")
        elseif battery_level >= 40 then
            battery_icon = colored_icon(icons.battery_half, "#ffff00")
        elseif battery_level >= 20 then
            battery_icon = colored_icon(icons.battery_1p4, "#ffff00")
        else
            battery_icon = colored_icon(icons.battery_empty, "#ff0000")
        end
        return string.format(" %s%d%%", battery_icon, battery_level)
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
        local up_icon = colored_icon(icons.net_up, "#00ff00")
        local down_icon = colored_icon(icons.net_down, "#ff0000")
        return string.format(
            " %s %s/s|%s %s/s",
            up_icon,
            fix(data["{wlan0 up_b}"], 0),
            down_icon,
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
        local disk_icon = ""
        if usage >= 80 then
            disk_icon = colored_icon(icons.disk, "#ff0000")
        else
            disk_icon = colored_icon(icons.disk, "#ffffff")
        end
        return string.format(
            " %s %s%%(%s)",
            disk_icon,
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
        local volume_icon = ""
        local muted = data[2] == "🔈" or data[1] == 0
        local volume = muted and "Mute" or data[1] .. "%"
        if muted then
            volume_icon = colored_icon(icons.volume_mute, "#ff0000")
        elseif data[1] > 50 then
            volume_icon = colored_icon(icons.volume_high, "#00ff00")
        else
            volume_icon = colored_icon(icons.volume_low, "#00ff00")
        end
        return string.format(" %s%s", volume_icon, volume)
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
        local brightness_icon = ""
        if brightness and tonumber(brightness:match("%d+")) then
            if tonumber(brightness:match("%d+")) >= 50 then
                brightness_icon = colored_icon(icons.brightness_high, "#ffff00")
            else
                brightness_icon = colored_icon(icons.brightness_low, "#ffffff")
            end
            widget:set_markup(string.format(" %s%s", brightness_icon, brightness))
        end
    end,
    wibox.widget.textbox()
)

-- Clock widget
widgets.clockwidget = wibox.widget.textclock(
    string.format(
        " %s%s",
        colored_icon(icons.clock, "#ff0000"),
        "%a %d %b, %H:%M:%S "
    ),
    1
)

-- Music widget
widgets.musicwidget = awful.widget.watch(
    "playerctl metadata --player=spotify --format '{{ status }}|{{ volume }}|{{ artist }} - {{ title }}'",
    0.05,
    function(widget, stdout)
        local music_info = stdout:gsub("\n", "")
        local status, raw_volume, track_info = music_info:match("^(.-)|(.-)|(.*)$")
        local music_icon = ""
        local music_text = ""
        if status == "Playing" then
            music_icon = colored_icon(icons.playing, "#00ff00")
            music_text = string.format("%s %.0f%%", truncate(track_info), tonumber(raw_volume) * 100)
        elseif status == "Paused" then
            music_icon = colored_icon(icons.paused, "#ffff00")
            music_text = string.format("%s %.0f%%", truncate(track_info), tonumber(raw_volume) * 100)
        else
            music_icon = colored_icon(icons.music, "#ff0000")
            music_text = "No music playing"
        end
        widget:set_markup(string.format(" %s%s ", music_icon, music_text))
    end,
    wibox.widget.textbox()
)

-- Clipboard widget
widgets.clipwidget = awful.widget.watch(
    "xclip -o -selection clipboard",
    1,
    function(widget, stdout)
        local clipboard_content = stdout:gsub("\n", "")
        local clipboard_icon = ""
        if clipboard_content == "" then
            clipboard_icon = colored_icon(icons.clipboard, "#ffffff")
            clipboard_content = "Clipboard empty"
        else
            clipboard_icon = colored_icon(icons.clipboard, "#ffff00")
            clipboard_content = truncate(clipboard_content)
        end
        widget:set_markup(string.format(" %s%s", clipboard_icon, clipboard_content))
    end,
    wibox.widget.textbox()
)

-- Focusing widget
local focus_icon = wibox.widget.imagebox()
local focus_text = wibox.widget.textbox()
widgets.focuswidget = wibox.layout.fixed.horizontal()
widgets.focuswidget:add(focus_icon)
widgets.focuswidget:add(focus_text)

local function update_focus_widget()
    local focused = client.focus
    if not focused then
        focus_icon.visible = false
        focus_text:set_markup("")
        return
    end
    local client_title = focused.name
    focus_icon:set_image(focused.icon and focused.icon or " • ")
    focus_icon.visible = focused.icon ~= nil
    focus_text:set_markup(string.format(
        " %s ",
        gears.string.xml_escape(client_title)
    ))
end

client.connect_signal("focus", update_focus_widget)
client.connect_signal("unfocus", update_focus_widget)
client.connect_signal("property::name", update_focus_widget)
update_focus_widget()

return widgets

-- file:///home/nqvietz/.config/awesome/3-wibar.lua

-- Remaining: notification widget.
-- Add the popup widget for each widget.