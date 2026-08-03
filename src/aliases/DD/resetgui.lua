if DD_GUI and type(DD_GUI.reset_layout) == "function" then
        DD_GUI.reset_layout()
        echo("\nDD_GUI layout reset to defaults.\n")
else
        echo("\nDD_GUI layout reset is unavailable until bootstrap completes.\n")
end
