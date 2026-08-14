DD_GUI = DD_GUI or {}

DD_GUI.exit_status_by_room = DD_GUI.exit_status_by_room or {}
DD_GUI.exit_status_meta_by_room = DD_GUI.exit_status_meta_by_room or {}

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

local function copy_statuses(statuses)
        local copy = {}
        for direction, status in pairs(statuses or {}) do
                local short = compass_exit_aliases[tostring(direction):lower()]
                if short then
                        copy[short] = tonumber(status) or 0
                end
        end
        return copy
end

local function truthy(value)
        if value == true or value == 1 then
                return true
        end
        local text = tostring(value or ""):lower()
        return text == "true" or text == "yes" or text == "on" or text == "1"
end

local function decode_table(value)
        if type(value) ~= "string" then
                return value
        end

        local text = value:gsub("^%s+", ""):gsub("%s+$", "")
        if text == "" then
                return nil
        end

        -- Mudlet normally exposes nested GMCP objects as tables. Keep a
        -- guarded fallback for profiles or protocol bridges that leave an
        -- object as its JSON string instead.
        if type(json) == "table" and type(json.decode) == "function" then
                local ok, decoded = pcall(json.decode, text)
                if ok and type(decoded) == "table" then
                        return decoded
                end
        end
        if type(decodeJson) == "function" then
                local ok, decoded = pcall(decodeJson, text)
                if ok and type(decoded) == "table" then
                        return decoded
                end
        end
        return value
end

local function normalise_status(value)
        value = decode_table(value)
        if type(value) == "table" then
                if truthy(value.wall) or truthy(value.blocked) then
                        return 4
                elseif truthy(value.locked) or truthy(value.is_locked) or
                       truthy(value.isLocked) then
                        return 3
                elseif truthy(value.closed) or truthy(value.is_closed) or
                       truthy(value.isClosed) then
                        return 2
                elseif truthy(value.open) or truthy(value.is_open) or
                       truthy(value.isOpen) then
                        return 1
                end
                value = value.status or value.state or value.door_state or
                        value.door_status or value.exit_state
        end

        local numeric = tonumber(value)
        if numeric then
                return math.max(0, math.min(4, math.floor(numeric)))
        end

        local text = tostring(value or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
        if text == "wall" or text == "blocked" then
                return 4
        elseif text == "locked" or text == "lock" then
                return 3
        elseif text == "closed" or text == "close" then
                return 2
        elseif text == "open" or text == "opened" then
                return 1
        end
        return nil
end

local function current_room_id()
        -- GMCP is the freshest source during a room transition. The mapper
        -- cache can be one event behind while the room text is still arriving.
        if gmcp and gmcp.Room and type(gmcp.Room.Info) == "table" then
                local room_id = tonumber(gmcp.Room.Info.vnum)
                if room_id then
                        return room_id
                end
        end

        if type(map) == "table" and type(map.room_info) == "table" then
                return tonumber(map.room_info.vnum)
        end

        return nil
end

local function gmcp_exit_statuses(info)
        if type(info) ~= "table" then
                return {}, false
        end

        local statuses = {}
        local rich_sources = {}
        local fallback_sources = {}
        local has_rich_status = false

        local function add_source(collection, source)
                source = decode_table(source)
                if type(source) == "table" then
                        table.insert(collection, source)
                end
        end

        local function add_rich_source(source)
                source = decode_table(source)
                if type(source) ~= "table" then
                        return
                end

                -- Accept both a direction-keyed object and a wrapper used by
                -- a few GMCP bridges (`{ exits = { ... } }`).
                local nested = source.exit_details or source.exitDetails or
                        source.exit_detail or source.exits or source.data
                add_source(rich_sources, nested or source)
        end

        add_rich_source(info.exit_details or info.exitDetails or info.exit_detail)
        if gmcp and gmcp.Room then
                add_rich_source(gmcp.Room.ExitDetails or gmcp.Room.exit_details or
                        gmcp.Room.exitDetails or gmcp.Room.ExitDetail)
        end
        add_source(fallback_sources, info.exits)
        if gmcp and gmcp.Room then
                add_source(fallback_sources, gmcp.Room.Exits or gmcp.Room.exits)
        end

        local has_rich_payload = #rich_sources > 0

        local function read(source, allow_scalar)
                source = decode_table(source)
                if type(source) ~= "table" then
                        return
                end
                for direction, value in pairs(source) do
                        -- Room.Info.exits is historically a direction -> room
                        -- id table. Only its nested rich form may contribute
                        -- a scalar state; otherwise a destination such as
                        -- "3025" would look like a blocked status.
                        value = decode_table(value)
                        if not allow_scalar and type(value) ~= "table" then
                                value = nil
                        end
                        local short = compass_exit_aliases[tostring(direction):lower()]
                        if not short and type(value) == "table" then
                                local embedded_direction = value.direction or value.dir or
                                        value.name or value.exit or value.command
                                short = compass_exit_aliases[
                                        tostring(embedded_direction or ""):lower()
                                ]
                        end
                        local status = short and normalise_status(value)
                        if short and status ~= nil then
                                statuses[short] = status
                                has_rich_status = true
                        end
                end
        end

        for _, source in ipairs(rich_sources) do
                read(source, true)
        end

        -- Keep compatibility with a future/alternate Room.Info shape that
        -- embeds state directly in `exits` instead of `exit_details`.
        if not has_rich_status then
                for _, source in ipairs(fallback_sources) do
                        read(source, false)
                end
        end

        -- DD4 sends exit_details as a complete object, including an empty
        -- object for a room with no traversable exits. An empty rich object
        -- is authoritative only when there is no legacy exit list alongside
        -- it; otherwise preserve the text/native fallback for partial GMCP.
        local has_legacy_exits = false
        for _, source in ipairs(fallback_sources) do
                for direction, value in pairs(source) do
                        local short = compass_exit_aliases[tostring(direction):lower()]
                        if not short and type(value) == "table" then
                                local embedded_direction = value.direction or value.dir or
                                        value.name or value.exit or value.command
                                short = compass_exit_aliases[
                                        tostring(embedded_direction or ""):lower()
                                ]
                        end
                        if short then
                                has_legacy_exits = true
                                break
                        end
                end
                if has_legacy_exits then
                        break
                end
        end

        local complete = has_rich_status or
                (has_rich_payload and not has_legacy_exits)
        return statuses, complete
end

DD_GUI.get_gmcp_exit_statuses = gmcp_exit_statuses

local function apply_statuses(room_id, statuses, source, complete)
        room_id = tonumber(room_id)
        if not room_id or type(statuses) ~= "table" then
                return false
        end

        local metadata = DD_GUI.exit_status_meta_by_room[room_id]
        if source == "text" and metadata and metadata.source == "gmcp" and
           metadata.complete then
                -- The legacy [Exits: ...] line must never overwrite DD4's
                -- richer, authoritative door state.
                return false
        end

        local previous = DD_GUI.exit_status_by_room[room_id]
        local normalised = {}
        if complete == true then
                normalised = copy_statuses(statuses)
        else
                normalised = copy_statuses(previous)
                for direction, status in pairs(copy_statuses(statuses)) do
                        normalised[direction] = status
                end
        end
        DD_GUI.exit_status_by_room[room_id] = normalised
        DD_GUI.exit_status_meta_by_room[room_id] = {
                source = source or "unknown",
                complete = complete == true,
        }
        DD_GUI.exit_status_room = room_id

        if DD_GUI.mapper_set_exit_status then
                pcall(
                        DD_GUI.mapper_set_exit_status,
                        room_id,
                        normalised,
                        source ~= "gmcp",
                        complete == true,
                        previous
                )
        end
        return true
end

-- GMCPMapper uses this same path when it reconciles a fresh Room.Info
-- snapshot. Keep it public so the mapper and the compass cannot drift apart.
DD_GUI.apply_exit_status = apply_statuses

local function clear_pending_exit_move()
        if DD_GUI.exit_move_timer and type(killTimer) == "function" then
                pcall(killTimer, DD_GUI.exit_move_timer)
        end
        DD_GUI.exit_move_timer = nil
        DD_GUI.pending_exit_move = nil
end

function DD_GUI.note_exit_move(direction, room_id)
        local short = compass_exit_aliases[tostring(direction or ""):lower()]
        local source_room = tonumber(room_id) or current_room_id()
        if not short or not source_room then
                return false
        end

        clear_pending_exit_move()
        DD_GUI.pending_exit_move = {
                room_id = source_room,
                direction = short,
        }
        if type(tempTimer) == "function" then
                DD_GUI.exit_move_timer = tempTimer(3, function()
                        clear_pending_exit_move()
                end)
        end
        return true
end

function DD_GUI.clear_pending_exit_move(current_room)
        local pending = DD_GUI.pending_exit_move
        if not pending then
                return
        end
        if current_room == nil or tonumber(current_room) ~= pending.room_id then
                clear_pending_exit_move()
        end
end

function DD_GUI.mark_pending_exit_failed(state)
        local pending = DD_GUI.pending_exit_move
        local status = normalise_status(state)
        if not pending or not status then
                return false
        end
        apply_statuses(
                pending.room_id,
                {[pending.direction] = status},
                "failure",
                false
        )
        clear_pending_exit_move()
        return true
end

function DD_GUI.refresh_exit_status_from_gmcp()
        local info = gmcp and gmcp.Room and gmcp.Room.Info
        local room_id = type(info) == "table" and tonumber(info.vnum)
        if not room_id then
                return false
        end

        DD_GUI.clear_pending_exit_move(room_id)

        local statuses, complete = gmcp_exit_statuses(info)
        if complete then
                return apply_statuses(room_id, statuses, "gmcp", true)
        end

        -- Do not let a rich snapshot from an earlier connection suppress the
        -- text fallback when this session is using an older/partial payload.
        local metadata = DD_GUI.exit_status_meta_by_room[room_id]
        if metadata and metadata.source == "gmcp" then
                DD_GUI.exit_status_meta_by_room[room_id] = nil
                DD_GUI.exit_status_by_room[room_id] = nil
        end
        return false
end

function DD_GUI.update_exit_status(exit_text, complete_snapshot)
        local room_id = current_room_id()
        if not room_id then
                return false
        end

        local metadata = DD_GUI.exit_status_meta_by_room[room_id]
        if metadata and metadata.source == "gmcp" and metadata.complete then
                return false
        end

        local text = tostring(exit_text or "")
        text = text:gsub("\27%[[0-9;]*m", ""):lower()

        -- [Exits: ...] is a complete snapshot. Start empty so a door which
        -- was just opened/closed cannot retain its previous state forever.
        local statuses = {}
        local found = 0

        local function record(direction, status)
                local short = compass_exit_aliases[direction:lower()]
                if short then
                        statuses[short] = status
                        found = found + 1
                end
        end

        for direction in text:gmatch("%(%s*([%a]+)%s*%)") do
                record(direction, 2)
        end
        for direction in text:gmatch("%[%s*([%a]+)%s*%]") do
                record(direction, 3)
        end

        -- Remove marked tokens before reading plain exits, so `(down)` and
        -- `[east]` cannot be reclassified as open exits.
        local plain_text = text:gsub("%(%s*[%a]+%s*%)", " ")
                :gsub("%[%s*[%a]+%s*%]", " ")
        for token in plain_text:gmatch("%S+") do
                token = token:gsub("^[,;:]+", ""):gsub("[,;%.]+$", "")
                token = token:gsub("^exits:?$", "")
                local short = compass_exit_aliases[token]
                if short then
                        statuses[short] = 1
                        found = found + 1
                end
        end

        if found == 0 and complete_snapshot ~= true then
                return false
        end
        return apply_statuses(room_id, statuses, "text", true)
end

local function kill_handler(handler_id)
        if handler_id and type(killAnonymousEventHandler) == "function" then
                pcall(killAnonymousEventHandler, handler_id)
        end
end

local function schedule_exit_status_refresh(delay)
        if DD_GUI.exit_status_refresh_timer and type(killTimer) == "function" then
                pcall(killTimer, DD_GUI.exit_status_refresh_timer)
        end
        DD_GUI.exit_status_refresh_timer = nil
        if type(tempTimer) ~= "function" then
                return
        end
        DD_GUI.exit_status_refresh_timer = tempTimer(delay or 0.05, function()
                DD_GUI.exit_status_refresh_timer = nil
                DD_GUI.refresh_exit_status_from_gmcp()
        end)
end

-- Replace handlers left by an older live package tree. This matters during
-- reinstallgui/bootstrap, where globals survive package removal.
kill_handler(DD_GUI.exit_status_event_handler)
for _, handler_id in pairs(DD_GUI.exit_status_handlers or {}) do
        kill_handler(handler_id)
end
if DD_GUI.exit_status_refresh_timer and type(killTimer) == "function" then
        pcall(killTimer, DD_GUI.exit_status_refresh_timer)
end
DD_GUI.exit_status_refresh_timer = nil

DD_GUI.exit_status_handlers = {}
if type(registerAnonymousEventHandler) == "function" then
        DD_GUI.exit_status_handlers.room = registerAnonymousEventHandler(
                "gmcp.Room.Info",
                function()
                        DD_GUI.refresh_exit_status_from_gmcp()
                        schedule_exit_status_refresh(0.05)
                end
        )
        DD_GUI.exit_status_event_handler = DD_GUI.exit_status_handlers.room

        DD_GUI.exit_status_handlers.connection = registerAnonymousEventHandler(
                "sysConnectionEvent",
                function()
                        clear_pending_exit_move()
                        DD_GUI.refresh_exit_status_from_gmcp()
                        schedule_exit_status_refresh(0.1)
                end
        )
end

DD_GUI.refresh_exit_status_from_gmcp()
schedule_exit_status_refresh(0.05)
