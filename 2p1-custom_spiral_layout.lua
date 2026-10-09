local custom_spiral_layout = {
    name = "custom spiral",
}

local creation_order = setmetatable({}, { __mode = "k" })
local next_creation_order = 0

client.connect_signal("manage", function(c)
    next_creation_order = next_creation_order + 1
    creation_order[c] = next_creation_order
end)

local function set_geometry(geometries, c, x, y, width, height)
    geometries[c] = {
        x = x,
        y = y,
        width = width,
        height = height,
    }
end

local function split_width(area, count, index)
    local width = math.floor(area.width / count)
    local x = area.x + width * (index - 1)

    if index == count then
        width = area.x + area.width - x
    end

    return x, width
end

local function order_oldest_first(clients)
    for _, c in ipairs(clients) do
        if not creation_order[c] then
            next_creation_order = next_creation_order + 1
            creation_order[c] = next_creation_order
        end
    end

    table.sort(clients, function(a, b)
        return creation_order[a] < creation_order[b]
    end)
end

function custom_spiral_layout.arrange(params)
    local clients = {}
    for index, c in ipairs(params.clients) do
        clients[index] = c
    end
    order_oldest_first(clients)

    local geometries = params.geometries
    local area = params.workarea
    local count = #clients

    if count == 0 then
        return
    end

    if count == 1 then
        set_geometry(geometries, clients[1], area.x, area.y, area.width, area.height)
        return
    end

    local top_height = math.floor(area.height / 2)
    local bottom_y = area.y + top_height
    local bottom_height = area.y + area.height - bottom_y

    if count == 2 then
        for index, c in ipairs(clients) do
            local x, width = split_width(area, 2, index)
            set_geometry(geometries, c, x, area.y, width, area.height)
        end
        return
    end

    if count == 3 then
        local left_width = math.floor(area.width / 2)
        local right_x = area.x + left_width
        local right_width = area.x + area.width - right_x
        local right_top_height = math.floor(area.height / 2)

        set_geometry(geometries, clients[1], area.x, area.y, left_width, area.height)
        set_geometry(geometries, clients[2], right_x, area.y, right_width, right_top_height)
        set_geometry(geometries, clients[3], right_x, area.y + right_top_height, right_width,
            area.height - right_top_height)
        return
    end

    if count == 4 then
        local half_width = math.floor(area.width / 2)
        local right_x = area.x + half_width
        local right_width = area.x + area.width - right_x

        -- The newest client takes the first priority slot: RB, then LB, RT, LT.
        set_geometry(geometries, clients[4], right_x, bottom_y, right_width, bottom_height)
        set_geometry(geometries, clients[3], area.x, bottom_y, half_width, bottom_height)
        set_geometry(geometries, clients[2], right_x, area.y, right_width, top_height)
        set_geometry(geometries, clients[1], area.x, area.y, half_width, top_height)
        return
    end

    for index = 1, 2 do
        local x, width = split_width(area, 2, index)
        set_geometry(geometries, clients[index], x, area.y, width, top_height)
    end

    if count == 5 then
        local left_width = math.floor(area.width / 2)
        local right_x = area.x + left_width
        local right_width = area.x + area.width - right_x
        local mini_width = math.floor(right_width / 2)

        set_geometry(geometries, clients[3], area.x, bottom_y, left_width, bottom_height)
        set_geometry(geometries, clients[4], right_x, bottom_y, mini_width, bottom_height)
        set_geometry(geometries, clients[5], right_x + mini_width, bottom_y,
            right_width - mini_width, bottom_height)
        return
    end

    local mini_count = count - 2
    for index = 1, mini_count do
        local x, width = split_width(area, mini_count, index)
        set_geometry(geometries, clients[index + 2], x, bottom_y, width, bottom_height)
    end
end

return custom_spiral_layout

--[[
local spiral_floating = {}

local creation_order = setmetatable({}, { __mode = "k" })
local next_creation_order = 0

client.connect_signal("manage", function(c)
    next_creation_order = next_creation_order + 1
    creation_order[c] = next_creation_order
end)

local function set_geometry(geometries, c, x, y, width, height)
    geometries[c] = {
        x = x,
        y = y,
        width = width,
        height = height,
    }
end

--]]