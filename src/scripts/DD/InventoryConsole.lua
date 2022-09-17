function build_inventory_console()
        InventoryConsole = Geyser.MiniConsole:new({
          name="InventoryConsole",
          x = "4%", y = "13%",
          width="92%", 
          height="83%",
          autoWrap = true,
          color = "black",
          scrollBar = false,
          fontSize = 10,
        }, DD_GUI.InventoryBox)
end