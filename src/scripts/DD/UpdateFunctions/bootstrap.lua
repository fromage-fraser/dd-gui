DD_GUI = DD_GUI or {}

local function remove_conflicting_generic_mapper()
        if DD_GUI.generic_mapper_checked then
                return
        end

        DD_GUI.generic_mapper_checked = true

        if type(uninstallPackage) ~= "function" then
                return
        end

        if type(getPackageInfo) == "function" then
                local ok, version = pcall(getPackageInfo, "generic_mapper", "version")
                if not ok or version == nil or tostring(version) == "" then
                        return
                end
        end

        pcall(uninstallPackage, "generic_mapper")
end

local function run_update(fn)
        if type(fn) ~= "function" then
                return
        end

        local ok, err = pcall(fn)
        if not ok then
                DD_GUI.last_data_refresh_error = tostring(err)
        end
end

function DD_GUI.refresh_data()
        if not gmcp or type(gmcp.Char) ~= "table" then
                return
        end

        DD_GUI.last_data_refresh_error = nil
        local char = gmcp.Char
        local vitals = char.Vitals
        local affect = char.Affect

        if type(vitals) == "table" and type(char.Base) == "table" and
           type(char.Stats) == "table" and type(char.Worth) == "table" then
                run_update(update_vitals)
        end

        if type(affect) == "table" then
                run_update(update_affects)
        end

        if type(char.Quest) == "table" then
                run_update(update_quest_status)
        end

        if type(char.Items) == "table" then
                run_update(update_inventory)
        end

        if type(vitals) == "table" or type(char.Worn) == "table" then
                run_update(update_equipped)
        end

        local room = gmcp.Room and gmcp.Room.Info
        local position = type(vitals) == "table" and tonumber(vitals.position)
        local enemy_rows = char.Enemies
        local first_enemy_row = type(enemy_rows) == "table" and enemy_rows[1]
        local has_enemy = type(first_enemy_row) == "table" and
                (first_enemy_row.name ~= nil or first_enemy_row.hp ~= nil or
                 first_enemy_row.maxhp ~= nil or type(first_enemy_row[1]) == "table")

        if position == 6 and has_enemy then
                run_update(update_enemy)
        elseif type(room) == "table" and type(vitals) == "table" then
                run_update(update_travel)
        end

        if type(char.Channels) == "table" then
                run_update(update_channel_status)
        end
end

-- Rebuilds can happen while the server already has a complete GMCP snapshot.
-- Replay that snapshot after creating the widgets instead of waiting for the
-- next GMCP event to arrive.
local function dd_gui_installed_version()
        if DD_GUI and DD_GUI.package_version then
                return tostring(DD_GUI.package_version)
        end

        if type(getPackageInfo) ~= "function" then
                return ""
        end

        local ok, version = pcall(getPackageInfo, "DD_GUI", "version")
        if not ok then
                return ""
        end

        return tostring(version or "")
end

local function dd_gui_hide_widget(widget)
        if widget and type(widget.hide) == "function" then
                pcall(function() widget:hide() end)
        end
end

local function dd_gui_show_widget(widget)
        if widget and type(widget.show) == "function" then
                pcall(function() widget:show() end)
        end
end

local function dd_gui_hide_previous_roots()
        -- Deleting a live Adjustable.Container tree can crash some Mudlet
        -- builds while child QWidgets are still being repainted. Hide the
        -- old roots before constructing the replacement tree instead.
        for _, widget in ipairs({
                ui and ui.mainconsole_container,
                DD_GUI and DD_GUI.Top,
                DD_GUI and DD_GUI.Right,
                DD_GUI and DD_GUI.Bottom,
        }) do
                dd_gui_hide_widget(widget)
        end

        -- Remove panel overlays from the previous package tree before a
        -- versioned rebuild. The replacement tree creates exactly one frame
        -- for each right-column panel.
        for _, key in ipairs({
                "InventoryPanelOutline",
                "AffectPanelOutline",
        }) do
                if DD_GUI and DD_GUI[key] then
                        local outline = DD_GUI[key]
                        if type(outline.delete) == "function" then
                                pcall(function() outline:delete() end)
                        end
                        DD_GUI[key] = nil
                end
        end

        if DD_GUI and DD_GUI.FrameGrid and DD_GUI.FrameGrid.clear then
                DD_GUI.FrameGrid:clear()
        end
end

local function dd_gui_show_current_roots()
        for _, widget in ipairs({
                ui and ui.mainconsole_container,
                DD_GUI and DD_GUI.Top,
                DD_GUI and DD_GUI.Right,
                DD_GUI and DD_GUI.Bottom,
        }) do
                dd_gui_show_widget(widget)
        end

        -- Gauge columns are direct children of the bottom root and can retain
        -- a hidden state when Mudlet reuses named Geyser widgets during a
        -- reconnect or package rebuild.
        for _, widget in ipairs({
                DD_GUI and DD_GUI.FirstColumn,
                DD_GUI and DD_GUI.SecondColumn,
                DD_GUI and DD_GUI.ThirdColumn,
                DD_GUI and DD_GUI.FourthColumn,
                DD_GUI and DD_GUI.EnemyBox,
                DD_GUI and DD_GUI.MapBox,
                DD_GUI and DD_GUI.CharsheetBox,
                DD_GUI and DD_GUI.ChannelBox,
                DD_GUI and DD_GUI.InventoryBox,
                DD_GUI and DD_GUI.AffectBox,
                DD_GUI and DD_GUI.Hitpoints,
                DD_GUI and DD_GUI.Mana,
                DD_GUI and DD_GUI.Xp,
                DD_GUI and DD_GUI.Moves,
                HitpointsLabel,
                ManaLabel,
                XpLabel,
                MovesLabel,
        }) do
                dd_gui_show_widget(widget)
        end

        local panel_css = DD_GUI and DD_GUI.BoxCSS
        if panel_css and type(panel_css.getCSS) == "function" then
                local css = panel_css:getCSS()
                for _, panel in ipairs({
                        DD_GUI and DD_GUI.EnemyBox,
                        DD_GUI and DD_GUI.MapBox,
                        DD_GUI and DD_GUI.CharsheetBox,
                        DD_GUI and DD_GUI.ChannelBox,
                }) do
                        if panel and type(panel.setStyleSheet) == "function" then
                                pcall(function() panel:setStyleSheet(css) end)
                        end
                end
        end

        if DD_GUI.FrameGrid and DD_GUI.FrameGrid.schedule_refresh then
                DD_GUI.FrameGrid:schedule_refresh(0.02)
        end
end

DD_GUI.show_current_roots = dd_gui_show_current_roots

function bootstrap()
        remove_conflicting_generic_mapper()

        local package_version = dd_gui_installed_version()

        if DD_GUI.Theme and DD_GUI.Theme.apply_profile_style then
                DD_GUI.Theme:apply_profile_style()
        end

        if DD_GUI.bootstrap_ready and
           DD_GUI.bootstrap_version == package_version then
                if DD_GUI.bootstrap_refresh_timer then
                        killTimer(DD_GUI.bootstrap_refresh_timer)
                        DD_GUI.bootstrap_refresh_timer = nil
                end

                dd_gui_show_current_roots()
                DD_GUI.refresh_data()
                if DD_GUI.raise_info_box_contents then
                        DD_GUI.raise_info_box_contents()
                end
                if DD_GUI.apply_mapper_theme then
                        DD_GUI.apply_mapper_theme()
                end
                if DD_GUI.Layout then
                        DD_GUI.Layout:apply(false)
                end
                if DD_GUI.FrameGrid and DD_GUI.FrameGrid.schedule_refresh then
                        DD_GUI.FrameGrid:schedule_refresh(0.05)
                end
                return
        end

        if DD_GUI.bootstrap_ready then
                dd_gui_hide_previous_roots()
        end

        set_borders()
        ui_container()
        create_background()
        define_boxes()
        build_gauges()
        build_affects_box()
        build_affects_console()
        build_inventory_box()
        build_inventory_console()
        build_channel_box()
        build_channel_console()
        build_charsheet_box()
        build_charsheet_console()
        build_enemy_box()
        build_enemy_console()
        build_compass()
        if DD_GUI.migrate_layout_defaults then
                DD_GUI.migrate_layout_defaults()
        end
        initialise_mapper()
        load_dd_mapper()
        if DD_GUI.apply_mapper_theme then
                DD_GUI.apply_mapper_theme()
        end
        get_custom_content()
        if DD_GUI.Mapper and DD_GUI.Mapper.setColor then
                DD_GUI.Mapper:setColor(0, 0, 0, 255)
        end

        if DD_GUI.FrameGrid and DD_GUI.FrameGrid.register then
                DD_GUI.FrameGrid:register()
        end

        -- Resizing and moving are opt-in. Normal play leaves the adjustable
        -- surfaces click-through so tabs, compass controls, and scrollback
        -- receive mouse input directly.
        if DD_GUI.Layout then
                DD_GUI.Layout:apply(false)
        end

        DD_GUI.refresh_data()

        if DD_GUI.raise_info_box_contents then
                DD_GUI.raise_info_box_contents()
        end

        -- Named adjustable containers can be reused by Mudlet during a live
        -- package replacement. Ensure a root hidden during that handoff is
        -- visible before the first data refresh and paint pass.
        dd_gui_show_current_roots()

        DD_GUI.bootstrap_ready = true
        DD_GUI.bootstrap_version = package_version

        -- Geyser completes its initial geometry and stacking pass after
        -- bootstrap. Refresh once more so package updates also repaint the
        -- newly created consoles after that pass.
        if DD_GUI.bootstrap_refresh_timer then
                killTimer(DD_GUI.bootstrap_refresh_timer)
        end
        DD_GUI.bootstrap_refresh_timer = tempTimer(0.1, function()
                DD_GUI.bootstrap_refresh_timer = nil
                DD_GUI.refresh_data()
                if DD_GUI.raise_info_box_contents then
                        DD_GUI.raise_info_box_contents()
                end
                if DD_GUI.Layout then
                        DD_GUI.Layout:apply(false)
                end
                if DD_GUI.FrameGrid and DD_GUI.FrameGrid.schedule_refresh then
                        DD_GUI.FrameGrid:schedule_refresh(0.05)
                end
        end)
end
