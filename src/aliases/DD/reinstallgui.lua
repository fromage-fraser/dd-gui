local package_url = "https://www.dragons-domain.org/main/gui/DD_GUI.mpackage"
local uninstall_delay = 0.1
local reinstall_delay = 3

local state = DD_GUI or {}

if DD_GUI and DD_GUI.migrate_legacy_content then
        DD_GUI.migrate_legacy_content()
end

if state.reinstall_timer and killTimer then
        killTimer(state.reinstall_timer)
        state.reinstall_timer = nil
end

echo("\nDD_GUI will uninstall shortly, then reinstall in " ..
        reinstall_delay .. " seconds...\n")

-- Let this alias return before removing the package that owns it. Mudlet can
-- terminate when uninstallPackage() mutates the active package mid-alias.
state.reinstall_timer = tempTimer(uninstall_delay, function()
        state.reinstall_timer = nil
        local ok, err = pcall(uninstallPackage, "DD_GUI")
        if not ok then
                echo("DD_GUI uninstall failed: " .. tostring(err) .. "\n")
                return
        end

        tempTimer(reinstall_delay, function()
                echo("\nInstalling the latest DD_GUI package...\n")
                local install_ok, install_err = pcall(installPackage, package_url)
                if not install_ok then
                        echo("DD_GUI install failed: " .. tostring(install_err) .. "\n")
                end
        end)
end)
