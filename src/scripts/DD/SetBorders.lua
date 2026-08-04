function set_borders()
        local w,h = getMainWindowSize()
        local padding = tonumber(DD_GUI and DD_GUI.mainconsole_padding) or 8
        setBorderTop((h * 36) / 100 + padding)
        setBorderBottom((h * 6) / 100 + padding)
        setBorderRight((w * 34) / 100 + padding)
        setBorderLeft(padding)
end
