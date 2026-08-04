function build_inventory_console()
    if InventoryConsole and InventoryConsole.hide then
      InventoryConsole:hide()
    end

    if EquippedConsole and EquippedConsole.hide then
      EquippedConsole:hide()
    end

    if InventoryStatsLabel and InventoryStatsLabel.hide then
      InventoryStatsLabel:hide()
    end

    DD_GUI.Inventory.consoles = {}

    InventoryConsole = Geyser.MiniConsole:new({
      name="InventoryConsole",
      x = "0%", y = "0%",
      width="100%",
      height="86%",
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

    InventoryStatsLabel = Geyser.Label:new({
      name = "InventoryStatsLabel",
      x = "45%", y = "86%",
      width = "52%", height = "11%",
    }, DD_GUI.InventoryBox)
    InventoryStatsLabel:setStyleSheet([[
      background-color: rgb(0,0,0);
      border: 0px;
      padding: 0px;
      margin: 0px;
    ]])
    InventoryStatsLabel:setFgColor("white")
    if DD_GUI.Theme then
      DD_GUI.Theme:style_label(InventoryStatsLabel, 9, false)
    else
      InventoryStatsLabel:setFontSize(9)
    end
    InventoryStatsLabel:hide()

    DD_GUI.Inventory.consoles.inventory = InventoryConsole
    DD_GUI.Inventory.consoles.equipped = EquippedConsole
    DD_GUI.Inventory.stats_label = InventoryStatsLabel
    DD_GUI.Inventory:switch_tab(DD_GUI.Inventory.current_tab or "inventory")
end
