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
        local legacy_default = false
        local changed = false

        local map_x = DD_GUI.MapBox and DD_GUI.MapBox.get_x and
                tonumber(DD_GUI.MapBox:get_x()) or nil
        local map_width = DD_GUI.MapBox and DD_GUI.MapBox.get_width and
                tonumber(DD_GUI.MapBox:get_width()) or nil
        local char_x = DD_GUI.CharsheetBox and DD_GUI.CharsheetBox.get_x and
                tonumber(DD_GUI.CharsheetBox:get_x()) or nil
        local char_width = DD_GUI.CharsheetBox and DD_GUI.CharsheetBox.get_width and
                tonumber(DD_GUI.CharsheetBox:get_width()) or nil

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
        if legacy_top_layout or previous_top_layout then
                reset_adjustable_box(DD_GUI.MapBox, "27%", "17%", "27%", "83%")
                reset_adjustable_box(DD_GUI.CharsheetBox, "54%", "17%", "18%", "83%")
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
                if legacy_compass or
                   (approximately(compass_x, window_width * 0.60, 2) and
                    approximately(compass_y, window_height * 0.82, 2)) then
                        compass.back:move("52%", "70%")
                        compass.back:resize("8%", "8%")
                        if compass.back.get_width then
                                compass.back:resize("8%", compass.back:get_width())
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
                { ui and ui.mainconsole_container, "4%", "38%", "68%", "56%" },
                { DD_GUI.Right, "-28%", "0%", "28%", "100%" },
                { DD_GUI.Bottom, "0%", "94%", "72%", "6%" },
                { DD_GUI.EnemyBox, "4%", "17%", "23%", "83%" },
                { DD_GUI.MapBox, "27%", "17%", "27%", "83%" },
                { DD_GUI.CharsheetBox, "54%", "17%", "18%", "83%" },
                { DD_GUI.ChannelBox, "72%", "17%", "25%", "83%" },
                { DD_GUI.InventoryBox, "0%", "36%", "91%", "34%" },
                { DD_GUI.AffectBox, "0%", "70%", "91%", "30%" },
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

        return changed
end

function DD_GUI.reset_layout()
        local defaults = {
                { ui and ui.mainconsole_container, "4%", "38%", "68%", "56%" },
                { DD_GUI.Right, "-28%", "0%", "28%", "100%" },
                { DD_GUI.Top, "0%", "0%", "100%", "36%" },
                { DD_GUI.Bottom, "0%", "94%", "72%", "6%" },
                { DD_GUI.FirstColumn, "5%", "0%", "23.5%", "100%" },
                { DD_GUI.SecondColumn, "28.5%", "0%", "23.5%", "100%" },
                { DD_GUI.ThirdColumn, "52%", "0%", "23.5%", "100%" },
                { DD_GUI.FourthColumn, "75.5%", "0%", "23.5%", "100%" },
                { DD_GUI.EnemyBox, "4%", "17%", "23%", "83%" },
                { DD_GUI.MapBox, "27%", "17%", "27%", "83%" },
                { DD_GUI.CharsheetBox, "54%", "17%", "18%", "83%" },
                { DD_GUI.ChannelBox, "72%", "17%", "25%", "83%" },
                { DD_GUI.InventoryBox, "0%", "36%", "91%", "34%" },
                { DD_GUI.AffectBox, "0%", "70%", "91%", "30%" },
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
                reset_adjustable_box(compass.back, "52%", "70%", "8%", "8%")

                -- Keep the default compass square even when the terminal is
                -- not square. Its width remains responsive while its height
                -- is stored in pixels to preserve the intended aspect ratio.
                if type(compass.back.get_width) == "function" then
                        compass.back:resize("8%", compass.back:get_width())
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
end
