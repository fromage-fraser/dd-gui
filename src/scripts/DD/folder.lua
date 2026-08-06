DD_GUI = DD_GUI or {}
mudlet = mudlet or {}

-- Mudlet builds without getPackageInfo() still need a reliable way to show
-- the installed GUI version and decide whether bootstrap() may be reused.
DD_GUI.package_version = "0.0.62"

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

mudlet.mapper_script = true

function myScriptInstalled(_, name)
        if name ~= "DD_GUI" then
                return
        end
        DD_GUI.migrate_legacy_content()
        bootstrap()
end

function myScriptUninstalled(_, name)
        if name == "DD_GUI" then
                DD_GUI.migrate_legacy_content()
        end
end

registerAnonymousEventHandler("sysInstallPackage", "myScriptInstalled")
registerAnonymousEventHandler("sysUninstallPackage", "myScriptUninstalled")
