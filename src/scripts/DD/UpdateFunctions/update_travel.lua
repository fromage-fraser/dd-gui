function update_travel()

        if (tonumber(gmcp.Char.Vitals.position) ~= 6) then

                EnemyConsole:clear()
                DD_GUI.EnemyBox:setStyleSheet(DD_GUI.BoxCSS:getCSS())
                EnemyInfoConsole:clear()
                EnemyConsoleHitpointsContainer:hide()
                EnemyConsoleHitpoints:hide()
                EnemyHitpointsLabel:hide()
                EnemyLabel:echo("Travel Info")

                local room_image = ms_path .. "/avatars/default_char.png"
                local sector_name = "Unknown"

                --Room images based on sector types
                if (tonumber(gmcp.Room.Info.sector) == 0) then
                room_image = ms_path .. "/environments/0_sect_inside.png"
                sector_name = "Inside"
                elseif (tonumber(gmcp.Room.Info.sector) == 1) then
                room_image = ms_path .. "/environments/1_sect_city.png"
                sector_name = "City"
                elseif (tonumber(gmcp.Room.Info.sector) == 2) then
                room_image = ms_path .. "/environments/2_sect_field.png"
                sector_name = "Field"
                elseif (tonumber(gmcp.Room.Info.sector) == 3) then
                room_image = ms_path .. "/environments/3_sect_forest.png"
                sector_name = "Forest"
                elseif (tonumber(gmcp.Room.Info.sector) == 4) then
                room_image = ms_path .. "/environments/4_sect_hills.png"
                sector_name = "Hills"
                elseif (tonumber(gmcp.Room.Info.sector) == 5) then
                room_image = ms_path .. "/environments/5_sect_mountain.png"
                sector_name = "Mountain"
                elseif (tonumber(gmcp.Room.Info.sector) == 6) then
                room_image = ms_path .. "/environments/6_sect_water_swim.png"
                sector_name = "Water (Swimmable)"
                elseif (tonumber(gmcp.Room.Info.sector) == 7) then
                room_image = ms_path .. "/environments/7_sect_water_noswim.png"
                sector_name = "Water (Unswimmable)"
                elseif (tonumber(gmcp.Room.Info.sector) == 8) then
                room_image = ms_path .. "/environments/8_sect_underwater.png"
                sector_name = "Underwater"
                elseif (tonumber(gmcp.Room.Info.sector) == 9) then
                room_image = ms_path .. "/environments/9_sect_air.png"
                sector_name = "Air"
                elseif (tonumber(gmcp.Room.Info.sector) == 10) then
                room_image = ms_path .. "/environments/10_sect_desert.png"
                sector_name = "Desert"
                elseif (tonumber(gmcp.Room.Info.sector) == 11) then
                room_image = ms_path .. "/environments/11_sect_swamp.png"
                sector_name = "Swamp"
                elseif (tonumber(gmcp.Room.Info.sector) == 12) then
                room_image = ms_path .. "/environments/12_sect_underwater_ground.png"
                sector_name = "Underwater (Ground)"
                end

                -- Custom room images.  If a custom room image exists, use it.

                local ri_filename

                if (tonumber(gmcp.Room.Info.vnum) ~= 0) then
                        ri_filename = ms_path
                        .."/custom_rooms/"
                        ..tonumber(gmcp.Room.Info.vnum)
                        .."_"
                        ..string.lower(string.gsub(gmcp.Room.Info.name, " ", "_"))
                        ..".png"
                end

                if (file_exists(ri_filename)) then
                        room_image = ri_filename
                end

                --display(ri_filename)

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

                EnemyTPConsoleTop:setBackgroundImage(room_image,"border")

                local stripped_room_name = string.gsub(gmcp.Room.Info.name, "\{[a-zA-Z]", "")
                stripped_room_name = string.gsub(stripped_room_name, "\<%d+\>", "")

                if (#stripped_room_name) > 31 then
                        for i = #stripped_room_name, 32, -1 do
                                stripped_room_name = replace_char(i, stripped_room_name, "")
                        end
                        stripped_room_name = replace_char(31, stripped_room_name, '.')
                        stripped_room_name = replace_char(30, stripped_room_name, '.')
                end

                trimmed_area_name = gmcp.Room.Info.area

                if (#trimmed_area_name) > 14 then
                        for i = #trimmed_area_name, 15, -1 do
                                trimmed_area_name = replace_char(i, trimmed_area_name, "")
                        end
                        trimmed_area_name = replace_char(14, trimmed_area_name, '.')
                        trimmed_area_name = replace_char(13, trimmed_area_name, '.')
                end

                EnemyInfoConsole:clear()
                EnemyInfoConsole:cecho(
                string.format("<white>Area: <ansi_white>%-15s",
                trimmed_area_name)
                ..string.format("<white>Type: <ansi_white>%-10s\n",
                sector_name)
                ..string.format("<white>Room: <ansi_white>%-30s\n",
                stripped_room_name)
                )

                if (gmcp.Room.Info.flags ~= "") and not (string.find(gmcp.Room.Info.flags, "^no_mob$")) then
                        EnemyInfoConsole:cecho("<white>Room features: ")

                        local rflags = split_str(gmcp.Room.Info.flags)
                        local last_flag_index = #rflags

                        for index, value in ipairs(rflags) do
                                if (value ~= "no_mob") then
                                        value = firstToUpper(value)
                                        value = string.gsub(value, "_", " ")
                                        EnemyInfoConsole:cecho(
                                        string.format("<ansi_white>%s",
                                                value)
                                        )
                                        if (last_flag_index ~= index) then
                                                EnemyInfoConsole:cecho(", ")
                                        end
                                end
                        end
                end
        end
end