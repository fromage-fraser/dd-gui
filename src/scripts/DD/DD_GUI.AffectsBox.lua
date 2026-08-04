DD_GUI = DD_GUI or {}
DD_GUI.Affects = DD_GUI.Affects or {}

function DD_GUI.Affects:tab_css()
        if DD_GUI.Theme then
                return DD_GUI.Theme:tab_css(true)
        end

        return [[
                background-color: rgba(0,120,135,190);
                border-style: solid;
                border-width: 1px;
                border-color: cyan;
                margin: 1px;
        ]]
end

function DD_GUI.Affects:build_tabs()
        if self.tab_rail and self.tab_rail.hide then
                self.tab_rail:hide()
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

        self.tab_rail = Geyser.Label:new({
                name = "DD_GUI.Affects.TabRail",
                x = "2%",
                y = "3%",
                width = "96%",
                height = "10%",
        }, DD_GUI.AffectBox)
        self.tab_rail:setColor(0, 0, 0, 0)

        self.tab_button = Geyser.Label:new({
                name = "DD_GUI.Affects.Tab",
                x = "0%",
                y = "0%",
                width = "100%",
                height = "100%",
        }, self.tab_rail)
        if DD_GUI.Theme then
                DD_GUI.Theme:style_label(self.tab_button, 8, true)
        else
                self.tab_button:setFontSize(8)
                self.tab_button:setBold(1)
        end
        self.tab_button:setStyleSheet(self:tab_css())
        self.tab_button:echo("Affects", "black", "c")
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
