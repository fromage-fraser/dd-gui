local function first_enemy(enemies)
        if type(enemies) ~= "table" or type(enemies[1]) ~= "table" then
                return nil
        end

        -- Older GMCP payloads wrapped the enemy rows one level deeper;
        -- the current web-gate payload sends a flat array of enemy objects.
        if enemies[1].name ~= nil or enemies[1].hp ~= nil or
           enemies[1].maxhp ~= nil then
                return enemies[1]
        end

        if type(enemies[1][1]) == "table" then
                return enemies[1][1]
        end

        return nil
end

function update_enemy()
        local asset_path = DD_GUI.asset_path or function(relative_path)
                return ms_path .. "/" .. relative_path
        end

        local enemies = gmcp and gmcp.Char and gmcp.Char.Enemies
        local enemy = first_enemy(enemies)

        if type(enemy) == "table" and
           (tonumber(gmcp.Char.Vitals.position) == 6) then

                DD_GUI.EnemyBox:setStyleSheet(DD_GUI.EnemyBoxCSS:getCSS())
                EnemyConsoleHitpointsContainer:show()
                EnemyConsoleHitpoints:show()
                EnemyHitpointsLabel:show()
                EnemyConsole:clear()
                EnemyInfoConsole:clear()
                local enemy_image       = asset_path("mobs/20412_the_destroyer.png")
                local def_enemy_image   = asset_path("mobs/0_default.png")
                local enemy_vnum = tonumber(enemy.vnum)
                if enemy_vnum == nil then
                        enemy_vnum = tonumber(enemy.isnpc) or 0
                end

                -- Newer GMCP payloads call this vnum; older ones call it isnpc.
                -- Zero means the enemy is a player and has no mob portrait.
                if enemy_vnum ~= 0 then
                        enemy_image = asset_path("mobs/"
                        ..enemy_vnum
                        .."_"
                        ..string.lower(string.gsub(enemy.name, " ", "_"))
                        ..".png")
                end

                enemy_image = string.gsub(enemy_image, "'", "_")
                --display(enemy_image)

                EnemyTPConsoleTop:clear()

                if (file_exists(enemy_image)) then
                        DD_GUI.ImageFit:set(
                                EnemyTPConsoleTop,
                                EnemyConsole,
                                enemy_image,
                                {
                                        fallback = { width = 560, height = 300 },
                                        frame = EnemyImageFrame,
                                        align_x = "center",
                                        stretch = true,
                                }
                        )
                else
                        DD_GUI.ImageFit:set(
                                EnemyTPConsoleTop,
                                EnemyConsole,
                                def_enemy_image,
                                {
                                        fallback = { width = 560, height = 300 },
                                        frame = EnemyImageFrame,
                                        align_x = "center",
                                        stretch = true,
                                }
                        )
                end

                if enemy.name ~= nil then
                        EnemyInfoConsole:cecho("<white>Enemy: <reset>"..string.format("%-22s", firstToUpper(enemy.name)))
                        EnemyInfoConsole:cecho("\n<white>Lvl: <reset>" ..string.format("%-3s", enemy.level))

                        local enemy_hp = tonumber(enemy.hp) or 0
                        local enemy_maxhp = tonumber(enemy.maxhp) or 0
                        if enemy_maxhp > 0 then
                                enemy_hp = math.max(0, math.min(enemy_hp, enemy_maxhp))
                                EnemyConsoleHitpoints:setValue(
                                        (enemy_hp * 1000) / enemy_maxhp,
                                        1000
                                )
                        else
                                EnemyConsoleHitpoints:setValue(0, 1000)
                        end

                        -- The gauge is a sibling of the text console; keep it
                        -- above the image and text surfaces after each update.
                        if EnemyConsoleHitpointsContainer.raise then
                                EnemyConsoleHitpointsContainer:raise()
                        end
                        if EnemyConsoleHitpoints.raise then
                                EnemyConsoleHitpoints:raise()
                        end
                        if EnemyHitpointsLabel.raise then
                                EnemyHitpointsLabel:raise()
                        end
                end
        end
end
