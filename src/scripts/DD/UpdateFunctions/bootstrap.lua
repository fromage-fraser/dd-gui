DD_GUI = DD_GUI or {}

-- A source reload must not let a timer from the previous package tree flush
-- into widgets while this script set is still being replaced.
DD_GUI.bootstrap_ready = false

local function remove_conflicting_generic_mapper()
        if DD_GUI.remove_conflicting_generic_mapper then
                DD_GUI.remove_conflicting_generic_mapper()
        end
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

local function dd_gui_refresh_data_impl()
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

function DD_GUI.refresh_data()
        if DD_GUI.data_refresh_in_progress then
                return
        end

        DD_GUI.data_refresh_in_progress = true
        local ok, error_message = pcall(dd_gui_refresh_data_impl)
        DD_GUI.data_refresh_in_progress = false
        if not ok then
                DD_GUI.last_data_refresh_error = tostring(error_message)
        end
end

-- GMCP can arrive in bursts during reconnect. Keep one managed handler per
-- event and coalesce a burst into one short deferred update pass. Named event
-- handlers prevent a local source reload from stacking another copy.
local data_refresh_specs = {
        {key = "vitals", event = "gmcp.Char.Vitals", updates = {"update_vitals", "update_equipped"}},
        {key = "affects", event = "gmcp.Char.Affect", updates = {"update_affects"}},
        {key = "quest", event = "gmcp.Char.Quest", updates = {"update_quest_status"}},
        {key = "inventory", event = "gmcp.Char.Items", updates = {"update_inventory"}},
        {key = "worn", event = "gmcp.Char.Worn", updates = {"update_equipped"}},
        {key = "base", event = "gmcp.Char.Base", updates = {"update_equipped"}},
        {key = "room", event = "gmcp.Room.Info", updates = {"update_travel"}},
        {key = "enemy", event = "gmcp.Char.Enemies", updates = {"update_enemy"}},
        {key = "comms", event = "gmcp.Comm.Channel.Text", updates = {"update_comms"}},
        {key = "channels", event = "gmcp.Char.Channels", updates = {"update_channel_status"}},
}

local data_refresh_owner = "DD_GUI"

local function data_refresh_handler_name(spec)
        return "data_refresh_" .. spec.key
end

local function cancel_data_refresh_timer()
        if DD_GUI.data_refresh_timer and type(killTimer) == "function" then
                pcall(killTimer, DD_GUI.data_refresh_timer)
        end
        DD_GUI.data_refresh_timer = nil
end

function DD_GUI.unregister_data_refresh_handlers()
        cancel_data_refresh_timer()
        DD_GUI.pending_data_updates = {}

        if type(deleteNamedEventHandler) == "function" then
                for _, spec in ipairs(data_refresh_specs) do
                        pcall(deleteNamedEventHandler, data_refresh_owner,
                                data_refresh_handler_name(spec))
                end
        end

        for _, handler_id in pairs(DD_GUI.data_refresh_handler_ids or {}) do
                if handler_id and type(killAnonymousEventHandler) == "function" then
                        pcall(killAnonymousEventHandler, handler_id)
                end
        end

        DD_GUI.data_refresh_handler_ids = {}
        DD_GUI.data_refresh_handlers_named = false
end

local function flush_data_refresh()
        DD_GUI.data_refresh_timer = nil
        if not DD_GUI.bootstrap_ready then
                return
        end

        local pending = DD_GUI.pending_data_updates or {}
        DD_GUI.pending_data_updates = {}
        for _, spec in ipairs(data_refresh_specs) do
                for _, update_name in ipairs(spec.updates) do
                        if pending[update_name] then
                                run_update(_G[update_name])
                        end
                end
        end
end

function DD_GUI.schedule_data_refresh(update_names)
        DD_GUI.pending_data_updates = DD_GUI.pending_data_updates or {}
        for _, update_name in ipairs(update_names or {}) do
                DD_GUI.pending_data_updates[update_name] = true
        end

        if DD_GUI.data_refresh_timer then
                return
        end

        if type(tempTimer) ~= "function" then
                flush_data_refresh()
                return
        end

        DD_GUI.data_refresh_timer = tempTimer(0.03, flush_data_refresh)
end

local function register_data_refresh_handlers()
        DD_GUI.unregister_data_refresh_handlers()

        local function make_data_refresh_handler(updates)
                return function()
                        DD_GUI.schedule_data_refresh(updates)
                end
        end

        local named_registration_ok = type(registerNamedEventHandler) == "function" and
                type(deleteNamedEventHandler) == "function"
        if named_registration_ok then
                for _, spec in ipairs(data_refresh_specs) do
                        local ok, result = pcall(
                                registerNamedEventHandler,
                                data_refresh_owner,
                                data_refresh_handler_name(spec),
                                spec.event,
                                make_data_refresh_handler(spec.updates),
                                false
                        )
                        if not ok or result == false then
                                named_registration_ok = false
                                break
                        end
                end
        end

        if named_registration_ok then
                DD_GUI.data_refresh_handlers_named = true
                return
        end

        -- Older Mudlet builds may not provide named event handlers. The
        -- anonymous fallback still replaces the previous IDs on reload.
        DD_GUI.unregister_data_refresh_handlers()
        for _, spec in ipairs(data_refresh_specs) do
                local handler_id = registerAnonymousEventHandler(
                        spec.event,
                        make_data_refresh_handler(spec.updates)
                )
                table.insert(DD_GUI.data_refresh_handler_ids, handler_id)
        end
end

register_data_refresh_handlers()

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

local function dd_gui_bootstrap_impl()
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

        if next(DD_GUI.pending_data_updates or {}) then
                DD_GUI.schedule_data_refresh()
        end

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

function bootstrap()
        if DD_GUI.bootstrap_in_progress then
                return
        end

        DD_GUI.bootstrap_in_progress = true
        local ok, error_message = pcall(dd_gui_bootstrap_impl)
        DD_GUI.bootstrap_in_progress = false
        if not ok then
                DD_GUI.last_bootstrap_error = tostring(error_message)
                if type(cecho) == "function" then
                        cecho("<red>DD_GUI bootstrap failed: " ..
                                tostring(error_message) .. "<reset>\n")
                end
        end
end
