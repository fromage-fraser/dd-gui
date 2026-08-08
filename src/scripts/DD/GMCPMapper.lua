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
                elseif text == "wall" or text == "blocked" then
                        return 4
                end
                return 0
        end

        local function normalise_exit(value)
                local result = {
                        to = nil,
                        status = nil,
                        has_status = false,
                        blocked = false,
                        door = nil,
                        command = nil,
                        cost = nil,
                }

                if type(value) == "table" then
                        result.to = dd_mapper_number(
                                value.to or value.vnum or value.room or value.id or value.destination
                        )
                        local raw_status = value.status or value.state or value.door_state
                        if raw_status ~= nil then
                                result.status = normalise_door_status(raw_status)
                                result.has_status = true
                                result.blocked = tostring(raw_status):lower() == "wall" or
                                        tostring(raw_status):lower() == "blocked"
                        end
                        result.door = value.door or value.door_name
                        result.command = value.command or value.move or value.keyword
                        result.cost = dd_mapper_number(value.cost or value.move_cost or value.weight)
                else
                        result.to = dd_mapper_number(value)
                end

                return result
        end

        local function normalise_tags(value)
                local tags = {}
                if type(value) == "string" then
                        for tag in value:lower():gmatch("[%w_%-]+") do
                                tags[tag] = true
                        end
                elseif type(value) == "table" then
                        for key, tag in pairs(value) do
                                if type(tag) == "string" then
                                        tags[tag:lower()] = true
                                elseif tag == true and type(key) == "string" then
                                        tags[key:lower()] = true
                                elseif type(tag) == "table" then
                                        local name = tag.name or tag.tag or tag.id
                                        if name then
                                                tags[tostring(name):lower()] = true
                                        end
                                end
                        end
                end
                return tags
        end

        local function merge_exit_detail(exits, direction, value)
                local short = short_direction(direction)
                if not direction_names[short] then
                        return
                end

                local detail = normalise_exit(value)
                local existing = exits[short] or {
                        to = nil,
                        status = nil,
                        has_status = false,
                        blocked = false,
                        door = nil,
                        command = nil,
                        cost = nil,
                }

                if detail.to then
                        existing.to = detail.to
                end
                if detail.has_status then
                        existing.status = detail.status
                        existing.has_status = true
                        existing.blocked = detail.blocked == true
                end
                if detail.door ~= nil then
                        existing.door = tostring(detail.door)
                end
                if detail.command ~= nil then
                        existing.command = tostring(detail.command)
                end
                if detail.cost ~= nil then
                        existing.cost = detail.cost
                end
                exits[short] = existing
        end

        local function normalise_special_exits(source)
                local result = {}
                if type(source) ~= "table" then
                        return result
                end

                for key, value in pairs(source) do
                        local detail = normalise_exit(value)
                        local command
                        if type(value) == "table" then
                                command = value.command or value.name or value.move or value.keyword or
                                        (type(key) == "string" and key or nil)
                        elseif type(key) == "string" then
                                command = key
                        end

                        if detail.to and command then
                                detail.command = tostring(command)
                                table.insert(result, detail)
                        end
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

                -- DD4 now sends exit_details beside the legacy exits object.
                -- Merge it rather than replacing exits so older payloads keep
                -- mapping exactly as before while rich state becomes authoritative.
                local exit_details = source.exit_details or source.exitDetails or source.exit_detail
                if type(exit_details) == "table" then
                        for direction, value in pairs(exit_details) do
                                merge_exit_detail(exits, direction, value)
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
                        tags = normalise_tags(source.tags),
                        exits = exits,
                        special_exits = normalise_special_exits(
                                source.special_exits or source.specialExits or source.special_exit_details
                        ),
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

        local function set_mapper_user_data(room_id, key, value)
                if type(setRoomUserData) ~= "function" then
                        return false
                end

                value = tostring(value or "")
                local old_value = ""
                if type(getRoomUserData) == "function" then
                        local ok, stored = dd_mapper_call(getRoomUserData, room_id, key)
                        if ok then
                                old_value = tostring(stored or "")
                        end
                end

                if old_value == value then
                        return false
                end
                pcall(setRoomUserData, room_id, key, value)
                return true
        end

        local function set_mapper_area_data(area_id, key, value)
                if type(setAreaUserData) ~= "function" then
                        return false
                end

                value = tostring(value or "")
                local old_value = ""
                if type(getAreaUserData) == "function" then
                        local ok, stored = dd_mapper_call(getAreaUserData, area_id, key)
                        if ok then
                                old_value = tostring(stored or "")
                        end
                end

                if old_value == value then
                        return false
                end
                pcall(setAreaUserData, area_id, key, value)
                return true
        end

        local function update_area_metadata(area_id, info)
                if not area_id or not info then
                        return false
                end

                local changed = false
                local managed_name = ""
                if type(getAreaUserData) == "function" then
                        local ok, stored = dd_mapper_call(
                                getAreaUserData, area_id, "dd_gui.server_area_name"
                        )
                        if ok then
                                managed_name = tostring(stored or "")
                        end
                end
                if info.area_id then
                        changed = set_mapper_area_data(
                                area_id, "dd_gui.server_area_id", info.area_id
                        ) or changed
                end
                changed = set_mapper_area_data(
                        area_id, "dd_gui.server_area_name", info.area
                ) or changed

                -- A server area rename should follow the stable area_id, but
                -- an area a player has deliberately renamed must remain theirs.
                if type(setAreaName) == "function" and type(getAreaTable) == "function" then
                        local current_name
                        for candidate_name, candidate_id in pairs(getAreaTable() or {}) do
                                if tonumber(candidate_id) == tonumber(area_id) then
                                        current_name = tostring(candidate_name)
                                        break
                                end
                        end
                        if current_name and current_name ~= info.area
                        and (managed_name == "" or managed_name == current_name) then
                                local ok = pcall(setAreaName, area_id, info.area)
                                changed = ok or changed
                        end
                end
                return changed
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
                                        update_area_metadata(tonumber(candidate_id), info)
                                        return tonumber(candidate_id)
                                end
                        end
                end

                local area_id = areas and areas[name]
                if area_id then
                        local existing_server_id
                        if info and info.area_id and type(getAreaUserData) == "function" then
                                local stored_ok, stored = dd_mapper_call(
                                        getAreaUserData, area_id, "dd_gui.server_area_id"
                                )
                                if stored_ok and tostring(stored or "") ~= "" then
                                        existing_server_id = tonumber(stored)
                                end
                        end
                        if existing_server_id and existing_server_id ~= tonumber(info.area_id) then
                                local scoped_name = string.format(
                                        "%s [%s]", name, tostring(info.area_id)
                                )
                                local scoped_ok, scoped_id = dd_mapper_call(
                                        addAreaName, scoped_name
                                )
                                if scoped_ok and scoped_id then
                                        update_area_metadata(tonumber(scoped_id), info)
                                        return tonumber(scoped_id)
                                end
                        end
                        update_area_metadata(tonumber(area_id), info)
                        return tonumber(area_id)
                end

                local ok, added = dd_mapper_call(addAreaName, name)
                if ok and added then
                        update_area_metadata(tonumber(added), info)
                        return tonumber(added)
                end

                areas = getAreaTable()
                area_id = areas and tonumber(areas[name]) or nil
                update_area_metadata(area_id, info)
                return area_id
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

        local function serialise_exit_details(exits)
                local parts = {}
                for direction, exit in pairs(exits or {}) do
                        if exit.to then
                                local door = tostring(exit.door or "")
                                local command = tostring(exit.command or "")
                                door = door:gsub("%%", "%%25"):gsub("[|,]", function(value)
                                        return value == "|" and "%%7C" or "%%2C"
                                end)
                                command = command:gsub("%%", "%%25"):gsub("[|,]", function(value)
                                        return value == "|" and "%%7C" or "%%2C"
                                end)
                                table.insert(parts, string.format(
                                        "%s=%s,%s,%s,%s,%s",
                                        direction,
                                        tostring(exit.status or 0),
                                        tostring(exit.has_status and 1 or 0),
                                        tostring(exit.cost or ""),
                                        door,
                                        command
                                ))
                        end
                end
                table.sort(parts)
                return table.concat(parts, ";")
        end

        local function serialise_special_exits(exits)
                local parts = {}
                for _, exit in ipairs(exits or {}) do
                        if exit.to and exit.command then
                                local command = tostring(exit.command)
                                command = command:gsub("%%", "%%25"):gsub("[|=]", function(value)
                                        return value == "|" and "%%7C" or "%%3D"
                                end)
                                table.insert(parts, string.format(
                                        "%s=%s,%s,%s",
                                        command,
                                        tostring(exit.to),
                                        tostring(exit.status or 0),
                                        tostring(exit.cost or "")
                                ))
                        end
                end
                table.sort(parts)
                return table.concat(parts, ";")
        end

        local function room_flag_text(info)
                if type(info.flags) == "string" then
                        return info.flags:lower()
                elseif type(info.flags) == "table" then
                        local parts = {}
                        for key, flag in pairs(info.flags) do
                                if type(flag) == "string" then
                                        table.insert(parts, flag:lower())
                                elseif flag == true and type(key) == "string" then
                                        table.insert(parts, key:lower())
                                end
                        end
                        return table.concat(parts, " ")
                end
                return ""
        end

        local function set_room_metadata(info, area_id)
                pcall(setRoomName, info.vnum, info.name)
                pcall(setRoomArea, info.vnum, area_id)

                local changed = false
                changed = set_mapper_user_data(info.vnum, "dd_gui.area_id", info.area_id) or changed
                changed = set_mapper_user_data(info.vnum, "dd_gui.area", info.area) or changed
                changed = set_mapper_user_data(info.vnum, "dd_gui.sector", info.sector) or changed
                changed = set_mapper_user_data(info.vnum, "dd_gui.sector_text", info.sector_text) or changed
                changed = set_mapper_user_data(info.vnum, "dd_gui.flags", room_flag_text(info)) or changed

                local tag_names = {}
                for tag in pairs(info.tags or {}) do
                        table.insert(tag_names, tag)
                end
                table.sort(tag_names)
                changed = set_mapper_user_data(
                        info.vnum, "dd_gui.tags", table.concat(tag_names, ",")
                ) or changed
                if info.description ~= "" then
                        -- Keep room notes useful without allowing a malformed
                        -- payload to make the persistent map unbounded.
                        local description = info.description:sub(1, 4096)
                        changed = set_mapper_user_data(
                                info.vnum, "dd_gui.description", description
                        ) or changed
                end

                local terrain = terrain_types[info.sector]
                if terrain and type(setRoomEnv) == "function" then
                        pcall(setRoomEnv, info.vnum, terrain.id)
                        if type(setCustomEnvColor) == "function" then
                                pcall(setCustomEnvColor, terrain.id, terrain.r, terrain.g, terrain.b, 255)
                        end
                end
                return changed
        end

        local function set_exit_door(room_id, direction, status, present)
                local short = short_direction(direction)
                local native_door_directions = {
                        n = true, ne = true, nw = true, e = true,
                        w = true, s = true, se = true, sw = true,
                }
                if present and native_door_directions[short] and type(setDoor) == "function" then
                        local native_status = math.max(0, math.min(3, tonumber(status) or 0))
                        pcall(setDoor, room_id, short, native_status)
                end
        end

        local function sync_room_exits(info, created)
                local previous = {}
                local previous_serialised = ""
                local changed = false
                if type(getRoomUserData) == "function" then
                        local ok, value = dd_mapper_call(getRoomUserData, info.vnum, "dd_gui.exits")
                        if ok then
                                previous_serialised = tostring(value or "")
                                previous = parse_serialised_exits(value)
                        end
                end

                DD_GUI.exit_status_by_room = DD_GUI.exit_status_by_room or {}
                DD_GUI.exit_status_by_room[info.vnum] = DD_GUI.exit_status_by_room[info.vnum] or {}
                for direction, exit in pairs(info.exits) do
                        if exit.blocked then
                                pcall(setExitStub, info.vnum, direction, true)
                                pcall(setExit, info.vnum, -1, direction)
                        elseif exit.to and roomExists(exit.to) then
                                pcall(setExit, info.vnum, exit.to, direction)
                        else
                                pcall(setExitStub, info.vnum, direction, true)
                        end
                        if exit.has_status then
                                DD_GUI.exit_status_by_room[info.vnum][direction] = exit.status
                                local native_status = exit.status
                                -- DD4 reports every traversable exit as
                                -- state=open. Only draw an open native door
                                -- when the exit actually has a door keyword;
                                -- closed and locked exits remain visible even
                                -- when the MUD leaves that keyword blank.
                                if exit.status == 1 and
                                        tostring(exit.door or "") == "" then
                                        native_status = 0
                                end
                                set_exit_door(info.vnum, direction, native_status, true)
                        end
                        if exit.cost and type(setExitWeight) == "function" then
                                local cost_weight = math.max(0, math.floor(exit.cost) - 1)
                                pcall(setExitWeight, info.vnum, direction, cost_weight)
                                changed = set_mapper_user_data(
                                        info.vnum, "dd_gui.exit_cost." .. direction, exit.cost
                                ) or changed
                        elseif type(getRoomUserData) == "function" then
                                local cost_ok, old_cost = dd_mapper_call(
                                        getRoomUserData, info.vnum, "dd_gui.exit_cost." .. direction
                                )
                                if cost_ok and tostring(old_cost or "") ~= "" then
                                        if type(setExitWeight) == "function" then
                                                pcall(setExitWeight, info.vnum, direction, 0)
                                        end
                                        changed = set_mapper_user_data(
                                                info.vnum, "dd_gui.exit_cost." .. direction, ""
                                        ) or changed
                        end
                        end
                        if exit.door ~= nil then
                                changed = set_mapper_user_data(
                                        info.vnum, "dd_gui.door_name." .. direction, exit.door
                                ) or changed
                        end
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
                                                if special.cost and type(setExitWeight) == "function" then
                                                        pcall(setExitWeight, info.vnum, tostring(command),
                                                                math.max(0, math.floor(special.cost) - 1))
                                                end
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
                                        DD_GUI.exit_status_by_room[info.vnum][direction] = nil
                                        set_exit_door(info.vnum, direction, 0, true)
                                        if type(getRoomUserData) == "function" then
                                                local cost_ok, old_cost = dd_mapper_call(
                                                        getRoomUserData, info.vnum,
                                                        "dd_gui.exit_cost." .. direction
                                                )
                                                if cost_ok and tostring(old_cost or "") ~= "" then
                                                        if type(setExitWeight) == "function" then
                                                                pcall(setExitWeight, info.vnum, direction, 0)
                                                        end
                                                        changed = set_mapper_user_data(
                                                                info.vnum, "dd_gui.exit_cost." .. direction, ""
                                                        ) or changed
                                                end
                                        end
                                end
                        end
                end

                local current_serialised = serialise_exits(info.exits)
                if previous_serialised ~= current_serialised then
                        changed = set_mapper_user_data(
                                info.vnum, "dd_gui.exits", current_serialised
                        ) or changed
                end

                changed = set_mapper_user_data(
                        info.vnum, "dd_gui.exit_details", serialise_exit_details(info.exits)
                ) or changed
                changed = set_mapper_user_data(
                        info.vnum, "dd_gui.special_exits", serialise_special_exits(info.special_exits)
                ) or changed
                return changed
        end

        local function apply_room_semantics(info)
                if not map.configs.dd_room_symbols or type(setRoomChar) ~= "function" then
                        return false
                end

                local function has_tag(tag)
                        return info.tags and info.tags[tag] == true
                end

                local flags = room_flag_text(info)
                local symbol
                if has_tag("danger") or flags:find("death") or
                        flags:find("no recall") or flags:find("no_recall") then
                        symbol = "!"
                elseif has_tag("questmaster") or flags:find("quest") then
                        symbol = "Q"
                elseif has_tag("bank") then
                        symbol = "B"
                elseif has_tag("trainer") or flags:find("trainer") then
                        symbol = "T"
                elseif has_tag("healer") or flags:find("healer") then
                        symbol = "H"
                elseif has_tag("shop") or flags:find("shop") or flags:find("store") then
                        symbol = "$"
                elseif has_tag("arena") then
                        symbol = "A"
                elseif has_tag("vault") then
                        symbol = "V"
                elseif has_tag("craft") or has_tag("spellcraft") then
                        symbol = "C"
                elseif has_tag("safe") or flags:find("safe") then
                        symbol = "S"
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

                if not symbol then
                        if owned then
                                pcall(setRoomChar, info.vnum, " ")
                                set_mapper_user_data(info.vnum, "dd_gui.symbol", "")
                                return true
                        end
                        return false
                end

                local changed = false
                if existing == "" or owned then
                        pcall(setRoomChar, info.vnum, symbol)
                        if type(setRoomCharColor) == "function" then
                                local colours = {
                                        ["!"] = {220, 40, 45},
                                        Q = {210, 170, 45}, B = {80, 180, 220},
                                        T = {90, 210, 110}, H = {110, 220, 220},
                                        ["$"] = {230, 190, 50}, A = {220, 90, 120},
                                        V = {180, 110, 230}, C = {100, 190, 230},
                                        S = {100, 220, 120},
                                }
                                local colour = colours[symbol] or {210, 170, 45}
                                pcall(setRoomCharColor, info.vnum, colour[1], colour[2], colour[3])
                        end
                        changed = set_mapper_user_data(info.vnum, "dd_gui.symbol", symbol) or changed
                end
                return changed or existing ~= symbol
        end

        local function arrival_is_spatial(arrival)
                if type(arrival) ~= "table" then
                        return true
                end

                local kind = tostring(arrival.kind or ""):lower()
                return kind == "" or kind == "walk" or kind == "climb" or kind == "other"
        end

        local function placement_for(info, area_id)
                local arrival = info.arrival
                local previous_id = arrival and dd_mapper_number(
                        arrival.from or arrival.from_vnum or arrival.previous
                )
                previous_id = previous_id or dd_mapper_number(map.prev_info and map.prev_info.vnum)
                local previous_coords = previous_id and room_coordinates(previous_id)
                local previous_area = previous_id and room_area(previous_id)
                local base

                if previous_coords and previous_area == area_id then
                        local arrival_direction = arrival and (arrival.direction or arrival.dir or arrival.command)
                        local arrival_vector = direction_vector(arrival_direction)
                        if arrival_vector and arrival_is_spatial(arrival) then
                                base = {
                                        previous_coords[1] + arrival_vector[1],
                                        previous_coords[2] + arrival_vector[2],
                                        previous_coords[3] + arrival_vector[3],
                                }
                        elseif arrival_is_spatial(arrival) then
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
                        else
                                -- A recall, portal, teleport, or immortal
                                -- transfer is not a directional map edge. Keep
                                -- the destination visibly separate instead of
                                -- inventing an adjacent room relationship.
                                base = {
                                        previous_coords[1] + 3,
                                        previous_coords[2] + 3,
                                        previous_coords[3],
                                }
                        end
                end

                base = base or {0, 0, 0}
                return free_coordinates(area_id, base, info.vnum)
        end

        local function sync_arrival_link(info)
                local arrival = info.arrival
                if not arrival or not arrival_is_spatial(arrival) or
                        type(setExit) ~= "function" then
                        return false
                end

                local from_room = dd_mapper_number(
                        arrival.from or arrival.from_vnum or arrival.previous
                )
                local direction = short_direction(
                        arrival.direction or arrival.dir or arrival.command
                )
                if not from_room or not direction_names[direction] or
                        not roomExists(from_room) or not roomExists(info.vnum) then
                        return false
                end

                local checked = false
                if type(getRoomExits) == "function" then
                        local exits_ok, exits = dd_mapper_call(getRoomExits, from_room)
                        if exits_ok and type(exits) == "table" then
                                checked = true
                                local current = exits[direction] or exits[long_direction(direction)]
                                if tonumber(current) == tonumber(info.vnum) then
                                        return false
                                end
                        end
                end

                pcall(setExit, from_room, info.vnum, direction)
                return checked
        end

        local function create_room(info, area_id)
                local coordinates, displaced = placement_for(info, area_id)
                local add_ok, added = pcall(addRoom, info.vnum, area_id)
                if not add_ok or added == false then
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
                local metadata_changed = false
                local area_id = area_id_for(info)
                if not area_id then
                        return false, false
                end

                if created then
                        create_room(info, area_id)
                else
                        metadata_changed = set_room_metadata(info, area_id)
                end

                local exits_changed = sync_room_exits(info, created)
                local arrival_link_changed = sync_arrival_link(info)
                local semantics_changed = apply_room_semantics(info)
                return created or metadata_changed or exits_changed or
                        arrival_link_changed or semantics_changed, created
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
                if status == 4 then
                        return {}
                elseif status == 3 then
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
                local commands = movement_commands(action.from, action.direction)
                if #commands == 0 then
                        stop_route("Speedwalk stopped: the next exit is a wall.")
                        return
                end
                for index, command in ipairs(commands) do
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
                DD_GUI.exit_status_by_room = DD_GUI.exit_status_by_room or {}
                DD_GUI.exit_status_by_room[room_id] = DD_GUI.exit_status_by_room[room_id] or {}
                for direction, status in pairs(statuses) do
                        local short = short_direction(direction)
                        local numeric_status = tonumber(status) or 0
                        DD_GUI.exit_status_by_room[room_id][short] = numeric_status
                        set_exit_door(room_id, short, numeric_status, true)
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

        function DD_GUI.mapper_show_room_details(room_id)
                room_id = tonumber(room_id) or (map.room_info and tonumber(map.room_info.vnum))
                if not room_id or not roomExists(room_id) then
                        mapper_echo("No mapped room is available to inspect.", true)
                        return false
                end

                local name = room_id
                if type(getRoomName) == "function" then
                        local ok, value = dd_mapper_call(getRoomName, room_id)
                        if ok and value and tostring(value) ~= "" then
                                name = tostring(value)
                        end
                end
                mapper_echo("Room " .. tostring(room_id) .. ": " .. tostring(name))

                local data = {}
                if type(getAllRoomUserData) == "function" then
                        local ok, value = dd_mapper_call(getAllRoomUserData, room_id)
                        if ok and type(value) == "table" then
                                data = value
                        end
                end

                local keys = {}
                for key in pairs(data) do
                        if tostring(key):match("^dd_gui%.") then
                                table.insert(keys, tostring(key))
                        end
                end
                table.sort(keys)
                for _, key in ipairs(keys) do
                        local value = tostring(data[key] or ""):gsub("[\r\n]+", " ")
                        mapper_echo("  " .. key .. " = " .. value)
                end

                local statuses = DD_GUI.exit_status_by_room and DD_GUI.exit_status_by_room[room_id]
                if statuses then
                        local status_names = {[0] = "none", [1] = "open", [2] = "closed", [3] = "locked"}
                        local directions = {}
                        for direction in pairs(statuses) do
                                table.insert(directions, direction)
                        end
                        table.sort(directions)
                        for _, direction in ipairs(directions) do
                                mapper_echo(string.format(
                                        "  exit %s = %s",
                                        direction,
                                        status_names[tonumber(statuses[direction]) or 0] or "unknown"
                                ))
                        end
                end
                return true
        end

        local function selected_rooms()
                if type(getMapSelection) ~= "function" then
                        return {}
                end
                local ok, selection = dd_mapper_call(getMapSelection)
                return ok and type(selection) == "table" and selection.rooms or {}
        end

        local function area_name(area_id)
                if type(getRoomAreaName) == "function" then
                        local ok, name = dd_mapper_call(getRoomAreaName, area_id)
                        if ok and name then
                                return tostring(name)
                        end
                end
                for name, candidate_id in pairs(getAreaTable() or {}) do
                        if tonumber(candidate_id) == tonumber(area_id) then
                                return tostring(name)
                        end
                end
                return "unknown area"
        end

        local function selected_area(rooms)
                local selected_area_id
                for _, room_id in ipairs(rooms or {}) do
                        room_id = tonumber(room_id)
                        if room_id and roomExists(room_id) then
                                local current_area = room_area(room_id)
                                if current_area then
                                        if selected_area_id and selected_area_id ~= current_area then
                                                return nil, "Select rooms from only one area."
                                        end
                                        selected_area_id = current_area
                                end
                        end
                end

                if not selected_area_id and map.room_info and map.room_info.vnum then
                        selected_area_id = room_area(tonumber(map.room_info.vnum))
                end
                return selected_area_id
        end

        local function clear_pending_area_reset()
                local pending = state.pending_area_reset
                if pending and pending.timer then
                        pcall(killTimer, pending.timer)
                end
                state.pending_area_reset = nil
        end

        local function request_area_reset(area_id)
                if type(deleteArea) ~= "function" and type(deleteRoom) ~= "function" then
                        mapper_echo("This Mudlet version cannot remove mapped areas.", true)
                        return false
                end

                area_id = tonumber(area_id)
                if not area_id then
                        mapper_echo("No mapped area was selected.", true)
                        return false
                end

                local rooms = {}
                if type(getAreaRooms) == "function" then
                        local ok, result = dd_mapper_call(getAreaRooms, area_id)
                        if ok and type(result) == "table" then
                                rooms = result
                        end
                end

                clear_pending_area_reset()
                state.pending_area_reset = {
                        area_id = area_id,
                        room_count = #rooms,
                        area_name = area_name(area_id),
                }
                local pending = state.pending_area_reset
                pending.timer = tempTimer(60, function()
                        if state.pending_area_reset == pending then
                                clear_pending_area_reset()
                                mapper_echo("Area reset confirmation expired.", true)
                        end
                end)

                mapper_echo(string.format(
                        "Reset %s and remove all %d mapped rooms?",
                        pending.area_name, pending.room_count
                ), true)

                if type(createComposer) == "function" then
                        local composer_call_ok, composer_opened = dd_mapper_call(
                                createComposer,
                                "Reset mapper area: " .. pending.area_name,
                                "",
                                function(text, saved)
                                        if not saved then
                                                DD_GUI.mapper_cancel_area_reset()
                                        elseif tostring(text or ""):match("^%s*RESET%s*$") then
                                                DD_GUI.mapper_confirm_area_reset(area_id)
                                        else
                                                mapper_echo("Type RESET in the confirmation dialog to clear this area.", true)
                                        end
                                end
                        )
                        if composer_call_ok and composer_opened then
                                return true
                        end
                end

                if type(cechoLink) == "function" then
                        cechoLink(
                                "main",
                                "<red>[CONFIRM RESET]<reset>",
                                "DD_GUI.mapper_confirm_area_reset(" .. tostring(area_id) .. ")",
                                "Remove every mapped room in this area",
                                true
                        )
                        cecho("main", "  ")
                        cechoLink(
                                "main",
                                "<white>[CANCEL]<reset>",
                                "DD_GUI.mapper_cancel_area_reset()",
                                "Cancel area reset",
                                true
                        )
                        cecho("main", "\n")
                else
                        mapper_echo("Type 'ddmap reset' to confirm, or 'ddmap cancel' to cancel.", true)
                end
                return true
        end

        function DD_GUI.mapper_cancel_area_reset()
                if state.pending_area_reset then
                        clear_pending_area_reset()
                        mapper_echo("Area reset cancelled.")
                end
        end

        function DD_GUI.mapper_confirm_area_reset(area_id)
                local pending = state.pending_area_reset
                if not pending or tonumber(pending.area_id) ~= tonumber(area_id) then
                        mapper_echo("That area reset confirmation has expired.", true)
                        return false
                end

                clear_pending_area_reset()
                local current_room = map.room_info and tonumber(map.room_info.vnum)
                local current_area = current_room and room_area(current_room)
                local rooms = {}
                if type(getAreaRooms) == "function" then
                        local ok, result = dd_mapper_call(getAreaRooms, area_id)
                        if ok and type(result) == "table" then
                                rooms = result
                        end
                end
                for _, room_id in ipairs(rooms) do
                        if DD_GUI.exit_status_by_room then
                                DD_GUI.exit_status_by_room[tonumber(room_id)] = nil
                        end
                end

                stop_route()
                local success = false
                local error_message
                if type(deleteArea) == "function" then
                        local ok, result, err = dd_mapper_call(deleteArea, area_id)
                        success = ok and result == true
                        error_message = err or result
                elseif type(deleteRoom) == "function" then
                        success = true
                        for _, room_id in ipairs(rooms) do
                                local ok, result = dd_mapper_call(deleteRoom, room_id)
                                if not ok or result == false then
                                        success = false
                                        error_message = result
                                        break
                                end
                        end
                end

                if not success then
                        mapper_echo("Could not reset " .. pending.area_name .. ": " .. tostring(error_message or "unknown error") .. ".", true)
                        return false
                end

                state.zoom_seen[tostring(area_id)] = nil
                clear_highlights()
                if type(clearMapSelection) == "function" then
                        pcall(clearMapSelection)
                end
                if current_area == tonumber(area_id) then
                        map.prev_info = {}
                        map.room_info = {}
                end
                if type(updateMap) == "function" then
                        pcall(updateMap)
                end
                if save_dd_mapper then
                        pcall(save_dd_mapper)
                end
                mapper_echo(string.format(
                        "Reset %s; removed %d mapped rooms. Move or look to begin remapping it.",
                        pending.area_name, #rooms
                ))
                return true
        end

        function DD_GUI.mapper_confirm_pending_area_reset()
                local pending = state.pending_area_reset
                if not pending then
                        mapper_echo("There is no pending area reset.", true)
                        return false
                end
                return DD_GUI.mapper_confirm_area_reset(pending.area_id)
        end

        local function handle_reset_area_menu()
                local rooms = selected_rooms()
                local area_id, error_message = selected_area(rooms)
                if not area_id then
                        mapper_echo(error_message or "No mapped area was selected.", true)
                else
                        request_area_reset(area_id)
                end
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
                elseif action == "details" then
                        DD_GUI.mapper_show_room_details(rooms[1])
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
                elseif action == "reset_area" then
                        local area_id, error_message = selected_area(rooms)
                        if not area_id then
                                mapper_echo(error_message or "No mapped area was selected.", true)
                        else
                                request_area_reset(area_id)
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
                if state.handlers.reset_area then
                        pcall(killAnonymousEventHandler, state.handlers.reset_area)
                        state.handlers.reset_area = nil
                end
                pcall(removeMapMenu, "DD_GUI.Mapper")
                pcall(addMapMenu, "DD_GUI.Mapper", nil, "DD_GUI")
                local entries = {
                        {"fit", "Fit current area"},
                        {"center", "Centre on player"},
                        {"route", "Route to selected room"},
                        {"quest", "Show quest destination"},
                        {"details", "Show DD4 room data"},
                        {"avoid", "Avoid selected rooms"},
                        {"allow", "Allow selected rooms"},
                }
                for _, entry in ipairs(entries) do
                        pcall(removeMapEvent, "DD_GUI.Mapper." .. entry[1])
                        pcall(addMapEvent, "DD_GUI.Mapper." .. entry[1],
                                "DD_GUI.MapperMenu", "DD_GUI.Mapper", entry[2], entry[1])
                end
                pcall(removeMapEvent, "DD_GUI.Mapper.reset_area")
                pcall(addMapEvent, "DD_GUI.Mapper.reset_area",
                        "DD_GUI.MapperResetArea", "DD_GUI.Mapper",
                        "Reset selected area's rooms")
                state.handlers.menu = registerAnonymousEventHandler("DD_GUI.MapperMenu", handle_mapper_menu)
                state.handlers.reset_area = registerAnonymousEventHandler(
                        "DD_GUI.MapperResetArea", handle_reset_area_menu
                )
        end

        local function audit_mapper()
                local area_count = 0
                local room_count = 0
                local overlap_count = 0
                local invalid_name_count = 0
                local dangling_exit_count = 0
                local rich_room_count = 0
                local tagged_room_count = 0
                local door_count = 0
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
                                if type(getRoomUserData) == "function" then
                                        local details_ok, details = dd_mapper_call(
                                                getRoomUserData, room_id, "dd_gui.exit_details"
                                        )
                                        if details_ok and tostring(details or "") ~= "" then
                                                rich_room_count = rich_room_count + 1
                                        end
                                        local tags_ok, tags = dd_mapper_call(
                                                getRoomUserData, room_id, "dd_gui.tags"
                                        )
                                        if tags_ok and tostring(tags or "") ~= "" then
                                                tagged_room_count = tagged_room_count + 1
                                        end
                                end
                                if type(getDoors) == "function" then
                                        local doors_ok, doors = dd_mapper_call(getDoors, room_id)
                                        if doors_ok and type(doors) == "table" then
                                                for _, status in pairs(doors) do
                                                        if tonumber(status) and tonumber(status) > 0 then
                                                                door_count = door_count + 1
                                                        end
                                                end
                                        end
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
                        "Audit: %d areas, %d rooms, %d overlaps, %d unnamed, %d dangling exits, %d rich rooms, %d tagged rooms, %d doors.",
                        area_count, room_count, overlap_count, invalid_name_count,
                        dangling_exit_count, rich_room_count, tagged_room_count, door_count
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
