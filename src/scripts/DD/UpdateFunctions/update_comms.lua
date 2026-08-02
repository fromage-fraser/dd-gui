function update_comms()
        if DD_GUI and DD_GUI.Comms and DD_GUI.Comms.handle_gmcp then
                DD_GUI.Comms:handle_gmcp()
        end
end
