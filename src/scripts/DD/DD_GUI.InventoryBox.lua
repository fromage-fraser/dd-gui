function build_inventory_box()
        DD_GUI.InventoryTopRow = Geyser.HBox:new({ 
          name = "GUI.InventoryTopRow", 
          x = "5%", y = "3%", 
          width = "100%", height = "10%", 
        },DD_GUI.InventoryBox ) 
        
        InventoryTitleLabel = Geyser.Label:new({
          name = "InventoryTitleLabel",
          x = 0, y = "10%",
          width = "50%", height = "70%",
          message = [[You are carrying:]]
        }, DD_GUI.InventoryTopRow )
        InventoryTitleLabel:setColor(0,0,0,0)
        InventoryTitleLabel:setFgColor("Cyan")
        InventoryTitleLabel:setFontSize(10)
        InventoryTitleLabel:setBold(1)
end