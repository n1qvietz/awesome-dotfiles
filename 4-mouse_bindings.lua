local awful = require("awful")
local gears = require("gears")

-- {{{ Mouse bindings
root.buttons(gears.table.join(
    awful.button({ }, 4, awful.tag.viewnext),
    awful.button({ }, 5, awful.tag.viewprev),
    awful.button({ }, 8, awful.tag.viewprev),
    awful.button({ }, 9, awful.tag.viewnext)
))
-- }}}