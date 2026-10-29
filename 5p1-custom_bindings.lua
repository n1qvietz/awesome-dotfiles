local gears = require("gears")
local awful = require("awful")
local naughty = require("naughty")

-- Reusable screenshot helper (saves, copies to clipboard, and notifies with thumbnail)
local function take_screenshot(opts)
    opts = opts or {}
    local dir = os.getenv("HOME") .. "/Pictures/Screenshots"
    local prefix = opts.prefix or "Screenshot from "
    local date_format = opts.date_format or "%Y-%m-%d %H-%M-%S"
    gears.filesystem.make_directories(dir)

    local ss = awful.screenshot({
        directory   = dir,
        file_path   = dir .. "/" .. prefix .. os.date(date_format) .. ".png",
        client      = opts.client,
        interactive = opts.interactive,
    })

    ss:connect_signal("file::saved", function(_, path)
        awful.spawn.with_shell(string.format("xclip -selection clipboard -t image/png -i %q", path))
        naughty.notification({
            title   = (opts.title or "Screenshot") .. " Copied",
            message = path:match("[^/]+$") or path,
            icon    = ss.surface,
            icon_size = 128,
        })
    end)

    if opts.interactive then
        ss:refresh()
    else
        ss:save()
    end
end

local customkeys = gears.table.join(
    -- Launchers
    awful.key({ modkey }, "space", function() awful.spawn("rofi -show drun")
    end, { description = "open Rofi application launcher", group = "launcher" }),
    awful.key({ modkey }, "r", function() awful.spawn("rofi -show run")
    end, { description = "open Rofi run launcher", group = "launcher" }),
    awful.key({ modkey }, "c", function() awful.spawn("code")
    end, { description = "open VS Code", group = "launcher" }),
    awful.key({ modkey }, "d", function() awful.spawn("discord")
    end, { description = "open Discord", group = "launcher" }),
    awful.key({ modkey }, "t", function() awful.spawn("ghostty")
    end, { description = "open Ghostty", group = "launcher" }),
    awful.key({ modkey }, "b", function() awful.spawn("google-chrome-stable")
    end, { description = "open Google Chrome", group = "launcher" }),
    awful.key({ modkey }, "e", function() awful.spawn("dolphin")
    end, { description = "open Dolphin", group = "launcher" }),
    awful.key({ "Control", "Shift" }, "Escape", function() awful.spawn("ghostty -e btop")
    end, { description = "open btop", group = "launcher" }),

    -- Client manipulation
    awful.key({ modkey }, "q", function() if client.focus then client.focus:kill() end
    end, { description = "close focused window", group = "client" }),

    -- Audio control
    awful.key({ }, "XF86AudioMute", function() awful.spawn("amixer set Master toggle")
    end, { description = "mute/unmute volume", group = "audio" }),
    awful.key({ }, "XF86AudioLowerVolume", function() awful.spawn.with_shell(
        "amixer set Master 5%- && amixer set Master unmute"
    ) end, { description = "lower volume", group = "audio" }),
    awful.key({ }, "XF86AudioRaiseVolume", function() awful.spawn.with_shell(
        "amixer set Master 5%+ && amixer set Master unmute"
    ) end, { description = "raise volume", group = "audio" }),

    -- Voice control
    awful.key({ "Control" }, "XF86AudioMute", function() awful.spawn("amixer set Capture toggle")
    end, { description = "mute/unmute microphone", group = "audio" }),

    -- Brightness control
    awful.key({ }, "XF86MonBrightnessUp", function() awful.spawn("brightnessctl set +5%")
    end, { description = "increase brightness", group = "brightness" }),
    awful.key({ }, "XF86MonBrightnessDown", function() awful.spawn("brightnessctl set 5%-")
    end, { description = "decrease brightness", group = "brightness" }),
    awful.key({ "Control" }, "XF86MonBrightnessUp", function() awful.spawn("redshift -x")
    end, { description = "disable night mode", group = "brightness" }),
    awful.key({ "Control" }, "XF86MonBrightnessDown", function() awful.spawn.with_shell(
        "redshift -x && redshift -O 3000K"
    ) end, { description = "enable night mode", group = "brightness" }),

    -- Media control (currently supports Spotify only)
    awful.key({ }, "XF86AudioPlay", function() awful.spawn("playerctl --player=spotify play-pause")
    end, { description = "play/pause music", group = "audio" }),
    awful.key({ "Control" }, "XF86AudioRaiseVolume", function() awful.spawn("playerctl --player=spotify volume 0.05+")
    end, { description = "increase media player volume", group = "audio" }),
    awful.key({ "Control" }, "XF86AudioLowerVolume", function() awful.spawn("playerctl --player=spotify volume 0.05-")
    end, { description = "decrease media player volume", group = "audio" }),

    -- Screenshot
    awful.key({ }, "Print", function()
        take_screenshot({ title = "Fullscreen" })
    end, { description = "take a screenshot", group = "screenshot" }),
    awful.key({ "Control" }, "Print", function() if client.focus then
        take_screenshot({ client = client.focus, title = "Window" }) end
    end, { description = "take a screenshot of focused window", group = "screenshot" }),
    awful.key({ modkey, "Shift" }, "s", function()
        take_screenshot({ interactive = true, title = "Area" })
    end, { description = "take a screenshot of selected area", group = "screenshot" })
)

return customkeys