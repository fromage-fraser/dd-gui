DD_GUI = DD_GUI or {}

local function dd_mapper_number(value)
        local number = tonumber(value)
        return number
end

local function dd_mapper_call(fn, ...)
        if type(fn) ~= "function" then
                return false, nil
        end

        return pcall(fn, ...)
end

function load_dd_mapper()
        cecho("Loading Dragons Domain custom mapper.\n")

        map = map or {}
        map.room_info = map.room_info or {}
        map.prev_info = map.prev_info or {}
        map.aliases = map.aliases or {}
        map.configs = map.configs or {}
        map.configs.speedwalk_delay = tonumber(map.configs.speedwalk_delay) or 0
        map.configs.speedwalk_random = map.configs.speedwalk_random == true
        map.configs.speedwalk_wait = map.configs.speedwalk_wait == true
        map.configs.use_translation = map.configs.use_translation == true
        map.configs.lang_dirs = map.configs.lang_dirs or {}
        map.configs.dd_safe_speedwalk = map.configs.dd_safe_speedwalk ~= false
        map.configs.dd_room_symbols = map.configs.dd_room_symbols ~= false

        DD_GUI.MapperState = DD_GUI.MapperState or {}
        local state = DD_GUI.MapperState
        state.handlers = state.handlers or {}
        state.menu_events = state.menu_events or {}
        state.zoom_seen = state.zoom_seen or {}
        state.highlights = state.highlights or {}
        state.route = nil

        local function kill_handler(handler_id)
                if handler_id then
                        pcall(killAnonymousEventHandler, handler_id)
                end
        end

        for _, handler_id in pairs(state.handlers) do
                kill_handler(handler_id)
        end
        state.handlers = {}

        for _, alias_id in pairs(map.aliases) do
                pcall(killAlias, alias_id)
        end
        map.aliases = {}

        local terrain_types = {
                [0] = {id = 20, r = 144, g = 144, b = 144},
                [1] = {id = 21, r = 100, g = 100, b = 100},
                [2] = {id = 22, r = 109, g = 241, b = 109},
                [3] = {id = 23, r = 3, g = 72, b = 2},
                [4] = {id = 24, r = 125, g = 80, b = 0},
                [5] = {id = 25, r = 42, g = 32, b = 0},
                [6] = {id = 26, r = 128, g = 180, b = 245},
                [7] = {id = 27, r = 18, g = 116, b = 238},
                [8] = {id = 28, r = 2, g = 48, b = 107},
                [9] = {id = 29, r = 206, g = 206, b = 206},
                [10] = {id = 30, r = 208, g = 180, b = 5},
                [11] = {id = 31, r = 54, g = 84, b = 60},
                [12] = {id = 32, r = 2, g = 78, b = 107},
        }

        local move_vectors = {
                n = {0, 1, 0}, s = {0, -1, 0}, e = {1, 0, 0}, w = {-1, 0, 0},
                ne = {1, 1, 0}, nw = {-1, 1, 0}, se = {1, -1, 0}, sw = {-1, -1, 0},
                u = {0, 0, 1}, d = {0, 0, -1},
        }

        local direction_names = {
                n = "north", north = "north", ne = "northeast", northeast = "northeast",
                nw = "northwest", northwest = "northwest", e = "east", east = "east",
                w = "west", west = "west", s = "south", south = "south",
                se = "southeast", southeast = "southeast", sw = "southwest", southwest = "southwest",
                u = "up", up = "up", d = "down", down = "down", ["in"] = "in", out = "out",
        }

        local direction_aliases = {
                north = "n", northeast = "ne", northwest = "nw", east = "e", west = "w",
                south = "s", southeast = "se", southwest = "sw", up = "u", down = "d",
                ["in"] = "in", out = "out",
        }

        local function short_direction(direction)
                local value = tostring(direction or ""):lower()
                return direction_aliases[value] or value
        end

        local function long_direction(direction)
                local value = short_direction(direction)
                return direction_names[value] or value
        end

        local function direction_vector(direction)
                return move_vectors[short_direction(direction)]
        end

        local function normalise_door_status(value)
                if type(value) == "number" then
                        return math.max(0, math.min(3, math.floor(value)))
                end

                local text = tostring(value or ""):lower()
                if text == "open" or text == "opened" or text == "1" then
                        return 1
                elseif text == "closed" or text == "close" or text == "2" then
                        return 2
                elseif text == "locked" or text == "lock" or text == "3" then
                        return 3
                end
                return 0
        end

        local function normalise_exit(value)
                local result = {
                        to = nil,
                        status = 0,
                        door = nil,
                        command = nil,
                }

                if type(value) == "table" then
                        result.to = dd_mapper_number(
                                value.to or value.vnum or value.room or value.id or value.destination
                        )
                        result.status = normalise_door_status(value.status or value.state or value.door_state)
                        result.door = value.door or value.door_name
                        result.command = value.command or value.move or value.keyword
                else
                        result.to = dd_mapper_number(value)
                end

                return result
        end

        local function normalise_room_info(source)
                if type(source) ~= "table" then
                        return nil
                end

                local room_id = dd_mapper_number(source.vnum)
                if not room_id then
                        return nil
                end

                local exits = {}
                if type(source.exits) == "table" then
                        for direction, value in pairs(source.exits) do
                                local short = short_direction(direction)
                                if direction_names[short] then
                                        exits[short] = normalise_exit(value)
                                end
                        end
                end

                local arrival = source.arrival or source.transition or source.move_info
                if type(arrival) ~= "table" then
                        arrival = nil
                end

                return {
                        vnum = room_id,
                        area = tostring(source.area or "Unknown"),
                        area_id = dd_mapper_number(source.area_id),
                        name = tostring(source.name or room_id),
                        sector = dd_mapper_number(source.sector),
                        sector_text = tostring(source.sector_text or ""),
                        description = tostring(source.description or ""),
                        flags = source.flags,
                        exits = exits,
                        special_exits = source.special_exits or source.specialExits,
                        arrival = arrival,
                }
        end

        local function mapper_echo(message, is_error)
                local colour = is_error and "<red>" or "<yellow>"
                cecho(colour .. "[Mapper] " .. tostring(message) .. "<reset>\n")
        end

        -- The custom mapper must not depend on helpers left behind by
        -- generic_mapper, which DD_GUI removes during bootstrap.
        map.echo = mapper_echo
        state.map_echo = mapper_echo

        local function room_coordinates(room_id)
                local ok, x, y, z = dd_mapper_call(getRoomCoordinates, room_id)
                if not ok or x == nil then
                        return nil
                end
                return {tonumber(x) or 0, tonumber(y) or 0, tonumber(z) or 0}
        end

        local function room_area(room_id)
                local ok, area_id = dd_mapper_call(getRoomArea, room_id)
                return ok and tonumber(area_id) or nil
        end

        local function area_id_for(info)
                local name = tostring(info and info.area or "Unknown")
                local areas = getAreaTable()

                if info and info.area_id and type(getAreaUserData) == "function" then
                        for _, candidate_id in pairs(areas or {}) do
                                local ok, stored = dd_mapper_call(
                                        getAreaUserData, candidate_id, "dd_gui.server_area_id"
                                )
                                if ok and tonumber(stored) == tonumber(info.area_id) then
                                        return tonumber(candidate_id)
                                end
                        end
                end

                local area_id = areas and areas[name]
                if area_id then
                        if info and info.area_id and type(setAreaUserData) == "function" then
                                pcall(setAreaUserData, area_id, "dd_gui.server_area_id", tostring(info.area_id))
                        end
                        return tonumber(area_id)
                end

                local ok, added = dd_mapper_call(addAreaName, name)
                if ok and added then
                        if info and info.area_id and type(setAreaUserData) == "function" then
                                pcall(setAreaUserData, added, "dd_gui.server_area_id", tostring(info.area_id))
                        end
                        return tonumber(added)
                end

                areas = getAreaTable()
                return areas and tonumber(areas[name]) or nil
        end

        local function room_at(area_id, x, y, z, excluded)
                local getter = getRoomsByPosition1 or getRoomsByPosition
                local ok, rooms = dd_mapper_call(getter, area_id, x, y, z)
                if not ok or type(rooms) ~= "table" then
                        return false
                end

                for _, room_id in pairs(rooms) do
                        if tonumber(room_id) ~= tonumber(excluded) then
                                return true
                        end
                end
                return false
        end

        local placement_offsets = {
                {0, 0}, {1, 0}, {-1, 0}, {0, 1}, {0, -1},
                {1, 1}, {-1, 1}, {1, -1}, {-1, -1}, {2, 0}, {-2, 0},
                {0, 2}, {0, -2}, {2, 1}, {-2, 1}, {2, -1}, {-2, -1},
        }

        local function free_coordinates(area_id, base, room_id)
                for _, offset in ipairs(placement_offsets) do
                        local x = base[1] + offset[1]
                        local y = base[2] + offset[2]
                        if not room_at(area_id, x, y, base[3], room_id) then
                                return {x, y, base[3]}, offset[1] ~= 0 or offset[2] ~= 0
                        end
                end

                return {base[1] + 3, base[2] + 3, base[3]}, true
        end

        local function serialise_exits(exits)
                local parts = {}
                for direction, exit in pairs(exits or {}) do
                        if exit.to then
                                table.insert(parts, direction .. "=" .. tostring(exit.to))
                        end
                end
                table.sort(parts)
                return table.concat(parts, ";")
        end

        local function parse_serialised_exits(value)
                local result = {}
                for part in tostring(value or ""):gmatch("[^;]+") do
                        local direction, room_id = part:match("^([^=]+)=(%d+)$")
                        if direction and room_id then
                                result[direction] = tonumber(room_id)
                        end
                end
                return result
        end

        local function set_room_metadata(info, area_id)
                pcall(setRoomName, info.vnum, info.name)
                pcall(setRoomArea, info.vnum, area_id)

                local terrain = terrain_types[info.sector]
                if terrain and type(setRoomEnv) == "function" then
                        pcall(setRoomEnv, info.vnum, terrain.id)
                        if type(setCustomEnvColor) == "function" then
                                pcall(setCustomEnvColor, terrain.id, terrain.r, terrain.g, terrain.b, 255)
                        end
                end
        end

        local function set_exit_door(room_id, direction, status)
                if status and status > 0 and type(setDoor) == "function" then
                        pcall(setDoor, room_id, short_direction(direction), status)
                end
        end

        local function sync_room_exits(info, created)
                local previous = {}
                local previous_serialised = ""
                if type(getRoomUserData) == "function" then
                        local ok, value = dd_mapper_call(getRoomUserData, info.vnum, "dd_gui.exits")
                        if ok then
                                previous_serialised = tostring(value or "")
                                previous = parse_serialised_exits(value)
                        end
                end

                for direction, exit in pairs(info.exits) do
                        if exit.to and roomExists(exit.to) then
                                pcall(setExit, info.vnum, exit.to, direction)
                        else
                                pcall(setExitStub, info.vnum, direction, true)
                        end
                        set_exit_door(info.vnum, direction, exit.status)
                end

                if type(info.special_exits) == "table" and type(addSpecialExit) == "function" then
                        for _, special in pairs(info.special_exits) do
                                if type(special) == "table" then
                                        local destination = dd_mapper_number(
                                                special.to or special.vnum or special.room or special.id
                                        )
                                        local command = special.command or special.name or special.move
                                        if destination and command and roomExists(destination) then
                                                pcall(addSpecialExit, info.vnum, destination, tostring(command))
                                        end
                                end
                        end
                end

                if created and type(setRoomUserData) == "function" then
                        pcall(setRoomUserData, info.vnum, "dd_gui.managed", "1")
                end

                local managed = false
                if type(getRoomUserData) == "function" then
                        local ok, value = dd_mapper_call(getRoomUserData, info.vnum, "dd_gui.managed")
                        managed = ok and tostring(value) == "1"
                end

                -- Only remove stale links from rooms explicitly created by this
                -- mapper. Existing hand-built rooms remain untouched.
                if managed then
                        for direction in pairs(previous) do
                                if not info.exits[direction] then
                                        pcall(setExitStub, info.vnum, direction, false)
                                        pcall(setExit, info.vnum, -1, direction)
                                end
                        end
                end

                local current_serialised = serialise_exits(info.exits)
                if type(setRoomUserData) == "function" and previous_serialised ~= current_serialised then
                        pcall(setRoomUserData, info.vnum, "dd_gui.exits", current_serialised)
                end

                return previous_serialised ~= current_serialised
        end

        local function room_flag_text(info)
                if type(info.flags) == "string" then
                        return info.flags:lower()
                elseif type(info.flags) == "table" then
                        local parts = {}
                        for _, flag in pairs(info.flags) do
                                table.insert(parts, tostring(flag):lower())
                        end
                        return table.concat(parts, " ")
                end
                return ""
        end

        local function apply_room_semantics(info)
                if not map.configs.dd_room_symbols or type(setRoomChar) ~= "function" then
                        return
                end

                local flags = room_flag_text(info)
                local symbol
                if flags:find("death") or flags:find("no recall") or flags:find("no_recall") then
                        symbol = "!"
                elseif flags:find("quest") then
                        symbol = "Q"
                elseif flags:find("trainer") then
                        symbol = "T"
                elseif flags:find("healer") then
                        symbol = "H"
                elseif flags:find("shop") or flags:find("store") then
                        symbol = "$"
                elseif flags:find("safe") then
                        symbol = "S"
                end

                if not symbol then
                        return
                end

                local existing = ""
                if type(getRoomChar) == "function" then
                        local ok, value = dd_mapper_call(getRoomChar, info.vnum)
                        existing = ok and tostring(value or "") or ""
                end

                local owned = false
                if type(getRoomUserData) == "function" then
                        local ok, value = dd_mapper_call(getRoomUserData, info.vnum, "dd_gui.symbol")
                        owned = ok and tostring(value or "") ~= ""
                end

                if existing == "" or owned then
                        pcall(setRoomChar, info.vnum, symbol)
                        if type(setRoomCharColor) == "function" then
                                local colour = symbol == "!" and {220, 40, 45} or {210, 170, 45}
                                pcall(setRoomCharColor, info.vnum, colour[1], colour[2], colour[3])
                        end
                        if type(setRoomUserData) == "function" then
                                pcall(setRoomUserData, info.vnum, "dd_gui.symbol", symbol)
                        end
                end
        end

        local function placement_for(info, area_id)
                local previous_id = dd_mapper_number(map.prev_info and map.prev_info.vnum)
                local previous_coords = previous_id and room_coordinates(previous_id)
                local previous_area = previous_id and room_area(previous_id)
                local base

                if previous_coords and previous_area == area_id then
                        local arrival = info.arrival
                        local arrival_direction = arrival and (arrival.direction or arrival.dir or arrival.command)
                        local arrival_vector = direction_vector(arrival_direction)
                        if arrival_vector then
                                base = {
                                        previous_coords[1] + arrival_vector[1],
                                        previous_coords[2] + arrival_vector[2],
                                        previous_coords[3] + arrival_vector[3],
                                }
                        else
                                for direction, exit in pairs(info.exits) do
                                        if exit.to == previous_id and direction_vector(direction) then
                                                local vector = direction_vector(direction)
                                                base = {
                                                        previous_coords[1] - vector[1],
                                                        previous_coords[2] - vector[2],
                                                        previous_coords[3] - vector[3],
                                                }
                                                break
                                        end
                                end
                        end
                end

                base = base or {0, 0, 0}
                return free_coordinates(area_id, base, info.vnum)
        end

        local function create_room(info, area_id)
                local coordinates, displaced = placement_for(info, area_id)
                local added = pcall(addRoom, info.vnum, area_id)
                if not added then
                        pcall(addRoom, info.vnum)
                end
                set_room_metadata(info, area_id)
                pcall(setRoomCoordinates, info.vnum, coordinates[1], coordinates[2], coordinates[3])

                if displaced and type(setRoomUserData) == "function" then
                        pcall(setRoomUserData, info.vnum, "dd_gui.placement_note", "coordinate collision; placed nearby")
                end

                return true
        end

        local function reconcile_room(info)
                local created = not roomExists(info.vnum)
                local area_id = area_id_for(info)
                if not area_id then
                        return false, false
                end

                if created then
                        create_room(info, area_id)
                else
                        set_room_metadata(info, area_id)
                end

                local exits_changed = sync_room_exits(info, created)
                apply_room_semantics(info)
                return created or exits_changed, created
        end

        local function clear_highlights()
                for room_id in pairs(state.highlights) do
                        if type(unHighlightRoom) == "function" then
                                pcall(unHighlightRoom, room_id)
                        end
                end
                state.highlights = {}
        end

        local function highlight(room_id, colour_a, colour_b)
                if not room_id or not roomExists(room_id) or type(highlightRoom) ~= "function" then
                        return
                end
                pcall(highlightRoom, room_id, colour_a[1], colour_a[2], colour_a[3],
                        colour_b[1], colour_b[2], colour_b[3], 1, 180, 90)
                state.highlights[room_id] = true
        end

        local function refresh_route_highlights()
                clear_highlights()
                local route = state.route
                if not route then
                        return
                end

                highlight(route.target, {190, 35, 45}, {55, 0, 0})
                for index = math.max(1, #route.visited - 3), #route.visited do
                        highlight(route.visited[index], {90, 90, 90}, {20, 20, 20})
                end
                local next_action = route.actions[route.index]
                if next_action then
                        highlight(next_action.to, {255, 130, 30}, {65, 10, 0})
                end
                for offset = 1, 3 do
                        local future = route.actions[route.index + offset]
                        if future then
                                highlight(future.to, {110, 35, 40}, {25, 0, 0})
                        end
                end
        end

        local function refresh_quest_marker()
                if state.route then
                        return
                end

                local quest = gmcp and gmcp.Char and gmcp.Char.Quest
                if type(quest) ~= "table" then
                        return
                end
                if type(quest[1]) == "table" and quest.room_vnum == nil then
                        quest = quest[1]
                end

                local room_id = dd_mapper_number(quest.room_vnum)
                if room_id and roomExists(room_id) then
                        highlight(room_id, {190, 150, 30}, {50, 30, 0})
                        state.quest_marker = room_id
                end
        end

        local function fit_area(area_id)
                area_id = tonumber(area_id)
                if not area_id or type(getAreaRooms) ~= "function" or type(setMapZoom) ~= "function" then
                        return false
                end

                local ok, rooms = dd_mapper_call(getAreaRooms, area_id)
                if not ok or type(rooms) ~= "table" or #rooms == 0 then
                        return false
                end

                local min_x, max_x, min_y, max_y
                for _, room_id in ipairs(rooms) do
                        local coordinates = room_coordinates(room_id)
                        if coordinates then
                                min_x = min_x and math.min(min_x, coordinates[1]) or coordinates[1]
                                max_x = max_x and math.max(max_x, coordinates[1]) or coordinates[1]
                                min_y = min_y and math.min(min_y, coordinates[2]) or coordinates[2]
                                max_y = max_y and math.max(max_y, coordinates[2]) or coordinates[2]
                        end
                end

                local span = math.max((max_x or 0) - (min_x or 0), (max_y or 0) - (min_y or 0))
                local zoom = math.max(3.5, math.min(16, 4.5 + span * 0.65))
                pcall(setMapZoom, zoom, area_id)
                return true
        end

        local function auto_fit_area(area_id)
                local key = tostring(area_id)
                if state.zoom_seen[key] then
                        return
                end

                local seen = false
                if type(getAreaUserData) == "function" then
                        local ok, value = dd_mapper_call(getAreaUserData, area_id, "dd_gui.autofit")
                        seen = ok and tostring(value) == "1"
                end
                if not seen then
                        fit_area(area_id)
                        state.zoom_seen[key] = true
                        if type(setAreaUserData) == "function" then
                                pcall(setAreaUserData, area_id, "dd_gui.autofit", "1")
                        end
                end
        end

        local function door_status(room_id, direction)
                local short = short_direction(direction)
                local parsed = DD_GUI.exit_status_by_room and DD_GUI.exit_status_by_room[room_id]
                if parsed and parsed[short] then
                        return tonumber(parsed[short]) or 0
                end

                if type(getDoors) == "function" then
                        local ok, doors = dd_mapper_call(getDoors, room_id)
                        if ok and type(doors) == "table" then
                                return tonumber(doors[short]) or tonumber(doors[long_direction(short)]) or 0
                        end
                end
                return 0
        end

        local function movement_commands(room_id, direction)
                local command = long_direction(direction)
                local status = door_status(room_id, direction)
                if status == 3 then
                        return {"unlock " .. command, "open " .. command, command}
                elseif status == 2 then
                        return {"open " .. command, command}
                end
                return {command}
        end

        local function stop_route(message)
                if state.route and state.route.timeout_timer then
                        pcall(killTimer, state.route.timeout_timer)
                end
                state.route = nil
                map.walkDirs = nil
                map.walkPath = nil
                clear_highlights()
                if message then
                        mapper_echo(message, true)
                end
        end

        local send_next_route_action
        send_next_route_action = function()
                local route = state.route
                if not route then
                        return
                end

                local action = route.actions[route.index]
                if not action then
                        local destination = route.target
                        state.route = nil
                        clear_highlights()
                        mapper_echo("Arrived at room " .. tostring(destination) .. ".")
                        return
                end

                route.awaiting = action.to
                route.last_room = map.room_info.vnum
                for index, command in ipairs(movement_commands(action.from, action.direction)) do
                        tempTimer((index - 1) * 0.2, function()
                                if state.route == route then
                                        send(command)
                                end
                        end)
                end

                if route.timeout_timer then
                        pcall(killTimer, route.timeout_timer)
                end
                route.timeout_timer = tempTimer(8, function()
                        if state.route == route then
                                stop_route("Speedwalk stopped: no room update was received.")
                        end
                end)
                refresh_route_highlights()
        end

        local function start_route(room_id)
                room_id = tonumber(room_id)
                if not room_id or not roomExists(room_id) then
                        mapper_echo("That room is not mapped.", true)
                        return false
                end

                local current = tonumber(map.room_info.vnum)
                if not current then
                        mapper_echo("The current room is not known yet.", true)
                        return false
                end
                if current == room_id then
                        mapper_echo("Already in that room.")
                        return true
                end

                if not getPath(current, room_id) then
                        mapper_echo("No path to room " .. tostring(room_id) .. " found.", true)
                        return false
                end

                local path = {}
                local directions = {}
                for index, value in ipairs(speedWalkPath or {}) do
                        path[index] = tonumber(value)
                end
                for index, value in ipairs(speedWalkDir or {}) do
                        directions[index] = value
                end

                local actions = {}
                for index, direction in ipairs(directions) do
                        local from = path[index]
                        local to = path[index + 1]
                        if from and to then
                                table.insert(actions, {
                                        from = from,
                                        to = to,
                                        direction = direction,
                                })
                        end
                end

                if #actions == 0 then
                        mapper_echo("No usable path to room " .. tostring(room_id) .. " found.", true)
                        return false
                end

                stop_route()
                state.route = {
                        target = room_id,
                        actions = actions,
                        index = 1,
                        last_room = current,
                        visited = {current},
                }
                map.walkPath = path
                map.walkDirs = directions
                if not map.configs.dd_safe_speedwalk then
                        for _, action in ipairs(actions) do
                                for _, command in ipairs(movement_commands(action.from, action.direction)) do
                                        send(command)
                                end
                        end
                        state.route = nil
                        clear_highlights()
                        return true
                end
                refresh_route_highlights()
                send_next_route_action()
                return true
        end

        function map.speedwalk(room_id)
                return start_route(room_id)
        end

        function doSpeedWalk()
                local path = speedWalkPath or {}
                local destination = path[#path]
                if destination then
                        start_route(destination)
                else
                        mapper_echo("No path to chosen room found.", true)
                end
        end

        function DD_GUI.mapper_set_exit_status(room_id, statuses)
                room_id = tonumber(room_id)
                if not room_id or type(statuses) ~= "table" then
                        return
                end
                for direction, status in pairs(statuses) do
                        set_exit_door(room_id, direction, tonumber(status) or 0)
                end
        end

        function DD_GUI.mapper_shift(direction)
                local short = short_direction(direction)
                local vector = direction_vector(short)
                local room_id = map.room_info and tonumber(map.room_info.vnum)
                if not vector or not room_id or not roomExists(room_id) then
                        mapper_echo("Invalid shift direction.", true)
                        return false
                end
                local coordinates = room_coordinates(room_id)
                if not coordinates then
                        return false
                end
                pcall(setRoomCoordinates, room_id,
                        coordinates[1] + vector[1], coordinates[2] + vector[2], coordinates[3] + vector[3])
                if save_dd_mapper then
                        save_dd_mapper()
                end
                centerview(room_id)
                return true
        end

        function DD_GUI.mapper_fit_area()
                local area_id = map.room_info and room_area(tonumber(map.room_info.vnum))
                if area_id and fit_area(area_id) then
                        centerview(map.room_info.vnum)
                        return true
                end
                return false
        end

        local function selected_rooms()
                if type(getMapSelection) ~= "function" then
                        return {}
                end
                local ok, selection = dd_mapper_call(getMapSelection)
                return ok and type(selection) == "table" and selection.rooms or {}
        end

        local function handle_mapper_menu(_, action)
                local rooms = selected_rooms()
                if action == "fit" then
                        DD_GUI.mapper_fit_area()
                elseif action == "center" then
                        if map.room_info and map.room_info.vnum then
                                centerview(map.room_info.vnum)
                        end
                elseif action == "route" then
                        if rooms[1] then
                                start_route(rooms[1])
                        end
                elseif action == "avoid" or action == "allow" then
                        for _, room_id in ipairs(rooms) do
                                if action == "avoid" then
                                        local old_weight = 1
                                        if type(getRoomWeight) == "function" then
                                                local ok, value = dd_mapper_call(getRoomWeight, room_id)
                                                old_weight = ok and tonumber(value) or 1
                                        end
                                        if type(setRoomUserData) == "function" then
                                                pcall(setRoomUserData, room_id, "dd_gui.avoid_weight", tostring(old_weight))
                                        end
                                        pcall(setRoomWeight, room_id, 100)
                                        if type(setRoomUserData) == "function" then
                                                pcall(setRoomUserData, room_id, "dd_gui.avoid", "1")
                                        end
                                else
                                        local old_weight = 1
                                        if type(getRoomUserData) == "function" then
                                                local ok, value = dd_mapper_call(getRoomUserData, room_id, "dd_gui.avoid_weight")
                                                old_weight = ok and tonumber(value) or 1
                                        end
                                        pcall(setRoomWeight, room_id, old_weight)
                                        if type(clearRoomUserDataItem) == "function" then
                                                pcall(clearRoomUserDataItem, room_id, "dd_gui.avoid")
                                                pcall(clearRoomUserDataItem, room_id, "dd_gui.avoid_weight")
                                        end
                                end
                        end
                elseif action == "quest" then
                        local quest = gmcp and gmcp.Char and gmcp.Char.Quest
                        local quest_room = type(quest) == "table" and tonumber(quest.room_vnum)
                        if quest_room and roomExists(quest_room) then
                                centerview(quest_room)
                                clear_highlights()
                                highlight(quest_room, {190, 150, 30}, {50, 30, 0})
                        else
                                mapper_echo("The current quest destination is not mapped.", true)
                        end
                end
end

        local function register_mapper_menu()
                if type(addMapMenu) ~= "function" or type(addMapEvent) ~= "function" then
                        return
                end

                if state.handlers.menu then
                        pcall(killAnonymousEventHandler, state.handlers.menu)
                        state.handlers.menu = nil
                end
                pcall(removeMapMenu, "DD_GUI.Mapper")
                pcall(addMapMenu, "DD_GUI.Mapper", nil, "DD_GUI")
                local entries = {
                        {"fit", "Fit current area"},
                        {"center", "Centre on player"},
                        {"route", "Route to selected room"},
                        {"quest", "Show quest destination"},
                        {"avoid", "Avoid selected rooms"},
                        {"allow", "Allow selected rooms"},
                }
                for _, entry in ipairs(entries) do
                        pcall(removeMapEvent, "DD_GUI.Mapper." .. entry[1])
                        pcall(addMapEvent, "DD_GUI.Mapper." .. entry[1],
                                "DD_GUI.MapperMenu", "DD_GUI.Mapper", entry[2], entry[1])
                end
                state.handlers.menu = registerAnonymousEventHandler("DD_GUI.MapperMenu", handle_mapper_menu)
        end

        local function audit_mapper()
                local area_count = 0
                local room_count = 0
                local overlap_count = 0
                local invalid_name_count = 0
                local dangling_exit_count = 0
                local areas = getAreaTable() or {}

                for area_name, area_id in pairs(areas) do
                        area_count = area_count + 1
                        local rooms = getAreaRooms(tonumber(area_id)) or {}
                        room_count = room_count + #rooms
                        local seen = {}
                        for _, room_id in ipairs(rooms) do
                                local coordinates = room_coordinates(room_id)
                                if coordinates then
                                        local key = table.concat(coordinates, ":")
                                        if seen[key] then
                                                overlap_count = overlap_count + 1
                                        end
                                        seen[key] = room_id
                                end
                                local ok, name = dd_mapper_call(getRoomName, room_id)
                                if not ok or not name or tostring(name) == "" then
                                        invalid_name_count = invalid_name_count + 1
                                end
                                if type(getRoomExits) == "function" then
                                        local exits_ok, exits = dd_mapper_call(getRoomExits, room_id)
                                        if exits_ok and type(exits) == "table" then
                                                for _, destination in pairs(exits) do
                                                        if not roomExists(destination) then
                                                                dangling_exit_count = dangling_exit_count + 1
                                                        end
                                                end
                                        end
                                end
                        end
                end

                mapper_echo(string.format(
                        "Audit: %d areas, %d rooms, %d coordinate overlaps, %d unnamed rooms, %d dangling exits.",
                        area_count, room_count, overlap_count, invalid_name_count, dangling_exit_count
                ))
                if overlap_count > 0 then
                        mapper_echo("Overlaps were reported only; no map data was changed.", true)
                end
        end

        local function configure()
                for _, terrain in pairs(terrain_types) do
                        if type(setCustomEnvColor) == "function" then
                                pcall(setCustomEnvColor, terrain.id, terrain.r, terrain.g, terrain.b, 255)
                        end
                end

                for _, alias_id in pairs(map.aliases) do
                        pcall(killAlias, alias_id)
                end
                map.aliases = {}
                table.insert(map.aliases, tempAlias([[^shift (\w+)$]], [[DD_GUI.mapper_shift(matches[2])]]))
                table.insert(map.aliases, tempAlias([[^make_room$]], [[DD_GUI.mapper_make_room()]]))
                register_mapper_menu()
        end

        DD_GUI.mapper_audit = audit_mapper

        function DD_GUI.mapper_make_room()
                local info = normalise_room_info(gmcp and gmcp.Room and gmcp.Room.Info)
                if not info then
                        mapper_echo("Current GMCP room data is incomplete.", true)
                        return false
                end
                map.prev_info = map.room_info or {}
                map.room_info = info
                local changed = reconcile_room(info)
                centerview(info.vnum)
                if changed and save_dd_mapper then
                        save_dd_mapper()
                end
                return changed
        end

        function map.eventHandler(event, ...)
                local args = {...}
                if event == "gmcp.Room.Info" then
                        local info = normalise_room_info(gmcp and gmcp.Room and gmcp.Room.Info)
                        if not info then
                                return
                        end

                        map.prev_info = map.room_info or {}
                        map.room_info = info
                        local changed, created = reconcile_room(info)
                        local current_area = room_area(info.vnum)
                        if current_area then
                                auto_fit_area(current_area)
                        end
                        centerview(info.vnum)

                        if state.route then
                                local route = state.route
                                if info.vnum == route.awaiting then
                                        route.index = route.index + 1
                                        route.last_room = info.vnum
                                        table.insert(route.visited, info.vnum)
                                        send_next_route_action()
                                elseif info.vnum ~= route.last_room then
                                        stop_route("Speedwalk stopped: route diverged from the mapped path.")
                                end
                        else
                                refresh_quest_marker()
                        end

                        if changed and save_dd_mapper then
                                save_dd_mapper()
                        end
                elseif event == "gmcp.Char.Quest" then
                        clear_highlights()
                        refresh_quest_marker()
                elseif event == "onMoveFail" then
                        if state.route then
                                stop_route("Speedwalk stopped because movement failed.")
                        end
                elseif event == "shiftRoom" then
                        DD_GUI.mapper_shift(args[1])
                elseif event == "sysConnectionEvent" then
                        configure()
                end
        end

        state.handlers.room = registerAnonymousEventHandler("gmcp.Room.Info", "map.eventHandler")
        state.handlers.shift = registerAnonymousEventHandler("shiftRoom", "map.eventHandler")
        state.handlers.connection = registerAnonymousEventHandler("sysConnectionEvent", "map.eventHandler")
        state.handlers.quest = registerAnonymousEventHandler("gmcp.Char.Quest", "map.eventHandler")
        state.handlers.move_fail = registerAnonymousEventHandler("onMoveFail", "map.eventHandler")

        configure()
        if gmcp and gmcp.Room and type(gmcp.Room.Info) == "table" then
                tempTimer(0.05, function()
                        if map and map.eventHandler then
                                map.eventHandler("gmcp.Room.Info")
                        end
                end)
        end
end
