function build_channel_box()
        -- Hide the title created by older package versions before using the
        -- full channel box for tabs and comms text.
        if DD_GUI.ChannelTopRow and DD_GUI.ChannelTopRow.hide then
                DD_GUI.ChannelTopRow:hide()
        end

        if ChannelTitleLabel and ChannelTitleLabel.hide then
                ChannelTitleLabel:hide()
        end

        DD_GUI.ChannelTopRow = nil
        ChannelTitleLabel = nil
end
