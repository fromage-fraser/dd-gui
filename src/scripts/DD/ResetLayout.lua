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

        local window_width = getMainWindowSize()
        local right_x = tonumber(DD_GUI.Right:get_x()) or 0
        local right_width = tonumber(DD_GUI.Right:get_width()) or 0
        local legacy_default = false

        -- Existing profiles may have saved one of the previous shipped
        -- defaults. Only migrate those exact layouts; custom panel sizes and
        -- positions remain untouched.
        for _, legacy in ipairs({
                { x = 0.74, width = 0.26 },
                { x = 0.72, width = 0.28 },
                { x = 0.68, width = 0.32 },
                { x = 0.66, width = 0.34 },
        }) do
                if approximately(right_x, window_width * legacy.x, 2) and
                   approximately(right_width, window_width * legacy.width, 2) then
                        legacy_default = true
                        break
                end
        end

        if not legacy_default then
                return false
        end

        local defaults = {
                { ui and ui.mainconsole_container, "4%", "38%", "62%", "56%" },
                { DD_GUI.Right, "-34%", "0%", "34%", "100%" },
                { DD_GUI.Bottom, "0%", "94%", "66%", "6%" },
                { DD_GUI.EnemyBox, "4%", "17%", "23%", "83%" },
                { DD_GUI.MapBox, "27%", "17%", "16%", "83%" },
                { DD_GUI.CharsheetBox, "43%", "17%", "23%", "83%" },
                { DD_GUI.ChannelBox, "66%", "17%", "31%", "83%" },
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

        if ui and ui.updateBorderSizes then
                ui.window_width = nil
                ui.updateBorderSizes()
        end

        if DD_GUI.raise_info_box_contents then
                DD_GUI.raise_info_box_contents()
        end

        return true
end

function DD_GUI.reset_layout()
        local defaults = {
                { ui and ui.mainconsole_container, "4%", "38%", "62%", "56%" },
                { DD_GUI.Right, "-34%", "0%", "34%", "100%" },
                { DD_GUI.Top, "0%", "0%", "100%", "36%" },
                { DD_GUI.Bottom, "0%", "94%", "66%", "6%" },
                { DD_GUI.FirstColumn, "5%", "0%", "23.5%", "100%" },
                { DD_GUI.SecondColumn, "28.5%", "0%", "23.5%", "100%" },
                { DD_GUI.ThirdColumn, "52%", "0%", "23.5%", "100%" },
                { DD_GUI.FourthColumn, "75.5%", "0%", "23.5%", "100%" },
                { DD_GUI.EnemyBox, "4%", "17%", "23%", "83%" },
                { DD_GUI.MapBox, "27%", "17%", "16%", "83%" },
                { DD_GUI.CharsheetBox, "43%", "17%", "23%", "83%" },
                { DD_GUI.ChannelBox, "66%", "17%", "31%", "83%" },
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
                reset_adjustable_box(compass.back, "60%", "82%", "8%", "8%")

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
