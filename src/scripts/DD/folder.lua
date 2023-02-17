DD_GUI = DD_GUI or {}
mudlet = mudlet or {}

ms_path = string.gsub(getMudletHomeDir().."/DD_GUI","\\","/")

mudlet.mapper_script = true

function myScriptInstalled(_, name)
    -- stop if what got installed isn't my thing
    if name ~= "DD_GUI" then return end
    bootstrap()
end

registerAnonymousEventHandler("sysInstallPackage", "myScriptInstalled")