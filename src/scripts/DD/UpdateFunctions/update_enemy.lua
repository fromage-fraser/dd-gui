function update_enemy()
        local asset_path = DD_GUI.asset_path or function(relative_path)
                return ms_path .. "/" .. relative_path
        end

        local enemies = gmcp and gmcp.Char and gmcp.Char.Enemies
        local enemy = type(enemies) == "table" and type(enemies[1]) == "table" and
                enemies[1][1]

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
                end
        end
end
