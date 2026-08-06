function update_travel()

    local asset_path = DD_GUI.asset_path or function(relative_path)
            return ms_path .. "/" .. relative_path
    end

    local vitals = gmcp and gmcp.Char and gmcp.Char.Vitals
    local room = gmcp and gmcp.Room and gmcp.Room.Info
    if type(vitals) ~= "table" or type(room) ~= "table" then
            return
    end

    if (tonumber(vitals.position) ~= 6) then

            if DD_GUI.maybe_start_enemy_defeat_transition and
               DD_GUI.maybe_start_enemy_defeat_transition() then
                    return
            end

            local previous_mode = DD_GUI.enemy_panel_mode
            local room_changed = false
            if DD_GUI.enemy_panel_room_changed then
                    room_changed = DD_GUI.enemy_panel_room_changed(
                            gmcp.Room.Info.vnum
                    )
            end
            DD_GUI.enemy_panel_mode = "travel"
            if previous_mode == "combat" then
                    if DD_GUI.cancel_enemy_combat_pulse then
                            DD_GUI.cancel_enemy_combat_pulse()
                    end
                    if DD_GUI.cancel_enemy_panel_flash then
                            DD_GUI.cancel_enemy_panel_flash()
                    end
            end
            if room_changed and DD_GUI.flash_enemy_panel then
                    DD_GUI.flash_enemy_panel()
            elseif not DD_GUI.enemy_panel_flash_active and
                   DD_GUI.set_enemy_panel_border then
                    DD_GUI.set_enemy_panel_border(
                            DD_GUI.Theme and DD_GUI.Theme.colors.frame or
                                    "rgb(151,27,39)"
                    )
            end

            -- Travel mode has three lines of room metadata. The info console
            -- shares the panel with the combat summary, so give it the
            -- unused lower space while the enemy gauge is hidden.
            if EnemyInfoConsole and EnemyInfoConsole.resize then
                    EnemyInfoConsole:resize("92%", "22%")
            end

            EnemyConsole:clear()
            if not DD_GUI.enemy_panel_flash_active and
               DD_GUI.set_enemy_panel_border then
                    DD_GUI.set_enemy_panel_border(
                            DD_GUI.Theme and DD_GUI.Theme.colors.frame or
                                    "rgb(151,27,39)"
                    )
            end
            EnemyInfoConsole:clear()
            EnemyConsoleHitpointsContainer:hide()
            EnemyConsoleHitpoints:hide()
            EnemyHitpointsLabel:hide()
            local room_image = asset_path("avatars/default_char.png")
            local sector_name = "Unknown"

            --Room images based on sector types
            if (tonumber(gmcp.Room.Info.sector) == 0) then
            room_image = asset_path("environments/0_sect_inside.png")
            sector_name = "Inside"
            elseif (tonumber(gmcp.Room.Info.sector) == 1) then
            room_image = asset_path("environments/1_sect_city.png")
            sector_name = "City"
            elseif (tonumber(gmcp.Room.Info.sector) == 2) then
            room_image = asset_path("environments/2_sect_field.png")
            sector_name = "Field"
            elseif (tonumber(gmcp.Room.Info.sector) == 3) then
            room_image = asset_path("environments/3_sect_forest.png")
            sector_name = "Forest"
            elseif (tonumber(gmcp.Room.Info.sector) == 4) then
            room_image = asset_path("environments/4_sect_hills.png")
            sector_name = "Hills"
            elseif (tonumber(gmcp.Room.Info.sector) == 5) then
            room_image = asset_path("environments/5_sect_mountain.png")
            sector_name = "Mountain"
            elseif (tonumber(gmcp.Room.Info.sector) == 6) then
            room_image = asset_path("environments/6_sect_water_swim.png")
            sector_name = "Water (Swimmable)"
            elseif (tonumber(gmcp.Room.Info.sector) == 7) then
            room_image = asset_path("environments/7_sect_water_noswim.png")
            sector_name = "Water (Unswimmable)"
            elseif (tonumber(gmcp.Room.Info.sector) == 8) then
            room_image = asset_path("environments/8_sect_underwater.png")
            sector_name = "Underwater"
            elseif (tonumber(gmcp.Room.Info.sector) == 9) then
            room_image = asset_path("environments/9_sect_air.png")
            sector_name = "Air"
            elseif (tonumber(gmcp.Room.Info.sector) == 10) then
            room_image = asset_path("environments/10_sect_desert.png")
            sector_name = "Desert"
            elseif (tonumber(gmcp.Room.Info.sector) == 11) then
            room_image = asset_path("environments/11_sect_swamp.png")
            sector_name = "Swamp"
            elseif (tonumber(gmcp.Room.Info.sector) == 12) then
            room_image = asset_path("environments/12_sect_underwater_ground.png")
            sector_name = "Underwater (Ground)"
            end

            -- Custom room images.  If a custom room image exists, use it.

            local custom_room_path
            local room_name = string.lower(tostring(gmcp.Room.Info.name or ""))
            room_name = string.gsub(room_name, "/", "_")
            room_name = string.gsub(room_name, " ", "_")
            -- Sanitize the relative filename before asset_path() checks the
            -- profile-owned content directory. Sanitizing the resolved path
            -- afterward makes asset_path() fall back to the package folder.
            room_name = string.gsub(room_name, "'", "_")
            room_name = string.gsub(room_name, "<", "_")
            room_name = string.gsub(room_name, ">", "_")
            room_name = string.gsub(room_name, "{", "_")

            if (tonumber(gmcp.Room.Info.vnum) ~= 0) then
                    custom_room_path = asset_path("custom_rooms/"
                    ..tonumber(gmcp.Room.Info.vnum)
                    .."_"
                    ..room_name
                    ..".png")
            end

            if (custom_room_path and file_exists(custom_room_path)) then
                    room_image = custom_room_path
            end

            --display(ri_filename)

            --if (tonumber(gmcp.Room.Info.vnum) == 20695) then
            --        room_image = ms_path .. "/custom_rooms/20695_zeldas_cabin.png"
            --end

            --display(room_image)

            --if (tonumber(gmcp.Room.Info.vnum) == 20695) then
            --        room_image = ms_path .. "/custom_rooms/20695_zeldas_cabin.png"
            --end

            --display(room_image)

            EnemyTPConsoleTop:clear()
            --EnemyTPConsoleTop:setBackgroundImage([[
            --background-image: url(]] .. room_image .. [[);
            --border: 4px solid;
            --background-position: top left;
            --background-repeat: no-repeat;]],
            --"style")

            DD_GUI.ImageFit:set(
                    EnemyTPConsoleTop,
                    EnemyConsole,
                    room_image,
                    {
                            fallback = { width = 560, height = 300 },
                            frame = EnemyImageFrame,
                            align_x = "center",
                            stretch = true,
                    }
            )

            local stripped_room_name = string.gsub(gmcp.Room.Info.name, "\{[a-zA-Z]", "")
            stripped_room_name = string.gsub(stripped_room_name, "\<%d+\>", "")

            if (#stripped_room_name) > 31 then
                    for i = #stripped_room_name, 32, -1 do
                            stripped_room_name = replace_char(i, stripped_room_name, "")
                    end
                    stripped_room_name = replace_char(31, stripped_room_name, '.')
                    stripped_room_name = replace_char(30, stripped_room_name, '.')
            end

            local trimmed_area_name = tostring(gmcp.Room.Info.area or "Unknown")

            if (#trimmed_area_name) > 14 then
                    for i = #trimmed_area_name, 15, -1 do
                            trimmed_area_name = replace_char(i, trimmed_area_name, "")
                    end
                    trimmed_area_name = replace_char(14, trimmed_area_name, '.')
                    trimmed_area_name = replace_char(13, trimmed_area_name, '.')
            end

            EnemyInfoConsole:clear()
            local room_flags = {}
            local raw_flags = gmcp.Room.Info.flags
            if type(raw_flags) == "string" then
                    for _, value in ipairs(split_str(raw_flags)) do
                            if value ~= "" and value ~= "no_mob" then
                                    value = firstToUpper(value)
                                    value = string.gsub(value, "_", " ")
                                    table.insert(room_flags, value)
                            end
                    end
            elseif type(raw_flags) == "table" then
                    for _, value in ipairs(raw_flags) do
                            value = tostring(value)
                            if value ~= "" and value ~= "no_mob" then
                                    value = firstToUpper(value)
                                    value = string.gsub(value, "_", " ")
                                    table.insert(room_flags, value)
                            end
                    end
            end

            local room_flags_text = #room_flags > 0 and
                    table.concat(room_flags, ", ") or "None"

            EnemyInfoConsole:cecho(
            string.format("<white>Area: <ansi_white>%-15s",
            trimmed_area_name)
            ..string.format("<white>Type: <ansi_white>%-10s\n",
            sector_name)
            ..string.format("<white>Room: <ansi_white>%-30s\n",
            stripped_room_name)
            ..string.format("<white>Room flags: <ansi_white>%s",
            room_flags_text)
            )
    end
end
