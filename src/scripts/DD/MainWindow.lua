function ui_container()

        -- interfacescript
        --------------------------------
        ui = ui or {} -- user interface related stuff goes into this table

        -- Transparent adjustable overlay used to define the main MUD console area.
        local mainconsole_constraints = {
                name = "DD_GUI.MainConsole",
                x = "4%", y = "38%",
                width = "75%", height = "56%",
        }

        ui.mainconsole_container = DD_GUI.new_adjustable_container and
                DD_GUI.new_adjustable_container(mainconsole_constraints) or
                Geyser.Container:new(mainconsole_constraints)

        function ui.updateBorderSizes()
                if not ui.mainconsole_container then
                        return
                end

                local w, h = getMainWindowSize()
                local cx = tonumber(ui.mainconsole_container:get_x()) or 0
                local cy = tonumber(ui.mainconsole_container:get_y()) or 0
                local cw = tonumber(ui.mainconsole_container:get_width()) or w
                local ch = tonumber(ui.mainconsole_container:get_height()) or h

                local left = math.max(0, cx)
                local top = math.max(0, cy)
                local right = math.max(0, w - cx - cw)
                local bottom = math.max(0, h - cy - ch)

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
