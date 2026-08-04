local version
if DD_GUI and DD_GUI.package_version then
        version = DD_GUI.package_version
elseif type(getPackageInfo) == "function" then
        version = getPackageInfo("DD_GUI", "version")
end

if version and version ~= "" then
        echo("\nDD_GUI version: " .. tostring(version) .. "\n")
else
        echo("\nDD_GUI package version is unavailable.\n")
end
