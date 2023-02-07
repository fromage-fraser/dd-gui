function load_dd_mapper ()
        -- Generic GMCP mapping script for Mudlet
        -- by Blizzard. https://worldofpa.in
        -- based upon an MSDP script from the Mudlet forums in the generic mapper thread
        -- with pieces from the generic mapper script and the mmpkg mapper by breakone9r
        -- Customised for Dragons Domain MUD by Owl

        cecho("Loading Dragons Domain custom mapper.\n")

        map = map or {}
        map.room_info = map.room_info or {}
        map.prev_info = map.prev_info or {}
        map.aliases = map.aliases or {}
        map.configs = map.configs or {}
        map.configs.speedwalk_delay = 0

        local defaults = {
            -- using Geyser to handle the mapper in this, since this is a totally new script
            mapper = {x = 0, y = 0, width = "100%", height = "100%"}
        }

        local terrain_types = {
            -- used to make rooms of different terrain types have different colors
            -- add a new entry for each terrain type, and set the color with RGB values
            -- each id value must be unique, terrain types not listed here will use mapper default color
            -- not used if you define these in a map XML file
            -- Numbers 1-16 and 257-272 are reserved by Mudlet. (don't use)
            -- 257-272 are the default colors the user can adjust in mapper settings (don't overwrite)
            -- We are using DD sector values +20 (so as not to conflict with reserved 1-16 range)
            -- You can see the RGB colours using the converter at https://www.rgbtohex.net/

            [20]          = {id = 20,  r = 144, g = 144, b = 144},         -- ["Inside"]
            [21]          = {id = 21,  r = 100, g = 100, b = 100},         -- ["City"]
            [22]          = {id = 22,  r = 109, g = 241, b = 109},         -- ["Field"]
            [23]          = {id = 23,  r =   3, g =  72, b =   2},         -- ["Forest"]
            [24]          = {id = 24,  r = 125, g =  80, b =   0},         -- ["Hills"]
            [25]          = {id = 25,  r =  42, g =  32, b =   0},         -- ["Mountain"]
            [26]          = {id = 26,  r = 128, g = 180, b = 245},         -- ["WaterSwim"]
            [27]          = {id = 27,  r =  18, g = 116, b = 238},         -- ["WaterNoSwim"]
            [28]          = {id = 28,  r =   2, g =  48, b = 107},         -- ["Underwater"]
            [29]          = {id = 29,  r = 206, g = 206, b = 206},         -- ["Air"]
            [30]          = {id = 30,  r = 208, g = 180, b =   5},         -- ["Desert"]
            [31]          = {id = 31,  r =  54, g =  84, b =  60},         -- ["Swamp"]
            [32]          = {id = 32,  r =  2,  g =  78, b = 107}          -- ["UnderwaterGround"]
        }

        -- list of possible movement directions and appropriate coordinate changes
        local move_vectors = {
            n = {0,1,0}, s = {0,-1,0}, e = {1,0,0}, w = {-1,0,0},
            nw = {-1,1,0}, ne = {1,1,0}, sw = {-1,-1,0}, se = {1,-1,0},
            u = {0,0,1}, d = {0,0,-1}
        }

        local exitmap = {
            n = 'north',    ne = 'northeast',   nw = 'northwest',   e = 'east',
            w = 'west',     s = 'south',        se = 'southeast',   sw = 'southwest',
            u = 'up',       d = 'down',         ["in"] = 'in',      out = 'out',
            l = 'look'
        }

        local stubmap = {
            north = 1,          northeast = 2,      northwest = 3,      east = 4,
            west = 5,           south = 6,          southeast = 7,      southwest = 8,
            up = 9,             down = 10,          ["in"] = 11,        out = 12,
            northup = 13,       southdown = 14,     southup = 15,       northdown = 16,
            eastup = 17,        westdown = 18,      westup = 19,        eastdown = 20,
            [1] = "n",          [2] = "northeast",  [3] = "northwest",  [4] = "e",
            [5] = "w",          [6] = "s",          [7] = "southeast",  [8] = "southwest",
            [9] = "u",          [10] = "d",         [11] = "in",        [12] = "out",
            [13] = "northup",   [14] = "southdown", [15] = "southup",   [16] = "northdown",
            [17] = "eastup",    [18] = "westdown",  [19] = "westup",    [20] = "eastdown",
        }

        local short = {}
        for k,v in pairs(exitmap) do
            short[v] = k
        end

        local function make_room()
            local info = map.room_info
            local coords = {0,0,0}
            addRoom(info.vnum)
                  setRoomName(info.vnum, info.name)
            local areas = getAreaTable()
            local areaID = areas[info.area]
            if not areaID then
                areaID = addAreaName(info.area)
            else
                coords = {getRoomCoordinates(map.prev_info.vnum)}
                local shift = {0,0,0}
                for k,v in pairs(info.exits) do
                    if v == map.prev_info.vnum and move_vectors[k] then
                        shift = move_vectors[k]
                        break
                    end
                end
                for n = 1,3 do
                    coords[n] = coords[n] - shift[n]
                end
                -- map stretching
                local overlap = getRoomsByPosition(areaID,coords[1],coords[2],coords[3])
                if not table.is_empty(overlap) then
                    local rooms = getAreaRooms(areaID)
                    local rcoords
                    for _,id in ipairs(rooms) do
                        rcoords = {getRoomCoordinates(id)}
                        for n = 1,3 do
                            if shift[n] ~= 0 and (rcoords[n] - coords[n]) * shift[n] <= 0 then
                                rcoords[n] = rcoords[n] - shift[n]
                            end
                        end
                        setRoomCoordinates(id,rcoords[1],rcoords[2],rcoords[3])
                    end
                end
            end
            setRoomArea(info.vnum, areaID)
            setRoomCoordinates(info.vnum, coords[1], coords[2], coords[3])
            --display("COORDS")
            --display(info.terrain)
            --display(terrain_types[tonumber(info.terrain)].id)
            --display(terrain_types[tonumber(info.terrain)].r)
            --display(terrain_types[tonumber(info.terrain)].g)
            --display(terrain_types[tonumber(info.terrain)].b)
            setRoomEnv(info.vnum, tonumber(terrain_types[tonumber(info.terrain)].id))
            setCustomEnvColor(
              terrain_types[tonumber(info.terrain)].id,
              terrain_types[tonumber(info.terrain)].r,
              terrain_types[tonumber(info.terrain)].g,
              terrain_types[tonumber(info.terrain)].b,
            255)

            for dir, id in pairs(info.exits) do
                -- need to see how special exits are represented to handle those properly here
                if getRoomName(id) then
                    setExit(info.vnum, id, dir)
                else
                    setExitStub(info.vnum, dir, true)
                end
            end
        end

        local function shift_room(dir)
            local ID = map.room_info.vnum
            local x,y,z = getRoomCoordinates(ID)
            local x1,y1,z1 = table.unpack(move_vectors[dir])
            x = x + x1
            y = y + y1
            z = z + z1
            setRoomCoordinates(ID,x,y,z)
            updateMap()
        end

        local function handle_move()
            local info = map.room_info
            if not getRoomName(info.vnum) then
                make_room()
            else
                local stubs = getExitStubs1(info.vnum)
                        if stubs then
                  for _, n in ipairs(stubs) do
                      local dir = stubmap[n]
                      --display("dir is " .. dir)
                      local id = info.exits[dir]
                      --display("id is " .. id)
                      -- need to see how special exits are represented to handle those properly here
                      if id and getRoomName(id) then
                          setExit(info.vnum, id, dir)
                      end
                  end
                        end
            end
            centerview(map.room_info.vnum)
        end

        local function config()

            -- setting terrain colors
            for k,v in pairs(terrain_types) do
                --display(v.id)
                --display(v.r)
                --display(v.g)
                --display(v.b)
                setCustomEnvColor(v.id, v.r, v.g, v.b, 255)
            end
            -- making mapper window
            --local info = defaults.mapper
            --Geyser.Mapper:new({name = "myMap", x = info.x, y = info.y, width = info.width, height = info.height})
            -- clearing existing aliases if they exist
            for k,v in pairs(map.aliases) do
                killAlias(v)
            end
            map.aliases = {}
            -- making an alias to let the user shift a room around via command line
            table.insert(map.aliases,tempAlias([[^shift (\w+)$]],[[raiseEvent("shiftRoom",matches[2])]]))
                table.insert(map.aliases,tempAlias([[^make_room$]],[[make_room()]]))
        end

        local function check_doors(roomID,exits)
            -- looks to see if there are doors in designated directions
            -- used for room comparison, can also be used for pathing purposes
            if type(exits) == "string" then exits = {exits} end
            local statuses = {}
            local doors = getDoors(roomID)
            local dir
            for k,v in pairs(exits) do
                dir = short[k] or short[v]
                if table.contains({'u','d'},dir) then
                    dir = exitmap[dir]
                end
                if not doors[dir] or doors[dir] == 0 then
                    return false
                else
                    statuses[dir] = doors[dir]
                end
            end
            return statuses
        end


        local continue_walk, timerID
        continue_walk = function(new_room)
            if not walking then return end
            -- calculate wait time until next command, with randomness
            local wait = map.configs.speedwalk_delay or 0
            if wait > 0 and map.configs.speedwalk_random then
                wait = wait * (1 + math.random(0,100)/100)
            end
            -- if no wait after new room, move immediately
            if new_room and map.configs.speedwalk_wait and wait == 0 then
                new_room = false
            end
            -- send command if we don't need to wait
            if not new_room then
                send(table.remove(map.walkDirs,1))
                -- check to see if we are done
                if #map.walkDirs == 0 then
                    walking = false
                end
            end
            -- make tempTimer to send next command if necessary
            if walking and (not map.configs.speedwalk_wait or (map.configs.speedwalk_wait and wait > 0)) then
                if timerID then killTimer(timerID) end
                timerID = tempTimer(wait, function() continue_walk() end)
            end
        end

        function map.speedwalk(roomID, walkPath, walkDirs)
            roomID = roomID or speedWalkPath[#speedWalkPath]
            getPath(map.room_info.vnum, roomID)
            walkPath = speedWalkPath
            walkDirs = speedWalkDir
            if #speedWalkPath == 0 then
                map.echo("No path to chosen room found.",false,true)
                return
            end
            table.insert(walkPath, 1, map.room_info.vnum)
            -- go through dirs to find doors that need opened, etc
            -- add in necessary extra commands to walkDirs table
            local k = 1
            repeat
                local id, dir = walkPath[k], walkDirs[k]
                if exitmap[dir] or short[dir] then
                    local door = check_doors(id, exitmap[dir] or dir)
                    local status = door and door[dir]
                    if status and status > 1 then
                        -- if locked, unlock door
                        if status == 3 then
                            table.insert(walkPath,k,id)
                            table.insert(walkDirs,k,"unlock " .. (exitmap[dir] or dir))
                            k = k + 1
                        end
                        -- if closed, open door
                        table.insert(walkPath,k,id)
                        table.insert(walkDirs,k,"open " .. (exitmap[dir] or dir))
                        k = k + 1
                    end
                end
                k = k + 1
            until k > #walkDirs
            if map.configs.use_translation then
                for k, v in ipairs(walkDirs) do
                    walkDirs[k] = map.configs.lang_dirs[v] or v
                end
            end
            -- perform walk
            walking = true
            if map.configs.speedwalk_wait or map.configs.speedwalk_delay > 0 then
                map.walkDirs = walkDirs
                continue_walk()
            else
                for _,dir in ipairs(walkDirs) do
                    send(dir)
                end
                walking = false
            end
        end

        function doSpeedWalk()
            if #speedWalkPath ~= 0 then
                map.speedwalk(nil, speedWalkPath, speedWalkDir)
            else
                map.echo("No path to chosen room found.",false,true)
            end
        end


        function map.eventHandler(event,...)
            if event == "gmcp.Room.Info" then
                map.prev_info = map.room_info
                map.room_info = {
                  vnum = tonumber(gmcp.Room.Info.vnum),
                  area = gmcp.Room.Info.area,
                  name = gmcp.Room.Info.name,
                  terrain = (gmcp.Room.Info.sector + 20),
                  exits = table.deepcopy(gmcp.Room.Info.exits)
                }
                --display("TERRAIN VALUE")
                --display(map.room_info.terrain)
                for k,v in pairs(map.room_info.exits) do
                    map.room_info.exits[k] = tonumber(v)
                end
                handle_move()
            elseif event == "shiftRoom" then
                local dir = exitmap[arg[1]] or arg[1]
                if not table.contains(exits, dir) then
                    echo("Error: Invalid direction '" .. dir .. "'.")
                else
                    shift_room(dir)
                end
            elseif event == "sysConnectionEvent" then
                config()
            end
        end

        mapper_event_1 = registerAnonymousEventHandler("gmcp.Room.Info","map.eventHandler")
        mapper_event_2 = registerAnonymousEventHandler("shiftRoom","map.eventHandler")
        mapper_event_3 = registerAnonymousEventHandler("sysConnectionEvent", "map.eventHandler")
end