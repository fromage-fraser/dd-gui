local package_url = "https://www.dragons-domain.org/main/gui/DD_GUI.mpackage"
local package_install_url = package_url
local uninstall_delay = 0.1
local reinstall_delay = 3
local version_check_delay = 5
local max_version_checks = 12
local timer_owner = "DD_GUI.reinstallgui"
local uninstall_timer_name = "uninstall"
local install_timer_name = "install"
local version_timer_name = "version"
local install_event_name = "installed"
local uninstall_event_name = "uninstalling"

local state = DD_GUI or {}

local function cancel_schedule(schedule)
        if not schedule then
                return
        end

        if type(schedule) == "table" and schedule.kind == "named" then
                if type(deleteNamedTimer) == "function" then
                        pcall(deleteNamedTimer, timer_owner, schedule.name)
                end
        elseif type(schedule) == "table" and schedule.kind == "temp" then
                if schedule.id and type(killTimer) == "function" then
                        pcall(killTimer, schedule.id)
                end
        elseif type(schedule) == "number" and type(killTimer) == "function" then
                -- Compatibility with the previous tempTimer-based alias.
                pcall(killTimer, schedule)
        end
end

local function schedule_timer(name, delay, callback)
        -- Named timers live in Mudlet's profile-level ID manager rather than
        -- in the package tree, so package removal cannot erase the handoff.
        if type(registerNamedTimer) == "function" and
           type(deleteNamedTimer) == "function" then
                pcall(deleteNamedTimer, timer_owner, name)
                local ok, result = pcall(
                        registerNamedTimer,
                        timer_owner,
                        name,
                        delay,
                        callback,
                        false
                )
                if ok and result then
                        return {kind = "named", name = name}
                end
        end

        return {kind = "temp", id = tempTimer(delay, callback)}
end

local function delete_named_event(name)
        if type(deleteNamedEventHandler) == "function" then
                pcall(deleteNamedEventHandler, timer_owner, name)
        end
end

local function installed_version()
        local version
        -- Prefer Mudlet's package metadata because DD_GUI.package_version can
        -- remain in memory briefly while a replacement package is loading.
        if type(getPackageInfo) == "function" then
                local ok, package_version = pcall(
                        getPackageInfo,
                        "DD_GUI",
                        "version"
                )
                if ok then
                        version = package_version
                end
        end
        if (not version or version == "") and
           DD_GUI and DD_GUI.package_version then
                version = DD_GUI.package_version
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
                local version = installed_version()
                if state.reinstall_install_requested and
                   previous_version and version and
                   tostring(version) ~= tostring(previous_version) then
                        state.reinstall_install_succeeded = true
                        state.reinstall_install_finished = true
                        state.reinstall_install_requested = false
                else
                        state.reinstall_version_timer = schedule_timer(
                                version_timer_name, 1, check_installed_version)
                        return
                end
        end

        if not state.reinstall_install_finished then
                state.reinstall_version_timer = schedule_timer(
                        version_timer_name, 1, check_installed_version)
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
                state.reinstall_version_timer = schedule_timer(
                        version_timer_name, 1, check_installed_version)
                return
        end

        if previous_version and version and
           tostring(version) == tostring(previous_version) then
                echo("\nDD_GUI version check timed out; installed version is " ..
                        tostring(version) .. ".\n")
                return
        end

        report_installed_version()
end

if DD_GUI and DD_GUI.migrate_legacy_content then
        DD_GUI.migrate_legacy_content()
end

cancel_schedule(state.reinstall_timer)
cancel_schedule(state.reinstall_install_timer)
cancel_schedule(state.reinstall_version_timer)
state.reinstall_timer = nil
state.reinstall_install_timer = nil
state.reinstall_version_timer = nil
delete_named_event(install_event_name)
delete_named_event(uninstall_event_name)
state.reinstall_install_succeeded = false
state.reinstall_install_finished = false
state.reinstall_install_requested = false
state.reinstall_pending = true

local install_scheduled = false

local function install_latest_package()
        state.reinstall_install_timer = nil
        state.reinstall_install_requested = true
        echo("\nInstalling the latest DD_GUI package...\n")

        local call_ok, result, error_message = pcall(
                installPackage,
                package_install_url
        )
        if (not call_ok or result == false or
            (result == nil and error_message ~= nil)) and
           not state.reinstall_install_succeeded then
                state.reinstall_install_finished = true
                state.reinstall_install_requested = false
                echo("DD_GUI install failed: " ..
                        tostring(error_message or result or "unknown error") ..
                        "\n")
                delete_named_event(install_event_name)
                return
        end

        -- installPackage() can return before the package's install event and
        -- new folder.lua have run. Leave the request pending until either
        -- that event or the version poll observes the new metadata.
end

local function schedule_install()
        if install_scheduled then
                return
        end

        install_scheduled = true
        state.reinstall_pending = false
        state.reinstall_install_timer = schedule_timer(
                install_timer_name,
                reinstall_delay,
                install_latest_package
        )
end

-- These handlers are profile-level objects, not package objects. The
-- uninstall event fires before Mudlet removes this package, giving us a
-- reliable place to arm the surviving install timer.
if type(registerNamedEventHandler) == "function" then
        pcall(
                registerNamedEventHandler,
                timer_owner,
                uninstall_event_name,
                "sysUninstallPackage",
                function(_, name)
                        if name == "DD_GUI" and state.reinstall_pending then
                                schedule_install()
                        end
                end,
                true
        )

        pcall(
                registerNamedEventHandler,
                timer_owner,
                install_event_name,
                "sysInstallPackage",
                function(_, name)
                        if name == "DD_GUI" and
                           state.reinstall_install_requested then
                                state.reinstall_install_succeeded = true
                                state.reinstall_install_finished = true
                                state.reinstall_install_requested = false
                        end
                end,
                true
        )
end

echo("\nDD_GUI will uninstall shortly, then reinstall in " ..
        reinstall_delay .. " seconds...\n")

-- Create this timer before removing the package so it survives the package
-- replacement. The install request itself is asynchronous, so wait beyond
-- the uninstall and reinstall delays before reading the new metadata.
state.reinstall_version_timer = schedule_timer(
        version_timer_name,
        uninstall_delay + reinstall_delay + version_check_delay,
        check_installed_version
)

-- Let this alias return before removing the package that owns it. Mudlet can
-- terminate when uninstallPackage() mutates the active package mid-alias.
state.reinstall_timer = schedule_timer(uninstall_timer_name, uninstall_delay, function()
        state.reinstall_timer = nil
        local ok, err = pcall(uninstallPackage, "DD_GUI")
        if not ok then
                echo("DD_GUI uninstall failed: " .. tostring(err) .. "\n")
                state.reinstall_pending = false
                delete_named_event(uninstall_event_name)
                return
        end
        -- The named uninstall event normally schedules this. The fallback
        -- covers Mudlet builds that do not expose named event handlers.
        schedule_install()
end)
