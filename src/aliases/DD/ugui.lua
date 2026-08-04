if DD_GUI and DD_GUI.migrate_legacy_content then
        DD_GUI.migrate_legacy_content()
end

echo("Uninstalling package 'DD_GUI'...\n")
uninstallPackage("DD_GUI")
