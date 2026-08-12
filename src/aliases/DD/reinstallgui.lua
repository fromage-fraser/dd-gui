local package_name = "DD_GUI"
local package_url = "https://www.dragons-domain.org/main/gui/DD_GUI.mpackage"
local uninstall_delay = 0.2
local reinstall_delay = 4
local download_retry_delay = 2
local install_retry_delay = 2
local max_download_attempts = 3
local max_install_attempts = 3
local max_install_checks = 20
local timer_owner = "DD_GUI.reinstallgui"
local download_timer_name = "download"
local uninstall_timer_name = "uninstall"
local install_timer_name = "install"
local status_timer_name = "status"
local download_done_event_name = "downloaded"
local download_error_event_name = "download_error"
local install_event_name = "installed"
local uninstall_event_name = "uninstalling"

DD_GUI = DD_GUI or {}
local state = DD_GUI

local function normalise_path(path)
        return tostring(path or ""):gsub("\\", "/")
end

local function staging_path()
        local root
        if type(getMudletHomeDir) == "function" then
                local ok, home = pcall(getMudletHomeDir)
                if ok and home and home ~= "" then
                        root = home
                end
        end
        root = root or ms_path or "."
        root = tostring(root):gsub("[/\\]+$", "")
        return root .. "\\DD_GUI_reinstall.mpackage"
end

local local_package_path = staging_path()

local function is_staging_path(path)
        return normalise_path(path) == normalise_path(local_package_path)
end

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
                -- Compatibility with the old tempTimer-based alias.
                pcall(killTimer, schedule)
        end
end

local function schedule_timer(name, delay, callback)
        -- Named timers belong to the profile ID manager, so they remain alive
        -- when the package that created this alias is removed.
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

local function package_is_installed()
        if type(getPackages) == "function" then
                local ok, packages = pcall(getPackages)
                if ok and type(packages) == "table" then
                        for key, installed_name in pairs(packages) do
                                if tostring(installed_name):lower() ==
                                   package_name:lower() or
                                   tostring(key):lower() == package_name:lower() then
                                        return true
                                end
                        end
                        return false
                end
        end

        if type(getPackageInfo) == "function" then
                local ok, version = pcall(
                        getPackageInfo,
                        package_name,
                        "version"
                )
                if ok then
                        return version ~= nil and tostring(version) ~= ""
                end
        end

        return state.package_version ~= nil
end

local function installed_version()
        if type(getPackageInfo) == "function" then
                local ok, version = pcall(
                        getPackageInfo,
                        package_name,
                        "version"
                )
                if ok and version and tostring(version) ~= "" then
                        return version
                end
        end

        if state.package_version then
                return state.package_version
        end

        return nil
end

local function report_installed_version()
        local version = installed_version()
        if version and version ~= "" then
                echo("\nDD_GUI version: " .. tostring(version) .. "\n")
        else
                echo("\nDD_GUI was installed, but its package version is unavailable.\n")
        end
end

local function delete_reinstall_handlers()
        delete_named_event(download_done_event_name)
        delete_named_event(download_error_event_name)
        delete_named_event(install_event_name)
        delete_named_event(uninstall_event_name)
end

local function finish_reinstall(success, message)
        if state.reinstall_finished then
                return
        end

        state.reinstall_finished = true
        state.reinstall_pending = false
        cancel_schedule(state.reinstall_download_timer)
        cancel_schedule(state.reinstall_timer)
        cancel_schedule(state.reinstall_install_timer)
        cancel_schedule(state.reinstall_status_timer)
        state.reinstall_download_timer = nil
        state.reinstall_timer = nil
        state.reinstall_install_timer = nil
        state.reinstall_status_timer = nil
        delete_reinstall_handlers()

        if success then
                state.reinstall_install_succeeded = true
                echo("\nDD_GUI reinstall completed.\n")
                report_installed_version()
        else
                state.reinstall_install_succeeded = false
                echo("\nDD_GUI reinstall failed: " ..
                        tostring(message or "unknown error") .. "\n")
        end
end

local function schedule_install()
        if state.reinstall_finished or state.reinstall_install_scheduled then
                return
        end

        state.reinstall_install_scheduled = true
        state.reinstall_install_timer = schedule_timer(
                install_timer_name,
                reinstall_delay,
                function()
                        state.reinstall_install_timer = nil
                        state.reinstall_install_scheduled = false
                        if state.reinstall_finished then
                                return
                        end
                        state.reinstall_phase = "installing"
                        state.reinstall_install_requested = true
                        state.reinstall_install_attempts =
                                state.reinstall_install_attempts + 1
                        echo("\nInstalling the downloaded DD_GUI package...\n")

                        local call_ok, result, error_message = pcall(
                                installPackage,
                                local_package_path
                        )
                        if not call_ok or result == false or
                           (result == nil and error_message ~= nil) then
                                if state.reinstall_install_attempts <
                                   max_install_attempts then
                                        echo("DD_GUI install attempt " ..
                                                tostring(state.reinstall_install_attempts) ..
                                                " failed; retrying in " ..
                                                tostring(install_retry_delay) ..
                                                " seconds.\n")
                                        state.reinstall_install_timer = schedule_timer(
                                                install_timer_name,
                                                install_retry_delay,
                                                function()
                                                        state.reinstall_install_scheduled = false
                                                        state.reinstall_install_timer = nil
                                                        state.reinstall_phase = "ready_to_install"
                                                        schedule_install()
                                                end
                                        )
                                        return
                                end

                                finish_reinstall(
                                        false,
                                        error_message or result or "installPackage() rejected the local package"
                                )
                                return
                        end

                        state.reinstall_install_checks = 0
                        local check_install_status
                        check_install_status = function()
                                        state.reinstall_status_timer = nil
                                        if state.reinstall_finished then
                                                return
                                        end

                                        if state.reinstall_install_succeeded or
                                           package_is_installed() then
                                                finish_reinstall(true)
                                                return
                                        end

                                        state.reinstall_install_checks =
                                                state.reinstall_install_checks + 1
                                        if state.reinstall_install_checks >=
                                           max_install_checks then
                                                finish_reinstall(
                                                        false,
                                                        "the package did not appear after " ..
                                                        tostring(max_install_checks) ..
                                                        " seconds"
                                                )
                                                return
                                        end

                                        state.reinstall_status_timer = schedule_timer(
                                                status_timer_name,
                                                1,
                                                check_install_status
                                        )
                                end
                        state.reinstall_status_timer = schedule_timer(
                                status_timer_name,
                                1,
                                check_install_status
                        )
                end
        )
end

local function schedule_uninstall()
        if state.reinstall_finished or state.reinstall_uninstall_scheduled then
                return
        end

        state.reinstall_uninstall_scheduled = true
        state.reinstall_timer = schedule_timer(
                uninstall_timer_name,
                uninstall_delay,
                function()
                        state.reinstall_timer = nil
                        if state.reinstall_finished then
                                return
                        end

                        state.reinstall_phase = "uninstalling"
                        echo("\nRemoving the current DD_GUI package...\n")

                        -- Arm the local install before mutating the package
                        -- that owns this alias. The named timer is the normal
                        -- handoff; the named uninstall event is an early path
                        -- when Mudlet emits it before the fallback timer.
                        schedule_install()

                        local ok, result, error_message = pcall(
                                uninstallPackage,
                                package_name
                        )
                        if not ok then
                                finish_reinstall(
                                        false,
                                        error_message or result or "uninstallPackage() failed"
                                )
                        end
                end
        )
end

local function begin_download()
        if state.reinstall_finished then
                return
        end

        state.reinstall_download_timer = nil
        state.reinstall_phase = "downloading"
        state.reinstall_download_attempts = state.reinstall_download_attempts + 1
        os.remove(local_package_path)
        echo("\nDownloading the latest DD_GUI package...\n")

        local call_ok, result, error_message = pcall(
                downloadFile,
                local_package_path,
                package_url
        )
        if not call_ok or result == false then
                if state.reinstall_download_attempts < max_download_attempts then
                        echo("DD_GUI download attempt " ..
                                tostring(state.reinstall_download_attempts) ..
                                " failed; retrying in " ..
                                tostring(download_retry_delay) ..
                                " seconds.\n")
                        state.reinstall_download_timer = schedule_timer(
                                download_timer_name,
                                download_retry_delay,
                                begin_download
                        )
                        return
                end

                finish_reinstall(
                        false,
                        error_message or result or "downloadFile() rejected the package URL"
                )
        end
end

local function on_download_done(event_name, filename)
        local candidate = filename or event_name
        if not is_staging_path(candidate) or
           state.reinstall_phase ~= "downloading" then
                return
        end

        state.reinstall_download_timer = nil
        state.reinstall_phase = "downloaded"
        echo("DD_GUI package download completed.\n")
        schedule_uninstall()
end

local function on_download_error(event_name, reason, filename)
        local candidate = filename
        if not is_staging_path(candidate) and is_staging_path(reason) then
                candidate = reason
        end
        if not is_staging_path(candidate) or
           state.reinstall_phase ~= "downloading" then
                return
        end

        state.reinstall_download_timer = nil
        if state.reinstall_download_attempts < max_download_attempts then
                echo("DD_GUI download failed: " .. tostring(reason or "unknown error") ..
                        "; retrying in " .. tostring(download_retry_delay) ..
                        " seconds.\n")
                state.reinstall_download_timer = schedule_timer(
                        download_timer_name,
                        download_retry_delay,
                        begin_download
                )
                return
        end

        finish_reinstall(false, reason or "download failed")
end

local function on_uninstall(event_name, name)
        if state.reinstall_finished or
           tostring(name or event_name):lower() ~= package_name:lower() then
                return
        end

        if state.reinstall_phase == "uninstalling" then
                state.reinstall_phase = "ready_to_install"
        end
end

local function on_install(event_name, name)
        if state.reinstall_finished or
           tostring(name or event_name):lower() ~= package_name:lower() or
           not state.reinstall_install_requested then
                return
        end

        state.reinstall_install_succeeded = true
        finish_reinstall(true)
end

local function register_reinstall_handlers()
        delete_reinstall_handlers()
        if type(registerNamedEventHandler) ~= "function" then
                return false
        end

        local registrations = {
                {download_done_event_name, "sysDownloadDone", on_download_done, false},
                {download_error_event_name, "sysDownloadError", on_download_error, false},
                {uninstall_event_name, "sysUninstallPackage", on_uninstall, true},
                {install_event_name, "sysInstallPackage", on_install, true},
        }

        for _, registration in ipairs(registrations) do
                local ok, result = pcall(
                        registerNamedEventHandler,
                        timer_owner,
                        registration[1],
                        registration[2],
                        registration[3],
                        registration[4]
                )
                if not ok or not result then
                        delete_reinstall_handlers()
                        return false
                end
        end

        return true
end

if DD_GUI.migrate_legacy_content then
        DD_GUI.migrate_legacy_content()
end

cancel_schedule(state.reinstall_download_timer)
cancel_schedule(state.reinstall_timer)
cancel_schedule(state.reinstall_install_timer)
cancel_schedule(state.reinstall_status_timer)
state.reinstall_download_timer = nil
state.reinstall_timer = nil
state.reinstall_install_timer = nil
state.reinstall_status_timer = nil
state.reinstall_download_attempts = 0
state.reinstall_install_attempts = 0
state.reinstall_install_checks = 0
state.reinstall_install_requested = false
state.reinstall_install_succeeded = false
state.reinstall_install_scheduled = false
state.reinstall_uninstall_scheduled = false
state.reinstall_finished = false
state.reinstall_pending = true

if not register_reinstall_handlers() then
        finish_reinstall(
                false,
                "this Mudlet version cannot register the profile-level reinstall handoff"
        )
        return
end

echo("\nDD_GUI will download the latest package before uninstalling the current one.\n")
state.reinstall_download_timer = schedule_timer(
        download_timer_name,
        0.1,
        begin_download
)
