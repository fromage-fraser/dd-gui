if DD_GUI and DD_GUI.update_exit_status then
        -- Mudlet stores the first capture in matches[2]; matches[1] is the
        -- whole matched line. Prefer the capture so colour/control text
        -- outside the exit list cannot affect parsing.
        local line = matches and (matches[2] or matches[1]) or ""
        DD_GUI.update_exit_status(line, true)
end
