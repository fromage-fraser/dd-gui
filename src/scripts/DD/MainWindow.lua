function dd_gui_main_console_wheel(event)
        local delta = tonumber(event and event.angleDeltaY) or 0
        if delta == 0 then
                return
        end

        local lines = math.max(1, math.floor(math.abs(delta) / 40))
        if delta > 0 then
                scrollUp("main", lines)
        else
                scrollDown("main", lines)
        end
end

DD_GUI = DD_GUI or {}
DD_GUI.mainconsole_padding = 8

function ui_container()

        -- interfacescript
        --------------------------------
        ui = ui or {} -- user interface related stuff goes into this table

        -- Transparent adjustable overlay used to define the main MUD console area.
        local mainconsole_constraints = {
                name = "DD_GUI.MainConsole",
                x = "4%", y = "38%",
                width = "66%", height = "56%",
        }

        ui.mainconsole_container = DD_GUI.new_adjustable_container and
                DD_GUI.new_adjustable_container(mainconsole_constraints) or
                Geyser.Container:new(mainconsole_constraints)

        if ui.mainconsole_container.setStyleSheet and DD_GUI.Theme then
                ui.mainconsole_container:setStyleSheet(
                        DD_GUI.Theme:panel_css({ background = "rgba(0,0,0,0)" })
                )
        end

        if ui.mainconsole_frame and ui.mainconsole_frame.delete then
                ui.mainconsole_frame:delete()
        end
        local mainconsole_parent = ui.mainconsole_container.Inside or
                ui.mainconsole_container
        ui.mainconsole_frame = Geyser.Label:new({
                name = "DD_GUI.MainConsole.Frame",
                x = "0%", y = "0%",
                width = "100%", height = "100%",
        }, mainconsole_parent)
        ui.mainconsole_frame:setStyleSheet(DD_GUI.Theme and
                DD_GUI.Theme:image_frame_css() or [[
                        background-color: rgba(0,0,0,0);
                        border: 2px solid rgb(151,27,39);
                        border-radius: 0px;
                        margin: 0px;
                ]])
        if DD_GUI.set_widget_clickthrough then
                DD_GUI.set_widget_clickthrough(ui.mainconsole_frame, true)
        end

        if ui.mainconsole_container.adjLabel then
                ui.mainconsole_container.adjLabel:setWheelCallback(
                        "dd_gui_main_console_wheel"
                )
        end

        function ui.updateBorderSizes()
                if not ui.mainconsole_container then
                        return
                end

                local w, h = getMainWindowSize()
                local cx = tonumber(ui.mainconsole_container:get_x()) or 0
                local cy = tonumber(ui.mainconsole_container:get_y()) or 0
                local cw = tonumber(ui.mainconsole_container:get_width()) or w
                local ch = tonumber(ui.mainconsole_container:get_height()) or h

                local padding = tonumber(DD_GUI.mainconsole_padding) or 8
                local left = math.max(0, cx + padding)
                local top = math.max(0, cy + padding)
                local right = math.max(0, w - cx - cw + padding)
                local bottom = math.max(0, h - cy - ch + padding)

                if w ~= ui.window_width or h ~= ui.window_height or
                   left ~= ui.border_left or top ~= ui.border_top or
                   right ~= ui.border_right or bottom ~= ui.border_bottom then
                        ui.window_width = w
                        ui.window_height = h
                        ui.border_left = left
                        ui.border_top = top
                        ui.border_right = right
                        ui.border_bottom = bottom

                        setBorderLeft(left)
                        setBorderTop(top)
                        setBorderRight(right)
                        setBorderBottom(bottom)
                end
        end

        -- Defer border changes until the adjustable container has finished updating.
        function ui.updatecontent()
                if ui.eventtimer then
                        killTimer(ui.eventtimer)
                end

                ui.eventtimer = tempTimer(0, function()
                        ui.eventtimer = nil
                        ui.updateBorderSizes()
                end)
        end

        if not ui.handlers_registered then
                registerAnonymousEventHandler("sysWindowResizeEvent", ui.updatecontent)
                registerAnonymousEventHandler("AdjustableContainerReposition", ui.updatecontent)
                ui.handlers_registered = true
        end

        -- set_borders() establishes the legacy defaults before this container exists.
        -- Force one calculation so a saved layout is applied immediately on login.
        ui.window_width = nil
        ui.updateBorderSizes()
end
