if DD_GUI and DD_GUI.update_exit_status then
        -- Pass the complete matched line when Mudlet provides it. The parser
        -- also accepts the capture-only form for older profile runtimes.
        local line = matches and (matches[1] or matches[2]) or ""
        DD_GUI.update_exit_status(line, true)
end
