local spiral_floating = {
    name = "spiral_floating",
}

local function split_lr(rect)
    local left_width = math.floor(rect.width * 0.5)
    return {
        x = rect.x,
        y = rect.y,
        width = left_width,
        height = rect.height,
    }, {
        x = rect.x + left_width,
        y = rect.y,
        width = rect.width - left_width,
        height = rect.height,
    }
end

local function split_tb(rect)
    local top_height = math.floor(rect.height * 0.5)
    return {
        x = rect.x,
        y = rect.y,
        width = rect.width,
        height = top_height,
    }, {
        x = rect.x,
        y = rect.y + top_height,
        width = rect.width,
        height = rect.height - top_height,
    }
end

local function target_index_for_count(k)
    local n = 1
    while n < k do
        n = n << 1
    end

    return n + 1 - k
end

local function split_direction_for_count(count)
    if count == 3 or count == 4 then
        return "tb"
    end

    return "lr"
end

local function get_visible_clients(s)
    local clients = {}

    for _, c in ipairs(s.clients) do
        if c and c.valid and c:isvisible() then
            table.insert(clients, c)
        end
    end

    table.sort(clients, function(a, b)
        local ga = a:geometry()
        local gb = b:geometry()
        if ga.x ~= gb.x then
            return ga.x > gb.x
        end
        return ga.y > gb.y
    end)

    return clients
end

local function rebuild_screen_layout(s)
    local clients = get_visible_clients(s)
    if #clients == 0 then
        return
    end

    local geometry = s.workarea
    local rects = {}

    rects[clients[1]] = {
        x = geometry.x,
        y = geometry.y,
        width = geometry.width,
        height = geometry.height,
    }

    for index = 2, #clients do
        local target_client = clients[target_index_for_count(index)]
        local current_rect = rects[target_client] or rects[clients[1]]

        local next_rect, new_rect
        if split_direction_for_count(index) == "lr" then
            next_rect, new_rect = split_lr(current_rect)
        else
            next_rect, new_rect = split_tb(current_rect)
        end

        rects[target_client] = next_rect
        rects[clients[index]] = new_rect
    end

    for _, client in ipairs(clients) do
        if client and client.valid then
            client:geometry(rects[client] or {
                x = geometry.x,
                y = geometry.y,
                width = geometry.width,
                height = geometry.height,
            })
        end
    end
end

spiral_floating.arrange = function(s)
    rebuild_screen_layout(s)
end

return spiral_floating
