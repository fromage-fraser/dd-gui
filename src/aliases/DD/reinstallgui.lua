local package_url = "https://www.dragons-domain.org/main/gui/DD_GUI.mpackage"
local uninstall_delay = 0.1
local reinstall_delay = 3
local version_check_delay = 5
local max_version_checks = 12

local state = DD_GUI or {}

local function installed_version()
        local version
        if DD_GUI and DD_GUI.package_version then
                version = DD_GUI.package_version
        elseif type(getPackageInfo) == "function" then
                local ok, package_version = pcall(
                        getPackageInfo,
                        "DD_GUI",
                        "version"
                )
                if ok then
                        version = package_version
                end
        end
        return version
end

local function report_installed_version()
        local version = installed_version()

        if version and version ~= "" then
                echo("\nDD_GUI version: " .. tostring(version) .. "\n")
        else
                echo("\nDD_GUI package version is unavailable.\n")
        end
end

local previous_version = installed_version()
local version_check_attempts = 0

local function check_installed_version()
        state.reinstall_version_timer = nil
        if not state.reinstall_install_finished then
                state.reinstall_version_timer = tempTimer(
                        1,
                        check_installed_version
                )
                return
        end

        if not state.reinstall_install_succeeded then
                echo("\nDD_GUI version check skipped because installation failed.\n")
                return
        end

        version_check_attempts = version_check_attempts + 1
        local version = installed_version()
        if version_check_attempts < max_version_checks and
           (not version or version == "" or
            (previous_version and
             tostring(version) == tostring(previous_version))) then
                state.reinstall_version_timer = tempTimer(
                        1,
                        check_installed_version
                )
                return
        end

        report_installed_version()
end

if DD_GUI and DD_GUI.migrate_legacy_content then
        DD_GUI.migrate_legacy_content()
end

if state.reinstall_timer and killTimer then
        killTimer(state.reinstall_timer)
        state.reinstall_timer = nil
end
if state.reinstall_version_timer and killTimer then
        killTimer(state.reinstall_version_timer)
        state.reinstall_version_timer = nil
end
state.reinstall_install_succeeded = false
state.reinstall_install_finished = false

echo("\nDD_GUI will uninstall shortly, then reinstall in " ..
        reinstall_delay .. " seconds...\n")

-- Create this timer before removing the package so it survives the package
-- replacement. The install request itself is asynchronous, so wait beyond
-- the uninstall and reinstall delays before reading the new metadata.
state.reinstall_version_timer = tempTimer(
        uninstall_delay + reinstall_delay + version_check_delay,
        check_installed_version
)

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
                        state.reinstall_install_finished = true
                        return
                end
                state.reinstall_install_succeeded = true
                state.reinstall_install_finished = true
        end)
end)
