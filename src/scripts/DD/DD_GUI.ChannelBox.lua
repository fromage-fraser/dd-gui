function build_channel_box()
        DD_GUI.ChannelTopRow = Geyser.HBox:new({ 
          name = "DD_GUI.ChannelTopRow", 
          x = "5%", y = "3%", 
          width = "100%", height = "10%", 
        },DD_GUI.ChannelBox ) 
        
        ChannelTitleLabel = Geyser.Label:new({
          name = "ChannelTitleLabel",
          x = 0, y = "10%",
          width = "50%", height = "70%",
          message = [[Comms]]
        }, DD_GUI.ChannelTopRow )
        ChannelTitleLabel:setColor(0,0,0,0)
        ChannelTitleLabel:setFgColor("Cyan")
        ChannelTitleLabel:setFontSize(10)
        ChannelTitleLabel:setBold(1)
end