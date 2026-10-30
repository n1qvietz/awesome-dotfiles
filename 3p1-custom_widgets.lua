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

-- Bluetooth widget
widgets.btwidget = awful.widget.watch(
    "bluetoothctl show",
    0.05,
    function(widget, stdout)
        local bt_icon = ""
        if stdout:match("Powered: yes") then
            bt_icon = colored_icon(icons.bluetooth, "#0082fc")
        else
            bt_icon = colored_icon(icons.bluetooth, "#ffffff")
        end
        widget:set_markup(string.format(" %s", bt_icon))
    end,
    wibox.widget.textbox()
)

widgets.btwidget:buttons(gears.table.join(
    awful.button({ }, 1, function()
        awful.spawn.easy_async(
            "bluetoothctl show",
            function(stdout, stderr, _, exit_code)
                if exit_code ~= 0 then
                    naughty.notify({
                        title = "Bluetooth",
                        text = stderr ~= "" and stderr
                            or "Unable to read Bluetooth state",
                    })
                    return
                end

                awful.spawn.easy_async(
                    stdout:match("Powered: yes")
                        and "bluetoothctl power off"
                        or "bluetoothctl power on",
                    function(_, command_stderr, _, command_exit_code)
                        if command_exit_code ~= 0 then
                            naughty.notify({
                                title = "Bluetooth",
                                text = command_stderr ~= ""
                                    and command_stderr
                                    or "Unable to change Bluetooth power state",
                            })
                        end
                    end
                )
            end
        )
    end)
))

-- Battery widget
widgets.batwidget = wibox.widget.textbox()
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
        local clipboard_content = stdout:gsub("%s+", " "):match("^%s*(.-)%s*$")
        local clipboard_icon = ""
        if clipboard_content == "" then
            clipboard_icon = colored_icon(icons.clipboard, "#ffffff")
            clipboard_content = "Clipboard empty"
        else
            clipboard_icon = colored_icon(icons.clipboard, "#ffff00")
            clipboard_content = gears.string.xml_escape(truncate(clipboard_content))
        end
        widget:set_markup(string.format(" %s%s", clipboard_icon, clipboard_content))
    end,
    wibox.widget.textbox()
)

-- Voice widget
widgets.voicewidget = awful.widget.watch(
    "amixer get Capture",
    0.05,
    function(widget, stdout)
        local voice_icon = ""
        if stdout:match("%[off%]") then
            voice_icon = colored_icon(icons.voice_mute, "#ff0000")
        else
            voice_icon = colored_icon(icons.voice, "#00ff00")
        end
        widget:set_markup(string.format(" %s", voice_icon))
    end,
    wibox.widget.textbox()
)

-- Tasklist widget
function widgets.taskwidget(screen)
    return awful.widget.tasklist {
        screen = screen,
        filter = awful.widget.tasklist.filter.currenttags,
        buttons = {
            awful.button({ }, 1, function (c)
                c:activate { context = "tasklist", action = "toggle_minimization" }
            end),
            awful.button({ }, 3, function() awful.menu.client_list { theme = { width = 250 } } end),
            awful.button({ }, 4, function() awful.client.focus.byidx(-1) end),
            awful.button({ }, 5, function() awful.client.focus.byidx( 1) end),
        },
        widget_template = { { { {
            id = "icon_role", widget = wibox.widget.imagebox, },
            margins = 2, widget = wibox.container.margin, },
            id = "background_role", widget = wibox.container.background, },
            layout = wibox.layout.fixed.horizontal,
        },
    }
end

-- Focusing widget
local focus_image = wibox.widget.imagebox()
local focus_icon = wibox.container.margin(focus_image, 2, 0, 0, 0)
local focus_text = wibox.widget.textbox()
widgets.focuswidget = wibox.layout.fixed.horizontal(focus_icon, focus_text)

local function update_focus_widget()
    local focused = client.focus
    if not focused or not focused.name then
        focus_image:set_image(nil)
        focus_text:set_text("")
        return
    end
    focus_image:set_image(focused.icon and focused.icon or beautiful.awesome_icon)
    focus_text:set_markup(string.format(" %s", gears.string.xml_escape(focused.name)))
end

client.connect_signal("focus", update_focus_widget)
client.connect_signal("unfocus", update_focus_widget)
client.connect_signal("property::name", update_focus_widget)
client.connect_signal("property::icon", update_focus_widget)
update_focus_widget()

return widgets

-- file:///home/nqvietz/.config/awesome/3-wibar.lua
-- file:///home/nqvietz/.config/awesome/3p2-custom_icons.lua

-- Remaining: notification widget.
-- Add the popup widget for each widget.