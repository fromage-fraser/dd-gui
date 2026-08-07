local function file_exists(path)
        local file = io.open(path, "rb")
        if not file then
                return false
        end

        file:close()
        return true
end

local function asset_path(relative_path)
        if DD_GUI and DD_GUI.asset_path then
                return DD_GUI.asset_path(relative_path)
        end

        return string.gsub(
                getMudletHomeDir() .. "/DD_GUI/" .. relative_path,
                "\\", "/"
        )
end

function dd_mapper_save_path()
        -- Keep player map data outside the package resource folder so reinstalls preserve it.
        return string.gsub(getMudletHomeDir() .. "/dragons_domain_mapper.dat", "\\", "/")
end

local function legacy_mapper_save_path()
        local package_path = DD_GUI and DD_GUI.package_path or
                getMudletHomeDir() .. "/DD_GUI"
        return string.gsub(package_path .. "/maps/dragons_domain_mapper.dat", "\\", "/")
end

local map_info_title_name = "DD_GUI.MapTitle"
local map_info_accent_name = "DD_GUI.MapTitleAccent"

local function compact_map_title(room_id)
        local id = tonumber(room_id)
        if not id or type(roomExists) ~= "function" then
                return ""
        end

        local exists_ok, exists = pcall(roomExists, id)
        if not exists_ok or not exists then
                return ""
        end

        local name_ok, name = pcall(getRoomName, id)
        if not name_ok or not name or tostring(name) == "" then
                return tostring(id)
        end

        local title = tostring(name):gsub("[\r\n]+", " ") .. " / " .. tostring(id)
        -- The native mapper wraps map-info fragments. Keep the title on one
        -- line so north rooms remain visible in the small embedded viewport.
        if #title > 40 then
                title = title:sub(1, 37):gsub("%s+%S*$", "") .. "..."
        end
        return title
end

function DD_GUI.apply_mapper_theme()
        if type(setConfig) == "function" then
                pcall(function()
                        -- Keep northern room symbols visible if the native
                        -- title reaches into the top of the map.
                        setConfig("mapInfoColor", {0, 0, 0, 0})
                end)
        end

        if type(registerMapInfo) ~= "function" or
           type(enableMapInfo) ~= "function" then
                return
        end

        pcall(function()
                registerMapInfo(map_info_title_name, function(room_id)
                        local title = compact_map_title(room_id)
                        if title == "" then
                                return ""
                        end
                        return title, false, false, 255, 255, 255
                end)
                disableMapInfo("Short")
                -- Older builds registered a red rule beneath the title. Hide
                -- that persisted map-info entry so it cannot cover northern
                -- rooms after an upgrade.
                disableMapInfo(map_info_accent_name)
                enableMapInfo(map_info_title_name)
        end)
end

function save_dd_mapper()
        local saved, error_message = saveMap(dd_mapper_save_path())
        if not saved then
                cecho(string.format("<red>Unable to save Dragons Domain map: %s<reset>\n", error_message or "unknown error"))
        end

        return saved
end

function initialise_mapper()
        expandAlias("ignores")

        local bundled_map = asset_path("maps/mud_school.dat")
        local persistent_map = dd_mapper_save_path()
        local legacy_map = legacy_mapper_save_path()
        local map_to_load = bundled_map
        local migrate_legacy_map = false

        if file_exists(persistent_map) then
                map_to_load = persistent_map
        elseif file_exists(legacy_map) then
                map_to_load = legacy_map
                migrate_legacy_map = true
        end

        local loaded, error_message = loadMap(map_to_load)

        if not loaded and map_to_load ~= bundled_map then
                cecho(string.format("<yellow>Unable to load saved Dragons Domain map: %s. Loading the bundled map instead.<reset>\n", error_message or "unknown error"))
                loadMap(bundled_map)
        elseif migrate_legacy_map then
                save_dd_mapper()
        end
end
