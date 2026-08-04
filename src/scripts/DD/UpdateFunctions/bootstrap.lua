DD_GUI = DD_GUI or {}

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

        if gmcp.Comm and type(gmcp.Comm.Channel) == "table" then
                run_update(update_comms)
        end

        if type(char.Channels) == "table" then
                run_update(update_channel_status)
        end
end

-- Rebuilds can happen while the server already has a complete GMCP snapshot.
-- Replay that snapshot after creating the widgets instead of waiting for the
-- next GMCP event to arrive.
function bootstrap()
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
        get_custom_content()
        if DD_GUI.Mapper and DD_GUI.Mapper.setColor then
                DD_GUI.Mapper:setColor(0, 0, 0, 255)
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
        end)
end
