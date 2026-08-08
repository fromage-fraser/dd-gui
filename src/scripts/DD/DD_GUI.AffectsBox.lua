DD_GUI = DD_GUI or {}
DD_GUI.Affects = DD_GUI.Affects or {}

DD_GUI.Affects.tab_definitions = {
        { key = "affects", label = "Affects" },
        { key = "quest",   label = "Quest Status" },
}

function DD_GUI.Affects:tab_css(key)
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

function DD_GUI.Affects:style_tab(key)
        local tab = self.tab_buttons and self.tab_buttons[key]
        if not tab then
                return
        end

        tab:setStyleSheet(self:tab_css(key))
        tab:echo(self.tab_labels[key], "white", "c")
end

function DD_GUI.Affects:style_tabs()
        for _, definition in ipairs(self.tab_definitions) do
                self:style_tab(definition.key)
        end
end

function DD_GUI.Affects:build_tabs()
        if self.tab_rail and self.tab_rail.hide then
                self.tab_rail:hide()
        end
        if self.content_stack and self.content_stack.hide then
                self.content_stack:hide()
        end

        -- Older package versions added a second full-size frame. Remove it
        -- during rebuild so AffectBox's own red border is the only outline.
        if self.frame and self.frame.delete then
                self.frame:delete()
        end
        if type(deleteLabel) == "function" then
                pcall(deleteLabel, "DD_GUI.Affects.Frame")
        end
        self.frame = nil
        self.tab_button = nil
        self.tab_buttons = {}
        self.tab_labels = {}

        self.tab_rail = Geyser.Label:new({
                name = "DD_GUI.Affects.TabRail",
                x = "2%",
                y = "3%",
                width = "96%",
                height = "10%",
        }, DD_GUI.AffectBox)
        self.tab_rail:setColor(0, 0, 0, 0)

        self.content_stack = Geyser.Label:new({
                name = "DD_GUI.Affects.ContentStack",
                x = "2%",
                y = "14%",
                width = "96%",
                height = "82%",
        }, DD_GUI.AffectBox)
        self.content_stack:setColor(0, 0, 0, 255)

        local tab_width = 100 / #self.tab_definitions
        for index, definition in ipairs(self.tab_definitions) do
                local tab = Geyser.Label:new({
                        name = "DD_GUI.Affects.Tab." .. definition.key,
                        x = tostring((index - 1) * tab_width) .. "%",
                        y = "0%",
                        width = tostring(tab_width) .. "%",
                        height = "100%",
                }, self.tab_rail)

                if DD_GUI.Theme then
                        DD_GUI.Theme:style_label(tab, 8, true)
                else
                        tab:setFontSize(8)
                        tab:setBold(1)
                end
                tab:setClickCallback("dd_affects_tab_click", definition.key)

                self.tab_buttons[definition.key] = tab
                self.tab_labels[definition.key] = definition.label
        end

        if self.current_tab ~= "affects" and self.current_tab ~= "quest" then
                self.current_tab = "affects"
        end
        self:style_tabs()
end

function DD_GUI.Affects:switch_tab(key)
        if not self.consoles or not self.consoles[key] then
                key = "affects"
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

        if key == "affects" and type(update_affects) == "function" then
                update_affects()
        elseif key == "quest" and type(update_quest_status) == "function" then
                update_quest_status()
        end
end

function dd_affects_tab_click(key, event)
        if event and event.button and event.button ~= "LeftButton" then
                return
        end

        if DD_GUI and DD_GUI.Affects then
                DD_GUI.Affects:switch_tab(key)
        end
end

function build_affects_box()
        if DD_GUI.AffectsTopRow and DD_GUI.AffectsTopRow.hide then
                DD_GUI.AffectsTopRow:hide()
        end

        if AffectsTitleLabel and AffectsTitleLabel.hide then
                AffectsTitleLabel:hide()
        end

        DD_GUI.AffectsTopRow = nil
        AffectsTitleLabel = nil
        DD_GUI.Affects:build_tabs()
end
