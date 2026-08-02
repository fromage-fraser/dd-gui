function update_channel_status()
        if gmcp and gmcp.Char and gmcp.Char.Channels
        and DD_GUI and DD_GUI.Comms and DD_GUI.Comms.handle_channel_state then
                DD_GUI.Comms:handle_channel_state(gmcp.Char.Channels)
        end
end
