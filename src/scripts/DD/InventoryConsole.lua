function build_inventory_console()
    if InventoryConsole and InventoryConsole.hide then
      InventoryConsole:hide()
    end

    if EquippedConsole and EquippedConsole.hide then
      EquippedConsole:hide()
    end

    DD_GUI.Inventory.consoles = {}

    InventoryConsole = Geyser.MiniConsole:new({
      name="InventoryConsole",
      x = "0%", y = "0%",
      width="100%",
      height="100%",
      autoWrap = true,
      color = "black",
      scrollBar = true,
      horizontalScrollBar = false,
      fontSize = 10,
    }, DD_GUI.Inventory.content_stack)
    if DD_GUI.Theme then
      DD_GUI.Theme:style_console(InventoryConsole, 10)
    end

    EquippedConsole = Geyser.MiniConsole:new({
      name="EquippedConsole",
      x = "0%", y = "0%",
      width="100%",
      height="100%",
      autoWrap = false,
      wrapAt = 10000,
      color = "black",
      scrollBar = true,
      horizontalScrollBar = false,
      fontSize = 10,
    }, DD_GUI.Inventory.content_stack)
    if DD_GUI.Theme then
      DD_GUI.Theme:style_console(EquippedConsole, 10)
    end

    DD_GUI.Inventory.consoles.inventory = InventoryConsole
    DD_GUI.Inventory.consoles.equipped = EquippedConsole
    DD_GUI.Inventory:switch_tab(DD_GUI.Inventory.current_tab or "inventory")
end
