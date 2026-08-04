if DD_GUI and DD_GUI.Layout and type(DD_GUI.Layout.command) == "function" then
        DD_GUI.Layout:command(matches[2])
else
        echo("\nDD_GUI layout mode is unavailable until bootstrap completes.\n")
end
