DD_GUI = DD_GUI or {}
DD_GUI.Inventory = DD_GUI.Inventory or {}

DD_GUI.Inventory.tab_definitions = {
        { key = "inventory", label = "Inventory" },
        { key = "equipped",  label = "Equipped" },
}

function DD_GUI.Inventory:tab_css(key)
        if DD_GUI.Theme then
                return DD_GUI.Theme:tab_css(key == self.current_tab)
        end

        return [[
                background-color: rgba(0,0,0,170);
                border-style: solid;
                border-width: 1px;
                border-color: rgb(45,45,45);
                margin: 1px;
        ]]
end

function DD_GUI.Inventory:style_tab(key)
        local tab = self.tab_buttons and self.tab_buttons[key]
        if not tab then
                return
        end

        tab:setStyleSheet(self:tab_css(key))
        tab:echo(
                self.tab_labels[key],
                "white",
                "c"
        )
end

function DD_GUI.Inventory:style_tabs()
        for _, definition in ipairs(self.tab_definitions) do
                self:style_tab(definition.key)
        end
end

function DD_GUI.Inventory:build_tabs()
        if self.tab_rail and self.tab_rail.hide then
                self.tab_rail:hide()
        end

        if self.content_stack and self.content_stack.hide then
                self.content_stack:hide()
        end

        self.tab_buttons = {}
        self.tab_labels = {}

        self.tab_rail = Geyser.Label:new({
                name = "DD_GUI.Inventory.TabRail",
                x = "2%",
                y = "3%",
                width = "96%",
                height = "10%",
        }, DD_GUI.InventoryBox)
        self.tab_rail:setColor(0, 0, 0, 0)

        self.content_stack = Geyser.Label:new({
                name = "DD_GUI.Inventory.ContentStack",
                x = "2%",
                y = "14%",
                width = "96%",
                height = "82%",
        }, DD_GUI.InventoryBox)
        self.content_stack:setColor(0, 0, 0, 255)

        for index, definition in ipairs(self.tab_definitions) do
                local tab = Geyser.Label:new({
                        name = "DD_GUI.Inventory.Tab." .. definition.key,
                        x = tostring((index - 1) * 50) .. "%",
                        y = "0%",
                        width = "50%",
                        height = "100%",
                }, self.tab_rail)

                if DD_GUI.Theme then
                        DD_GUI.Theme:style_label(tab, 8, true)
                else
                        tab:setFontSize(8)
                        tab:setBold(1)
                end
                tab:setClickCallback("dd_inventory_tab_click", definition.key)

                self.tab_buttons[definition.key] = tab
                self.tab_labels[definition.key] = definition.label
        end

        self.current_tab = self.current_tab or "inventory"
        self:style_tabs()
end

function DD_GUI.Inventory:switch_tab(key)
        if not self.consoles or not self.consoles[key] then
                key = "inventory"
        end

        self.current_tab = key

        for tab_key, console in pairs(self.consoles or {}) do
                if tab_key == key then
                        console:show()
                        raiseWindow(console.name)
                else
                        console:hide()
                end
        end

        self:style_tabs()

        if key == "inventory" and type(update_inventory) == "function" then
                update_inventory()
        elseif key == "equipped" and type(update_equipped) == "function" then
                update_equipped()
        end
end

function dd_inventory_tab_click(key, event)
        if event and event.button and event.button ~= "LeftButton" then
                return
        end

        if DD_GUI and DD_GUI.Inventory then
                DD_GUI.Inventory:switch_tab(key)
        end
end

function build_inventory_box()
        -- Remove the old title and its row before placing the tab rail.
        if DD_GUI.InventoryTopRow and DD_GUI.InventoryTopRow.hide then
                DD_GUI.InventoryTopRow:hide()
        end

        if InventoryTitleLabel and InventoryTitleLabel.hide then
                InventoryTitleLabel:hide()
        end

        DD_GUI.InventoryTopRow = nil
        InventoryTitleLabel = nil
        DD_GUI.Inventory:build_tabs()
end
