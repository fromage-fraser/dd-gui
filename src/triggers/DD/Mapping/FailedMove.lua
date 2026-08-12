local line = tostring(matches and matches[1] or ""):lower()
if DD_GUI and DD_GUI.mark_pending_exit_failed then
        if string.find(line, "lack the key", 1, true) or
           string.find(line, "locked", 1, true) then
                DD_GUI.mark_pending_exit_failed("locked")
        elseif string.find(line, "wall blocks", 1, true) then
                DD_GUI.mark_pending_exit_failed("wall")
        elseif string.find(line, " is closed", 1, true) or
               string.find(line, " are closed", 1, true) then
                DD_GUI.mark_pending_exit_failed("closed")
        end
end
raiseEvent("onMoveFail")
