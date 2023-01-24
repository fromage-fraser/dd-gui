function build_enemy_box()
        DD_GUI.EnemyTopRow = Geyser.HBox:new({
          name = "DD_GUI.EnemyTopRow",
          x = "5%", y = "3%",
          width = "100%", height = "30%",
        },DD_GUI.EnemyBox )

        EnemyLabel = Geyser.Label:new({
          name = "EnemyLabel",
          x = 0, y = "5%",
          width = "50%", height = "70%",
          message = [[Enemy Info]]
        }, DD_GUI.EnemyTopRow )
        EnemyLabel:setColor(0,0,0,0)
        EnemyLabel:setFgColor("Cyan")
        EnemyLabel:setFontSize(10)
        EnemyLabel:setBold(1)
end