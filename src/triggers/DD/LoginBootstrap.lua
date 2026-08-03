local function dd_gui_character_data_ready()
        return gmcp and gmcp.Char and gmcp.Char.Base and gmcp.Char.Vitals and
                gmcp.Char.Stats and gmcp.Char.Worth and
                gmcp.Char.Base.name and gmcp.Char.Vitals.hp
end

local attempts = 0

local function dd_gui_bootstrap_when_ready()
        DD_GUI.login_bootstrap_timer = nil

        if not dd_gui_character_data_ready() then
                attempts = attempts + 1
                if attempts < 20 then
                        DD_GUI.login_bootstrap_timer = tempTimer(
                                0.5, dd_gui_bootstrap_when_ready)
                end
                return
        end

        bootstrap()
        update_affects()
        update_vitals()
        update_inventory()
        update_equipped()
        update_enemy()
        update_travel()
        echo("\nBootstrapping GUI...")
end

if DD_GUI.login_bootstrap_timer then
        killTimer(DD_GUI.login_bootstrap_timer)
end

DD_GUI.login_bootstrap_timer = tempTimer(0, dd_gui_bootstrap_when_ready)
