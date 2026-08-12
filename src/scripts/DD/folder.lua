DD_GUI = DD_GUI or {}
mudlet = mudlet or {}
local GENERIC_MAPPER_PACKAGE = "generic_mapper"

-- Register DD_GUI as the profile's mapper before touching the bundled mapper
-- package. Mudlet ships generic_mapper in new profiles and uses this flag to
-- recognise that another mapper owns the profile.
mudlet.mapper_script = true

-- Mudlet builds without getPackageInfo() still need a reliable way to show
-- the installed GUI version and decide whether bootstrap() may be reused.
DD_GUI.package_version = "0.0.131"

-- Return nil when Mudlet cannot answer the package query. In that case the
-- removal attempt is still made, because leaving the package installed is the
-- more dangerous failure mode for this profile.
local function generic_mapper_is_installed()
        -- getPackages() reports package presence directly. This is more
        -- reliable than probing version metadata, since the bundled mapper's
        -- metadata is not guaranteed to contain a version on older Mudlet
        -- profiles.
        if type(getPackages) == "function" then
                local ok, packages = pcall(getPackages)
                if ok and type(packages) == "table" then
                        for _, package_name in pairs(packages) do
                                if tostring(package_name):lower() ==
                                   GENERIC_MAPPER_PACKAGE then
                                        return true
                                end
                        end
                        return false
                end
        end

        if type(getPackageInfo) ~= "function" then
                return nil
        end

        local ok, version = pcall(
                getPackageInfo,
                GENERIC_MAPPER_PACKAGE,
                "version"
        )
        if not ok then
                return nil
        end

        return version ~= nil and tostring(version) ~= ""
end

-- DD_GUI owns the native mapper surface. Remove the legacy generic mapper as
-- early as possible so its profile-level map/autosave.dat is not loaded beside
-- the DD_GUI map during a local development reload. This deliberately avoids
-- a permanent "already checked" cache: the package can be installed again by
-- Mudlet or by its own updater after the first cleanup.
function DD_GUI.remove_conflicting_generic_mapper(_force)
        if DD_GUI.generic_mapper_uninstalling then
                return false
        end

        if type(uninstallPackage) ~= "function" then
                return false
        end

        local installed = generic_mapper_is_installed()
        if installed == false then
                DD_GUI.generic_mapper_removed = false
                return false
        end

        DD_GUI.generic_mapper_uninstalling = true
        local ok, result = pcall(
                uninstallPackage,
                GENERIC_MAPPER_PACKAGE
        )
        DD_GUI.generic_mapper_uninstalling = false

        DD_GUI.generic_mapper_removed = ok and result ~= false
        if DD_GUI.generic_mapper_removed and type(cecho) == "function" then
                cecho("<yellow>Removed the conflicting generic_mapper package; DD_GUI owns the mapper.<reset>\n")
        end

        return DD_GUI.generic_mapper_removed == true
end

function DD_GUI.cancel_generic_mapper_cleanup()
        if DD_GUI.generic_mapper_cleanup_timer and type(killTimer) == "function" then
                pcall(killTimer, DD_GUI.generic_mapper_cleanup_timer)
        end
        DD_GUI.generic_mapper_cleanup_timer = nil
end

-- A package-install event can arrive after the initial folder script has run.
-- Give Mudlet time to finish registering the package, then remove it again;
-- retry briefly because the bundled mapper may install asynchronously.
function DD_GUI.schedule_generic_mapper_cleanup(watch_install)
        DD_GUI.cancel_generic_mapper_cleanup()

        local attempts = 0
        local function cleanup()
                DD_GUI.generic_mapper_cleanup_timer = nil
                attempts = attempts + 1

                local installed = generic_mapper_is_installed()
                if installed == false and not watch_install then
                        return
                end

                if installed ~= false then
                        DD_GUI.remove_conflicting_generic_mapper(true)
                end
                if attempts < 12 and type(tempTimer) == "function" then
                        DD_GUI.generic_mapper_cleanup_timer = tempTimer(
                                0.25,
                                cleanup
                        )
                end
        end

        if type(tempTimer) == "function" then
                DD_GUI.generic_mapper_cleanup_timer = tempTimer(0.05, cleanup)
        else
                cleanup()
        end
end

DD_GUI.remove_conflicting_generic_mapper(true)
DD_GUI.schedule_generic_mapper_cleanup(false)

local profile_path = string.gsub(getMudletHomeDir(), "\\", "/")
local package_path = profile_path .. "/DD_GUI"
local content_path = profile_path .. "/DD_GUI_Content"
local lfs = require "lfs"

local function ensure_directory(path)
        if lfs.attributes(path, "mode") ~= "directory" then
                pcall(lfs.mkdir, path)
        end
end

local function copy_file(source, destination)
        local source_size = lfs.attributes(source, "size")
        if not source_size then
                return false
        end

        if lfs.attributes(destination, "size") == source_size then
                return true
        end

        local input = io.open(source, "rb")
        if not input then
                return false
        end

        local output = io.open(destination, "wb")
        if not output then
                input:close()
                return false
        end

        while true do
                local chunk = input:read(1024 * 1024)
                if not chunk then
                        break
                end
                output:write(chunk)
        end

        input:close()
        output:close()
        return true
end

local function copy_tree(source, destination)
        if lfs.attributes(source, "mode") ~= "directory" then
                return
        end

        ensure_directory(destination)
        for name in lfs.dir(source) do
                if name ~= "." and name ~= ".." then
                        local source_item = source .. "/" .. name
                        local destination_item = destination .. "/" .. name
                        local mode = lfs.attributes(source_item, "mode")
                        if mode == "directory" then
                                copy_tree(source_item, destination_item)
                        elseif mode == "file" then
                                copy_file(source_item, destination_item)
                        end
                end
        end
end

ms_path = content_path
DD_GUI.package_path = package_path
DD_GUI.content_path = content_path
ensure_directory(content_path)

function DD_GUI.asset_path(relative_path)
        local relative = tostring(relative_path or ""):gsub("\\", "/")
        local persistent_path = content_path .. "/" .. relative
        if lfs.attributes(persistent_path, "mode") == "file" then
                return persistent_path
        end
        return package_path .. "/" .. relative
end

function DD_GUI.migrate_legacy_content()
        ensure_directory(content_path)
        for _, directory in ipairs({
                "audio",
                "avatars",
                "compass",
                "custom_rooms",
                "environments",
                "layout",
                "maps",
                "mobs",
        }) do
                copy_tree(
                        package_path .. "/" .. directory,
                        content_path .. "/" .. directory
                )
        end
        copy_file(
                package_path .. "/custom_filelist.txt",
                content_path .. "/custom_filelist.txt"
        )
end

function myScriptInstalled(_, name)
        if tostring(name or ""):lower() == GENERIC_MAPPER_PACKAGE then
                DD_GUI.schedule_generic_mapper_cleanup(true)
                return
        end

        if name ~= "DD_GUI" then
                return
        end
        DD_GUI.remove_conflicting_generic_mapper(true)
        DD_GUI.schedule_generic_mapper_cleanup(true)
        DD_GUI.migrate_legacy_content()
        bootstrap()
end

function myScriptUninstalled(_, name)
        if name == "DD_GUI" then
                DD_GUI.cancel_generic_mapper_cleanup()
                if DD_GUI.unregister_data_refresh_handlers then
                        DD_GUI.unregister_data_refresh_handlers()
                end
                DD_GUI.migrate_legacy_content()
        end
end

local function register_package_handlers()
        DD_GUI.package_event_handlers = DD_GUI.package_event_handlers or {}
        for _, handler_id in pairs(DD_GUI.package_event_handlers) do
                if handler_id and type(killAnonymousEventHandler) == "function" then
                        pcall(killAnonymousEventHandler, handler_id)
                end
        end

        DD_GUI.package_event_handlers = {
                install = registerAnonymousEventHandler("sysInstallPackage", "myScriptInstalled"),
                uninstall = registerAnonymousEventHandler("sysUninstallPackage", "myScriptUninstalled"),
        }
end

register_package_handlers()
