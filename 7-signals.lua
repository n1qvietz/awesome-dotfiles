local awful = require("awful")
local beautiful = require("beautiful")
local gears = require("gears")
local focus_history_by_tag = {}

local function remove_from_history(history, c)
    for index, history_client in ipairs(history) do
        if history_client == c then
            table.remove(history, index)
            return
        end
    end
end

local function focus_last_client(t)
    if not t.selected then
        return
    end

    local candidate
    for _, c in ipairs(focus_history_by_tag[t] or {}) do
        if c.valid
            and not c.hidden
            and not c.minimized
            and awful.client.focus.filter(c)
            and gears.table.hasitem(c:tags(), t) then
            candidate = c
            break
        end
    end

    if not candidate then
        for _, c in ipairs(t:clients()) do
            if c.valid and awful.client.focus.filter(c) then
                candidate = c
                break
            end
        end
    end

    if not candidate then
        return
    end

    gears.timer.delayed_call(function()
        if candidate.valid and candidate:isvisible() then
            candidate:emit_signal("request::activate", "tag_selected", {raise = true})
        end
    end)
end

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.connect_signal("manage", function (c)
    -- Set the windows at the slave,
    -- i.e. put it at the end of others instead of setting it master.
    -- if not awesome.startup then awful.client.setslave(c) end

    if awesome.startup
      and not c.size_hints.user_position
      and not c.size_hints.program_position then
        -- Prevent clients from being unreachable after screen count changes.
        awful.placement.no_offscreen(c)
    end
end)

-- Enable sloppy focus, so that focus follows mouse.
client.connect_signal("mouse::enter", function(c)
    c:emit_signal("request::activate", "mouse_enter", {raise = false})
end)

client.connect_signal("focus", function(c)
    c.border_color = beautiful.border_focus
    for _, t in ipairs(c:tags()) do
        focus_history_by_tag[t] = focus_history_by_tag[t] or {}
        remove_from_history(focus_history_by_tag[t], c)
        table.insert(focus_history_by_tag[t], 1, c)
    end
end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

tag.connect_signal("property::selected", function(t)
    focus_last_client(t)
end)

client.connect_signal("request::unmanage", function(c)
    local tags = c:tags()
    for _, t in ipairs(tags) do
        local history = focus_history_by_tag[t]
        if history then
            remove_from_history(history, c)
            if #history == 0 then
                focus_history_by_tag[t] = nil
            end
        end
    end
    gears.timer.delayed_call(function()
        for _, t in ipairs(tags) do
            focus_last_client(t)
        end
    end)
end)
-- }}}
