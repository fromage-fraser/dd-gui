function set_borders()
        local w,h = getMainWindowSize()
        setBorderTop((h * 36) / 100)
        setBorderBottom((h * 6) / 100)
        setBorderRight((w * 26) / 100)
end