function update_enemy()
        if (tonumber(gmcp.Char.Vitals.position) == 6) then
          
                DD_GUI.EnemyBox:setStyleSheet(DD_GUI.EnemyBoxCSS:getCSS())
                EnemyConsoleHitpointsContainer:show()
                EnemyConsoleHitpoints:show()
                EnemyHitpointsLabel:show()
                EnemyConsole:clear()
                EnemyLabel:echo("Enemy Info")
                EnemyInfoConsole:clear()
                local enemy_image       = ms_path .. "/mobs/20412_the_destroyer.png"
                local def_enemy_image   = ms_path .. "/mobs/0_default.png"
          
                -- 0 if a PC, otherwise the VNUM of the mob
                if (gmcp.Char.Enemies[1][1].isnpc ~= 0) then
                        enemy_image = ms_path 
                        .."/mobs/" 
                        ..tonumber(gmcp.Char.Enemies[1][1].isnpc) 
                        .."_" 
                        ..string.lower(string.gsub(gmcp.Char.Enemies[1][1].name, " ", "_")) 
                        ..".png"
                end
          
                --display(enemy_image)
                EnemyTPConsoleTop:clear()

                if (file_exists(enemy_image)) then
                        EnemyTPConsoleTop:setBackgroundImage(enemy_image,"border")
                else
                        EnemyTPConsoleTop:setBackgroundImage(def_enemy_image,"border")
                end

                for i, count in ipairs(gmcp.Char.Enemies) do
                        --display(i)
                        --display(count)
                        if (gmcp.Char.Enemies[1][i].name) ~= nil then
                                EnemyInfoConsole:cecho("<white>Enemy: <reset>"..string.format("%-22s", firstToUpper(gmcp.Char.Enemies[1][1].name)))
                                EnemyInfoConsole:cecho("<white>Lvl: <reset>" ..string.format("%-3s\n", gmcp.Char.Enemies[1][1].level))
                                EnemyConsoleHitpoints:setValue(((gmcp.Char.Enemies[1][1].hp * 1000) / gmcp.Char.Enemies[1][1].maxhp),1000)
                        end
                end
        end
end