DD_GUI = DD_GUI or {}

local function reset_adjustable_box(box, x, y, width, height)
        if not box then
                return
        end

        -- User resizing can leave a container locked, minimized, or attached
        -- to another border. Clear those states before applying the defaults.
        if type(box.disconnect) == "function" then
                pcall(function() box:disconnect() end)
        end
        if type(box.detach) == "function" then
                pcall(function() box:detach() end)
        end
        if type(box.restore) == "function" then
                pcall(function() box:restore() end)
        end
        if type(box.unlockContainer) == "function" then
                pcall(function() box:unlockContainer() end)
        end
        if type(box.show) == "function" then
                box:show()
        end
        if DD_GUI.hide_adjustable_controls then
                DD_GUI.hide_adjustable_controls(box)
        end

        box:move(x, y)
        box:resize(width, height)

        if DD_GUI.set_adjustable_drag_outline then
                DD_GUI.set_adjustable_drag_outline(box, false)
        end
        if type(box.save) == "function" then
                box:save()
        end
end

local function approximately(value, target, tolerance)
        return value and math.abs(value - target) <= tolerance
end

function DD_GUI.migrate_layout_defaults()
        if not DD_GUI.Right or not DD_GUI.Right.get_x or
           not DD_GUI.Right.get_width or type(getMainWindowSize) ~= "function" then
                return false
        end

        local window_width, window_height = getMainWindowSize()
        local right_x = tonumber(DD_GUI.Right:get_x()) or 0
        local right_width = tonumber(DD_GUI.Right:get_width()) or 0
        local right_y = DD_GUI.Right.get_y and
                tonumber(DD_GUI.Right:get_y()) or nil
        local right_height = DD_GUI.Right.get_height and
                tonumber(DD_GUI.Right:get_height()) or nil
        local top_y = DD_GUI.Top and DD_GUI.Top.get_y and
                tonumber(DD_GUI.Top:get_y()) or nil
        local top_height = DD_GUI.Top and DD_GUI.Top.get_height and
                tonumber(DD_GUI.Top:get_height()) or nil
        local bottom_y = DD_GUI.Bottom and DD_GUI.Bottom.get_y and
                tonumber(DD_GUI.Bottom:get_y()) or nil
        local bottom_height = DD_GUI.Bottom and DD_GUI.Bottom.get_height and
                tonumber(DD_GUI.Bottom:get_height()) or nil
        local legacy_default = false
        local changed = false
        local inventory_width = DD_GUI.InventoryBox and DD_GUI.InventoryBox.get_width and
                tonumber(DD_GUI.InventoryBox:get_width()) or nil
        local affect_width = DD_GUI.AffectBox and DD_GUI.AffectBox.get_width and
                tonumber(DD_GUI.AffectBox:get_width()) or nil

        local map_x = DD_GUI.MapBox and DD_GUI.MapBox.get_x and
                tonumber(DD_GUI.MapBox:get_x()) or nil
        local map_width = DD_GUI.MapBox and DD_GUI.MapBox.get_width and
                tonumber(DD_GUI.MapBox:get_width()) or nil
        local char_x = DD_GUI.CharsheetBox and DD_GUI.CharsheetBox.get_x and
                tonumber(DD_GUI.CharsheetBox:get_x()) or nil
        local char_width = DD_GUI.CharsheetBox and DD_GUI.CharsheetBox.get_width and
                tonumber(DD_GUI.CharsheetBox:get_width()) or nil
        local map_y = DD_GUI.MapBox and DD_GUI.MapBox.get_y and
                tonumber(DD_GUI.MapBox:get_y()) or nil
        local map_height = DD_GUI.MapBox and DD_GUI.MapBox.get_height and
                tonumber(DD_GUI.MapBox:get_height()) or nil
        local char_y = DD_GUI.CharsheetBox and DD_GUI.CharsheetBox.get_y and
                tonumber(DD_GUI.CharsheetBox:get_y()) or nil
        local char_height = DD_GUI.CharsheetBox and DD_GUI.CharsheetBox.get_height and
                tonumber(DD_GUI.CharsheetBox:get_height()) or nil

        local main_x = ui and ui.mainconsole_container and
                ui.mainconsole_container.get_x and
                tonumber(ui.mainconsole_container:get_x()) or nil
        local main_y = ui and ui.mainconsole_container and
                ui.mainconsole_container.get_y and
                tonumber(ui.mainconsole_container:get_y()) or nil
        local main_width = ui and ui.mainconsole_container and
                ui.mainconsole_container.get_width and
                tonumber(ui.mainconsole_container:get_width()) or nil
        local main_height = ui and ui.mainconsole_container and
                ui.mainconsole_container.get_height and
                tonumber(ui.mainconsole_container:get_height()) or nil

        local bottom_width = DD_GUI.Bottom and DD_GUI.Bottom.get_width and
                tonumber(DD_GUI.Bottom:get_width()) or window_width * 0.72
        local gauge_columns = {
                DD_GUI.FirstColumn,
                DD_GUI.SecondColumn,
                DD_GUI.ThirdColumn,
                DD_GUI.FourthColumn,
        }

        -- Migrate only shipped geometries so user-customized layouts remain
        -- untouched while the map receives the recovered space.
        local legacy_top_layout =
                approximately(map_x, window_width * 0.27, 8) and
                approximately(map_width, window_width * 0.16, 8) and
                approximately(char_x, window_width * 0.43, 8) and
                approximately(char_width, window_width * 0.23, 8)
        local previous_top_layout =
                approximately(map_x, window_width * 0.27, 8) and
                approximately(map_width, window_width * 0.20, 8) and
                approximately(char_x, window_width * 0.47, 8) and
                approximately(char_width, window_width * 0.19, 8)

        local current_top_layout =
                approximately(map_x, window_width * 0.27, 8) and
                approximately(map_width, window_width * 0.27, 8) and
                approximately(map_y, window_height * 0.0612, 8) and
                approximately(map_height, window_height * 0.2988, 8) and
                approximately(char_x, window_width * 0.54, 8) and
                approximately(char_width, window_width * 0.18, 8) and
                approximately(char_y, window_height * 0.0612, 8) and
                approximately(char_height, window_height * 0.2988, 8)
        if legacy_top_layout or previous_top_layout or current_top_layout then
                reset_adjustable_box(DD_GUI.EnemyBox, "4%", "0%", "23%", "100%")
                reset_adjustable_box(DD_GUI.MapBox, "27%", "0%", "27%", "100%")
                reset_adjustable_box(DD_GUI.CharsheetBox, "54%", "0%", "18%", "100%")
                reset_adjustable_box(DD_GUI.ChannelBox, "72%", "0%", "25%", "100%")
                changed = true
        end

        local legacy_main_layout =
                approximately(main_x, window_width * 0.04, 8) and
                approximately(main_y, window_height * 0.38, 8) and
                approximately(main_width, window_width * 0.68, 8) and
                approximately(main_height, window_height * 0.56, 8)
        local previous_main_layout =
                approximately(main_x, window_width * 0.04, 8) and
                approximately(main_y, window_height * 0.36, 8) and
                approximately(main_width, window_width * 0.68, 8) and
                approximately(main_height, window_height * 0.58, 8)
        if legacy_main_layout or previous_main_layout then
                reset_adjustable_box(
                        ui and ui.mainconsole_container,
                        "4%", "36%", "68%", "57%"
                )
                changed = true
        end

        local previous_outer_layout =
                approximately(top_y, 0, 8) and
                approximately(top_height, window_height * 0.36, 8) and
                approximately(right_y, 0, 8) and
                approximately(right_height, window_height, 8) and
                approximately(bottom_y, window_height * 0.94, 8) and
                approximately(bottom_height, window_height * 0.06, 8)
        local current_outer_layout =
                approximately(top_y, window_height * 0.02, 8) and
                approximately(top_height, window_height * 0.34, 8) and
                approximately(right_y, window_height * 0.02, 8) and
                approximately(right_height, window_height * 0.96, 8) and
                approximately(bottom_y, window_height * 0.93, 8) and
                approximately(bottom_height, window_height * 0.05, 8)
        if previous_outer_layout or current_outer_layout then
                reset_adjustable_box(DD_GUI.Top, "0%", "3%", "100%", "33%")
                reset_adjustable_box(DD_GUI.Right, "-28%", "3%", "28%", "94%")
                reset_adjustable_box(DD_GUI.Bottom, "0%", "93%", "72%", "4%")
                changed = true
        end

        local old_gauge_columns = true
        local old_gauge_positions = { 0.05, 0.285, 0.52, 0.755 }
        local current_gauge_columns = true
        local current_gauge_positions = { 0.0556, 0.2917, 0.5278, 0.7639 }
        for index, column in ipairs(gauge_columns) do
                local column_x = column and column.get_x and
                        tonumber(column:get_x()) or nil
                local column_width = column and column.get_width and
                        tonumber(column:get_width()) or nil
                local matches_old = column and column.get_x and
                        column.get_width and
                        approximately(
                                column_x,
                                bottom_width * old_gauge_positions[index],
                                8
                        ) and approximately(
                                column_width,
                                bottom_width * 0.235,
                                8
                        )
                local matches_current = column and column.get_x and
                        column.get_width and
                        approximately(
                                column_x,
                                bottom_width * current_gauge_positions[index],
                                8
                        ) and approximately(
                                column_width,
                                bottom_width * 0.2361,
                                8
                        )
                if not matches_old then
                        old_gauge_columns = false
                end
                if not matches_current then
                        current_gauge_columns = false
                end
        end
        if old_gauge_columns or current_gauge_columns then
                local new_gauge_columns = {
                        { "5.56%", "23.61%" },
                        { "29.17%", "23.61%" },
                        { "52.78%", "23.61%" },
                        { "76.39%", "23.61%" },
                }
                for index, column in ipairs(gauge_columns) do
                        reset_adjustable_box(
                                column,
                                new_gauge_columns[index][1],
                                "0%",
                                new_gauge_columns[index][2],
                                "100%"
                        )
                end
                changed = true
        end

        if approximately(inventory_width, right_width * 0.91, 8) and
           approximately(affect_width, right_width * 0.91, 8) then
                reset_adjustable_box(
                        DD_GUI.InventoryBox,
                        "0%", "35.11%", "89.29%", "36.17%"
                )
                reset_adjustable_box(
                        DD_GUI.AffectBox,
                        "0%", "71.28%", "89.29%", "28.72%"
                )
                changed = true
        end

        -- Existing profiles may have saved one of the previous shipped
        -- defaults. Only migrate those exact layouts; custom panel sizes and
        -- positions remain untouched.
        for _, legacy in ipairs({
                { x = 0.74, width = 0.26 },
                { x = 0.68, width = 0.32 },
                { x = 0.66, width = 0.34 },
        }) do
                if approximately(right_x, window_width * legacy.x, 12) and
                   approximately(right_width, window_width * legacy.width, 12) then
                        legacy_default = true
                        break
                end
        end

        if compass and compass.back and compass.back.get_x and
           compass.back.get_y then
                local compass_x = tonumber(compass.back:get_x()) or 0
                local compass_y = tonumber(compass.back:get_y()) or 0
                local legacy_compass =
                        tostring(compass.back.x) == "60%" and
                        tostring(compass.back.y) == "82%"
                local shipped_compass =
                        tostring(compass.back.x) == "52%" and
                        tostring(compass.back.y) == "70%" and
                        (tostring(compass.back.width) == "8%" or
                                tostring(compass.back.width) == "9%" or
                                tostring(compass.back.width) == "11%")
                if legacy_compass or
                   shipped_compass or
                   (approximately(compass_x, window_width * 0.60, 2) and
                    approximately(compass_y, window_height * 0.82, 2)) then
                        compass.back:move("54%", "70%")
                        compass.back:resize("11%", "11%")
                        if compass.back.get_width then
                                compass.back:resize("11%", compass.back:get_width())
                        end
                        if compass.back.save then
                                compass.back:save()
                        end
                        changed = true
                end
        end

        if not legacy_default then
                if changed and DD_GUI.raise_info_box_contents then
                        DD_GUI.raise_info_box_contents()
                end
                return changed
        end

        local defaults = {
                { ui and ui.mainconsole_container, "4%", "36%", "68%", "57%" },
                { DD_GUI.Right, "-28%", "3%", "28%", "94%" },
                { DD_GUI.Bottom, "0%", "93%", "72%", "4%" },
                { DD_GUI.FirstColumn, "5.56%", "0%", "23.61%", "100%" },
                { DD_GUI.SecondColumn, "29.17%", "0%", "23.61%", "100%" },
                { DD_GUI.ThirdColumn, "52.78%", "0%", "23.61%", "100%" },
                { DD_GUI.FourthColumn, "76.39%", "0%", "23.61%", "100%" },
                { DD_GUI.EnemyBox, "4%", "0%", "23%", "100%" },
                { DD_GUI.MapBox, "27%", "0%", "27%", "100%" },
                { DD_GUI.CharsheetBox, "54%", "0%", "18%", "100%" },
                { DD_GUI.ChannelBox, "72%", "0%", "25%", "100%" },
                { DD_GUI.InventoryBox, "0%", "35.11%", "89.29%", "36.17%" },
                { DD_GUI.AffectBox, "0%", "71.28%", "89.29%", "28.72%" },
        }

        for _, default_box in ipairs(defaults) do
                reset_adjustable_box(
                        default_box[1],
                        default_box[2],
                        default_box[3],
                        default_box[4],
                        default_box[5]
                )
        end
        changed = true

        if ui and ui.updateBorderSizes then
                ui.window_width = nil
                ui.updateBorderSizes()
        end

        if DD_GUI.raise_info_box_contents then
                DD_GUI.raise_info_box_contents()
        end

        if DD_GUI.FrameGrid and DD_GUI.FrameGrid.schedule_refresh then
                DD_GUI.FrameGrid:schedule_refresh(0.02)
        end

        return changed
end

function DD_GUI.reset_layout()
        local defaults = {
                { ui and ui.mainconsole_container, "4%", "36%", "68%", "57%" },
                { DD_GUI.Right, "-28%", "3%", "28%", "94%" },
                { DD_GUI.Top, "0%", "3%", "100%", "33%" },
                { DD_GUI.Bottom, "0%", "93%", "72%", "4%" },
                { DD_GUI.FirstColumn, "5.56%", "0%", "23.61%", "100%" },
                { DD_GUI.SecondColumn, "29.17%", "0%", "23.61%", "100%" },
                { DD_GUI.ThirdColumn, "52.78%", "0%", "23.61%", "100%" },
                { DD_GUI.FourthColumn, "76.39%", "0%", "23.61%", "100%" },
                { DD_GUI.EnemyBox, "4%", "0%", "23%", "100%" },
                { DD_GUI.MapBox, "27%", "0%", "27%", "100%" },
                { DD_GUI.CharsheetBox, "54%", "0%", "18%", "100%" },
                { DD_GUI.ChannelBox, "72%", "0%", "25%", "100%" },
                { DD_GUI.InventoryBox, "0%", "35.11%", "89.29%", "36.17%" },
                { DD_GUI.AffectBox, "0%", "71.28%", "89.29%", "28.72%" },
        }

        for _, default_box in ipairs(defaults) do
                reset_adjustable_box(
                        default_box[1],
                        default_box[2],
                        default_box[3],
                        default_box[4],
                        default_box[5]
                )
        end

        if compass and compass.back then
                reset_adjustable_box(compass.back, "54%", "70%", "11%", "11%")

                -- Keep the default compass square even when the terminal is
                -- not square. Its width remains responsive while its height
                -- is stored in pixels to preserve the intended aspect ratio.
                if type(compass.back.get_width) == "function" then
                        compass.back:resize("11%", compass.back:get_width())
                        if type(compass.back.save) == "function" then
                                compass.back:save()
                        end
                end
        end

        if ui and ui.updateBorderSizes then
                ui.window_width = nil
                ui.updateBorderSizes()
        end

        if DD_GUI.raise_info_box_contents then
                DD_GUI.raise_info_box_contents()
        end

        if DD_GUI.Layout then
                DD_GUI.Layout:apply()
        end
        if DD_GUI.FrameGrid and DD_GUI.FrameGrid.schedule_refresh then
                DD_GUI.FrameGrid:schedule_refresh(0.02)
        end
end
