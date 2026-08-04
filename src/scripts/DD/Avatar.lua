DD_GUI = DD_GUI or {}

function DD_GUI.profile_avatar_filename()
        if not gmcp or not gmcp.Char or type(gmcp.Char.Base) ~= "table" then
                return nil
        end

        local character_name = tostring(gmcp.Char.Base.name or ""):lower()
        character_name = character_name:gsub("[^%w]+", "_")
        character_name = character_name:gsub("^_+", ""):gsub("_+$", "")
        if character_name == "" then
                return nil
        end

        local filename = character_name .. ".png"
        local avatar_path = DD_GUI.asset_path and
                DD_GUI.asset_path("avatars/" .. filename) or
                ms_path .. "/avatars/" .. filename
        if file_exists(avatar_path) then
                return filename
        end

        return nil
end
