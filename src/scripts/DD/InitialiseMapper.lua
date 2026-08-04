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
