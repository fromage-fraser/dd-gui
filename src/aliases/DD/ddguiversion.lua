local version
if type(getPackageInfo) == "function" then
        version = getPackageInfo("DD_GUI", "version")
end

if version and version ~= "" then
        echo("\nDD_GUI version: " .. tostring(version) .. "\n")
else
        echo("\nDD_GUI package version is unavailable.\n")
end
