DD_GUI = DD_GUI or {}

DD_GUI.exit_status_by_room = DD_GUI.exit_status_by_room or {}

local compass_exit_aliases = {
        n = "n",
        north = "n",
        ne = "ne",
        northeast = "ne",
        nw = "nw",
        northwest = "nw",
        u = "u",
        up = "u",
        w = "w",
        west = "w",
        e = "e",
        east = "e",
        s = "s",
        south = "s",
        se = "se",
        southeast = "se",
        sw = "sw",
        southwest = "sw",
        d = "d",
        down = "d",
        ["in"] = "in",
        out = "out",
}

local function compass_current_room_id()
        if type(map) == "table" and type(map.room_info) == "table" then
                return tonumber(map.room_info.vnum)
        end

        if gmcp and gmcp.Room and type(gmcp.Room.Info) == "table" then
                return tonumber(gmcp.Room.Info.vnum)
        end

        return nil
end

function DD_GUI.update_exit_status(exit_text)
        local statuses = {}
        local text = tostring(exit_text or "")
        text = text:gsub("\27%[[0-9;]*m", "")
        local room_id = compass_current_room_id()
        local previous = room_id and DD_GUI.exit_status_by_room[room_id]
        if type(previous) == "table" then
                for direction, status in pairs(previous) do
                        statuses[direction] = status
                end
        end

        for token in text:gmatch("%S+") do
                local first = token:sub(1, 1)
                local last = token:sub(-1)
                local status = 1

                if first == "(" and last == ")" then
                        status = 2
                elseif first == "[" and last == "]" then
                        status = 3
                end

                local direction = token
                if first == "(" or first == "[" then
                        direction = direction:sub(2)
                end
                if last == ")" or last == "]" then
                        direction = direction:sub(1, -2)
                end
                direction = direction:lower()
                local compass_direction = compass_exit_aliases[direction]
                if compass_direction then
                        statuses[compass_direction] = status
                end
        end

        if room_id then
                DD_GUI.exit_status_by_room[room_id] = statuses
                DD_GUI.exit_status_room = room_id
                if DD_GUI.mapper_set_exit_status then
                        DD_GUI.mapper_set_exit_status(room_id, statuses)
                end
        end
end

if not DD_GUI.exit_status_event_handler then
        DD_GUI.exit_status_event_handler = registerAnonymousEventHandler(
                "gmcp.Room.Info",
                function()
                        DD_GUI.exit_status_room = nil
                end
        )
end
