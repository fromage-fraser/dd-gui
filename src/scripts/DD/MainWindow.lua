function ui_container()

        -- interfacescript
        --------------------------------
        ui = ui or {} -- user interface related stuff goes into this table

        -- Container used to get console position
        ui.mainconsole_container = Geyser.Container:new({
                name = "mainconsole_container",
                x="4%", y="38%",
                width="75%", height="56%",
        })


        -- function called by the temptimer to do the work
        function ui.updateBorderSizes()
                local w,h = getMainWindowSize()
                -- Only update if window size have changed!
                if( w ~= ui.window_width or h ~= ui.window_height ) then
                        ui.window_width = w
                        ui.window_height = h

                        local cx = ui.mainconsole_container:get_x()
                        local cy = ui.mainconsole_container:get_y()
                        local cw = ui.mainconsole_container:get_width()
                        local ch = ui.mainconsole_container:get_height()

                        setBorderLeft(tonumber(cx))
                        setBorderTop(tonumber(cy))
                        setBorderRight(tonumber(w-cx-cw))
                        setBorderBottom(tonumber(h-cy-ch))
                end
        end

        -- sysWindowResizeEvent handler
        function ui.updatecontent( event, x, y )
                if( ui.eventtimer ) then killTimer( ui.eventtimer ) end
                ui.eventtimer = tempTimer(0, [[killTimer( "ui.eventtimer" ) ui.updateBorderSizes()]])
        end

        -- register our function as an event handler
        registerAnonymousEventHandler("sysWindowResizeEvent", "ui.updatecontent")
end
            