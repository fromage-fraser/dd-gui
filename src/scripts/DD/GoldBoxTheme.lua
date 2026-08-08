DD_GUI = DD_GUI or {}

DD_GUI.Theme = DD_GUI.Theme or {}
local Theme = DD_GUI.Theme

Theme.font = "Consolas"
Theme.colors = {
        ink = "rgb(0,0,0)",
        navy = "rgb(0,0,0)",
        panel = "rgb(0,0,0)",
        panel_alt = "rgb(0,0,0)",
        frame = "rgb(151,27,39)",
        bright_frame = "rgb(205,48,60)",
        frame_flash = "rgb(181,37,49)",
        dark_frame = "rgb(72,10,18)",
        gold = "rgb(196,161,78)",
        bright_gold = "rgb(239,210,118)",
        dark_gold = "rgb(105,82,36)",
        ivory = "rgb(240,235,213)",
        white = "rgb(255,255,255)",
        active_tab = "rgb(0,0,0)",
        muted = "rgb(153,160,174)",
        blue_grey = "rgb(72,91,123)",
        hp = "rgb(181,42,48)",
        mana = "rgb(46,92,184)",
        xp = "rgb(188,145,43)",
        moves = "rgb(38,139,126)",
        thirst = "rgb(35,112,153)",
        hunger = "rgb(145,103,34)",
}

Theme.map_info_frame = {151, 27, 39}

function Theme:panel_css(options)
        options = options or {}
        local background = options.background or self.colors.ink
        local border = options.border or self.colors.frame
        local margin = options.margin or 1

        return string.format([[
                background-color: %s;
                border-style: solid;
                border-width: 2px;
                border-color: %s;
                border-radius: 0px;
                margin: %dpx;
        ]], background, border, margin)
end

function Theme:band_css()
        return string.format([[
                background-color: %s;
                border: 0px;
                border-radius: 0px;
                margin: 0px;
        ]], self.colors.navy)
end

function Theme:tab_css(active, drop_target)
        if active then
                return string.format([[
                        background-color: %s;
                        color: %s;
                        border-style: outset;
                        border-width: 2px;
                        border-color: %s;
                        border-radius: 0px;
                        margin: 1px;
                ]], self.colors.active_tab, self.colors.white, self.colors.bright_frame)
        end

        if drop_target then
                return string.format([[
                        background-color: %s;
                        color: %s;
                        border-style: double;
                        border-width: 3px;
                        border-color: %s;
                        border-radius: 0px;
                        margin: 1px;
                ]], self.colors.panel_alt, self.colors.ivory, self.colors.bright_frame)
        end

        return string.format([[
                background-color: %s;
                color: %s;
                border-style: solid;
                border-width: 1px;
                border-color: %s;
                border-radius: 0px;
                margin: 1px;
        ]], self.colors.navy, self.colors.ivory, self.colors.dark_frame)
end

function Theme:gauge_back_css()
        return string.format([[
                background-color: %s;
                border-style: inset;
                border-width: 2px;
                border-color: %s;
                border-radius: 0px;
                padding: 0px;
        ]], self.colors.panel_alt, self.colors.dark_frame)
end

function Theme:gauge_front_css(color)
        return string.format([[
                background-color: %s;
                border-style: solid;
                border-width: 1px;
                border-color: %s;
                border-radius: 0px;
                padding: 0px;
        ]], color, self.colors.ink)
end

function Theme:image_frame_css()
        return string.format([[
                background-color: rgba(0,0,0,0);
                border-style: none;
                border-width: 0px;
                border-radius: 0px;
                margin: 0px;
        ]])
end

function Theme:compass_cell_css(hovered, blank)
        if blank then
                return string.format([[
                        background-color: %s;
                        border-style: inset;
                        border-width: 1px;
                        border-color: %s;
                        border-radius: 0px;
                        margin: 1px;
                ]], self.colors.ink, self.colors.dark_frame)
        end

        if hovered then
                return string.format([[
                        background-color: %s;
                        color: %s;
                        border-style: inset;
                        border-width: 2px;
                        border-color: %s;
                        border-radius: 0px;
                        margin: 1px;
                ]], self.colors.active_tab, self.colors.white, self.colors.bright_frame)
        end

        return string.format([[
                background-color: %s;
                color: %s;
                border-style: outset;
                border-width: 2px;
                border-color: %s;
                border-radius: 0px;
                margin: 1px;
        ]], self.colors.panel, self.colors.ivory, self.colors.frame)
end

function Theme:layout_outline_css(dragging)
        if dragging then
                return string.format([[
                        border-style: solid;
                        border-width: 3px;
                        border-color: %s;
                ]], self.colors.ivory)
        end

        return string.format([[
                border-style: dashed;
                border-width: 2px;
                border-color: %s;
        ]], self.colors.bright_gold)
end

function Theme:move_handle_css()
        return string.format([[
                background-color: %s;
                color: %s;
                border-style: solid;
                border-width: 1px;
                border-color: %s;
                border-radius: 0px;
                margin: 0px;
        ]], self.colors.gold, self.colors.ink, self.colors.bright_gold)
end

function Theme:style_label(label, size, bold)
        if not label then
                return
        end

        if type(label.setFont) == "function" then
                pcall(function() label:setFont(self.font) end)
        end
        if size and type(label.setFontSize) == "function" then
                label:setFontSize(size)
        end
        if bold ~= nil and type(label.setBold) == "function" then
                label:setBold(bold and 1 or 0)
        end
end

function Theme:style_console(console, size)
        if not console then
                return
        end

        if type(console.setFont) == "function" then
                pcall(function() console:setFont(self.font) end)
        end
        if size and type(console.setFontSize) == "function" then
                pcall(function() console:setFontSize(size) end)
        end
        if type(console.setColor) == "function" then
                pcall(function() console:setColor(0, 0, 0) end)
        end
end

function Theme:profile_style_sheet()
        local c = self.colors
        local function stylesheet_url(path)
                if not path then
                        return "none"
                end

                return 'url("' .. tostring(path):gsub("\\", "/")
                        :gsub('"', '\\"') .. '")'
        end

        local joiner = stylesheet_url(
                DD_GUI.asset_path and DD_GUI.asset_path("frame/node.png"))
        local menu_check = stylesheet_url(
                DD_GUI.asset_path and DD_GUI.asset_path("frame/menu-check.svg"))
        local menu_arrow = stylesheet_url(
                DD_GUI.asset_path and DD_GUI.asset_path("frame/menu-arrow.svg"))

        local console_stylesheet = string.format([[
                TConsole QScrollBar:vertical {
                        background-color: %s;
                        width: 10px;
                        margin: 0px;
                        border-left: 1px solid %s;
                        border-right: 1px solid %s;
                }
                TConsole QScrollBar::handle:vertical {
                        background-color: %s;
                        background-image: %s;
                        background-repeat: no-repeat;
                        background-position: center;
                        min-height: 20px;
                        border: 0px;
                }
                TConsole QScrollBar::handle:vertical:hover,
                TConsole QScrollBar::handle:vertical:pressed {
                        background-color: %s;
                        background-image: %s;
                        background-repeat: no-repeat;
                        background-position: center;
                }
                TConsole QScrollBar::add-line:vertical,
                TConsole QScrollBar::sub-line:vertical {
                        background: transparent;
                        height: 0px;
                        border: none;
                }
                TConsole QScrollBar::add-page:vertical,
                TConsole QScrollBar::sub-page:vertical {
                        background: transparent;
                }

                TConsole QScrollBar:horizontal {
                        background-color: %s;
                        height: 10px;
                        margin: 0px;
                        border-top: 1px solid %s;
                        border-bottom: 1px solid %s;
                }
                TConsole QScrollBar::handle:horizontal {
                        background-color: %s;
                        background-image: %s;
                        background-repeat: no-repeat;
                        background-position: center;
                        min-width: 20px;
                        border: 0px;
                }
                TConsole QScrollBar::handle:horizontal:hover,
                TConsole QScrollBar::handle:horizontal:pressed {
                        background-color: %s;
                        background-image: %s;
                        background-repeat: no-repeat;
                        background-position: center;
                }
                TConsole QScrollBar::add-line:horizontal,
                TConsole QScrollBar::sub-line:horizontal {
                        background: transparent;
                        width: 0px;
                        border: none;
                }
                TConsole QScrollBar::add-page:horizontal,
                TConsole QScrollBar::sub-page:horizontal {
                        background: transparent;
                }
                TConsole QScrollBar::corner {
                        background: %s;
                }
        ]],
                c.ink, c.dark_frame, c.dark_frame,
                c.ink, joiner, c.ink, joiner,
                c.ink, c.dark_frame, c.dark_frame,
                c.ink, joiner, c.ink, joiner,
                c.ink
        )

        local mapper_stylesheet = string.format([[
                QWidget#mapper,
                QWidget#widget_panel,
                QWidget#widget_topRow,
                QWidget#widget_panControls,
                TMapView {
                        background-color: %s;
                        border: 0px;
                }

                QWidget#mapper QToolButton,
                QWidget#widget_panel QToolButton,
                TMapView QToolButton {
                        background-color: %s;
                        color: %s;
                        border: 1px solid %s;
                        border-radius: 0px;
                        padding: 0px;
                        margin: 0px;
                }

                QWidget#mapper QToolButton:hover,
                QWidget#mapper QToolButton:focus,
                QWidget#mapper QToolButton:pressed,
                QWidget#mapper QToolButton:checked,
                QWidget#widget_panel QToolButton:hover,
                QWidget#widget_panel QToolButton:focus,
                QWidget#widget_panel QToolButton:pressed,
                QWidget#widget_panel QToolButton:checked,
                TMapView QToolButton:hover,
                TMapView QToolButton:focus,
                TMapView QToolButton:pressed,
                TMapView QToolButton:checked {
                        background-color: %s;
                        color: %s;
                        border-color: %s;
                }

                QWidget#mapper QLabel#label_area,
                QWidget#widget_panel QLabel#label_area,
                TMapView QLabel {
                        background-color: %s;
                        color: %s;
                        border: 0px;
                        padding: 0px;
                }

                QWidget#mapper QComboBox,
                QWidget#widget_panel QComboBox,
                TMapView QComboBox {
                        background-color: %s;
                        color: %s;
                        border: 1px solid %s;
                        border-radius: 0px;
                        padding: 0px 2px;
                        selection-background-color: %s;
                        selection-color: %s;
                }

                QWidget#mapper QComboBox:hover,
                QWidget#mapper QComboBox:focus,
                QWidget#widget_panel QComboBox:hover,
                QWidget#widget_panel QComboBox:focus,
                TMapView QComboBox:hover,
                TMapView QComboBox:focus {
                        border-color: %s;
                }

                QWidget#mapper QComboBox::drop-down,
                QWidget#widget_panel QComboBox::drop-down,
                TMapView QComboBox::drop-down {
                        background-color: %s;
                        border-left: 1px solid %s;
                        width: 16px;
                }

                QWidget#mapper QComboBox QAbstractItemView,
                QWidget#widget_panel QComboBox QAbstractItemView,
                TMapView QComboBox QAbstractItemView {
                        background-color: %s;
                        color: %s;
                        border: 1px solid %s;
                        selection-background-color: %s;
                        selection-color: %s;
                }
        ]],
                c.ink,
                c.ink, c.ivory, c.frame,
                c.dark_frame, c.white, c.bright_frame,
                c.ink, c.ivory,
                c.ink, c.ivory, c.frame, c.dark_frame, c.white,
                c.bright_frame,
                c.ink, c.dark_frame,
                c.ink, c.ivory, c.frame, c.dark_frame, c.white
        )

        local popup_stylesheet = string.format([[
                QMenu {
                        background-color: %s;
                        color: %s;
                        border: 1px solid %s;
                        padding: 2px;
                }

                QMenu::item {
                        background-color: transparent;
                        color: %s;
                        border: 1px solid transparent;
                        padding: 4px 28px 4px 24px;
                        margin: 1px 2px;
                }

                QMenu::item:selected,
                QMenu::item:pressed {
                        background-color: %s;
                        color: %s;
                        border-color: %s;
                }

                QMenu::item:disabled {
                        color: %s;
                }

                QMenu::separator {
                        height: 1px;
                        background-color: %s;
                        margin: 4px 5px;
                }

                QMenu::indicator {
                        width: 12px;
                        height: 12px;
                        margin-left: 5px;
                        margin-right: 3px;
                        background-color: %s;
                        border: 1px solid %s;
                }

                QMenu::indicator:checked,
                QMenu::indicator:non-exclusive:checked,
                QMenu::indicator:exclusive:checked,
                QMenu::indicator:indeterminate {
                        background-color: %s;
                        border: 0px;
                        image: %s;
                }

                QMenu::right-arrow {
                        width: 8px;
                        height: 8px;
                        image: %s;
                }
        ]],
                c.ink, c.ivory, c.frame,
                c.ivory,
                c.dark_frame, c.white, c.bright_frame,
                c.dark_gold,
                c.frame,
                c.ink, c.frame,
                c.ink, menu_check,
                menu_arrow
        )

        return console_stylesheet .. mapper_stylesheet .. popup_stylesheet
end

function Theme:apply_profile_style()
        if type(setProfileStyleSheet) ~= "function" then
                return false
        end

        local ok, err = pcall(function()
                setProfileStyleSheet(self:profile_style_sheet())
        end)
        if not ok then
                DD_GUI.profile_style_error = tostring(err)
                return false
        end

        DD_GUI.profile_style_error = nil
        return true
end

local function set_clickthrough(widget, enabled)
        if not widget then
                return
        end

        local method
        if enabled then
                method = widget.enableClickthrough
        else
                method = widget.disableClickthrough
        end
        if type(method) == "function" then
                pcall(function() method(widget) end)
                return
        end

        local global_method
        if enabled then
                global_method = enableClickthrough
        else
                global_method = disableClickthrough
        end
        if type(global_method) == "function" and widget.name then
                pcall(global_method, widget.name)
        end
end

DD_GUI.set_widget_clickthrough = set_clickthrough

DD_GUI.Layout = DD_GUI.Layout or {}
local Layout = DD_GUI.Layout
Layout.enabled = false

function Layout:each_box(callback)
        if not Adjustable or not Adjustable.Container or
           not Adjustable.Container.all then
                return
        end

        for _, box in pairs(Adjustable.Container.all) do
                if box and box._dd_gui_adjustable then
                        callback(box)
                end
        end
end

function Layout:apply_box(box)
        if not box or not box.adjLabel then
                return
        end

        -- Major panels are controlled by shared frame splitters. Their
        -- Adjustable.Container overlay must stay transparent so the frame
        -- never masks tabs, consoles, or the compass.
        local grid_managed = DD_GUI.FrameGrid and
                DD_GUI.FrameGrid.is_frame_box and
                DD_GUI.FrameGrid:is_frame_box(box)
        set_clickthrough(box.adjLabel, grid_managed and true or not self.enabled)
        if DD_GUI.hide_adjustable_controls then
                DD_GUI.hide_adjustable_controls(box)
        end
        if grid_managed then
                box._dd_gui_dragging = false
                box.adjLabel:setStyleSheet(box._dd_gui_base_style or "")
        elseif DD_GUI.refresh_adjustable_style then
                DD_GUI.refresh_adjustable_style(box)
        end
end

function Layout:apply_compass()
        if not compass or not compass.handle then
                return
        end

        if self.enabled then
                compass.handle:show()
                set_clickthrough(compass.handle, false)
                compass.handle:setStyleSheet(Theme:move_handle_css())
                compass.handle:echo("MOVE", "black", "c")
                compass.handle:setCursor("OpenHand")
                compass.handle:raise()
        else
                set_clickthrough(compass.handle, true)
                compass.handle:hide()
        end
end

function Layout:apply(enabled)
        if enabled ~= nil then
                self.enabled = enabled == true
        end

        self:each_box(function(box)
                self:apply_box(box)
        end)
        if DD_GUI.FrameGrid and DD_GUI.FrameGrid.set_enabled then
                DD_GUI.FrameGrid:set_enabled(self.enabled)
        end
        self:apply_compass()

        if DD_GUI.raise_info_box_contents then
                DD_GUI.raise_info_box_contents()
        end
end

function Layout:save()
        self:each_box(function(box)
                if type(box.save) == "function" then
                        pcall(function() box:save() end)
                end
        end)
end

function Layout:set_enabled(enabled)
        self.enabled = enabled == true
        self:apply()
        if not self.enabled then
                self:save()
        end
        return self.enabled
end

function Layout:command(raw_mode)
        local mode = tostring(raw_mode or ""):lower()
        mode = mode:gsub("^%s+", ""):gsub("%s+$", "")

        local enabled
        if mode == "on" then
                enabled = true
        elseif mode == "off" then
                enabled = false
        else
                enabled = not self.enabled
        end

        self:set_enabled(enabled)
        if enabled then
                cecho("\n<gold>DD_GUI layout mode: <white>ON<reset> - drag the shared red frame edges to resize adjacent regions.\n")
        else
                cecho("\n<gold>DD_GUI layout mode: <white>OFF<reset> - controls are locked and input passes through.\n")
        end
end
