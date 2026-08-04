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

                -- 0 if a PC, otherwise the VNUM of the mob
                if (enemy.isnpc ~= 0) then
                        enemy_image = asset_path("mobs/"
                        ..tonumber(enemy.isnpc)
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

                for i, count in ipairs(enemies) do
                        --display(i)
                        --display(count)
                        if (enemies[1][i].name) ~= nil then
                                EnemyInfoConsole:cecho("<white>Enemy: <reset>"..string.format("%-22s", firstToUpper(enemy.name)))
                                EnemyInfoConsole:cecho("\n<white>Lvl: <reset>" ..string.format("%-3s", enemy.level))
                                EnemyConsoleHitpoints:setValue(((enemy.hp * 1000) / enemy.maxhp),1000)
                        end
                end
        end
end
