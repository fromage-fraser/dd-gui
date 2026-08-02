DD_GUI = DD_GUI or {}
DD_GUI.Affects = DD_GUI.Affects or {}

function DD_GUI.Affects:tab_css()
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

        self.tab_rail = Geyser.Label:new({
                name = "DD_GUI.Affects.TabRail",
                x = "4%",
                y = "3%",
                width = "92%",
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
        self.tab_button:setFontSize(8)
        self.tab_button:setBold(1)
        self.tab_button:setStyleSheet(self:tab_css())
        self.tab_button:echo("Affects", "white", "c")
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
