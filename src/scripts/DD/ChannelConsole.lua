function build_channel_console()
        ChannelConsole = Geyser.MiniConsole:new({
          name="ChannelConsole",
          x = "4%", y = "13%",
          width="92%", 
          height="83%",
          autoWrap = true,
          color = "black",
          scrollBar = false,
          fontSize = 10,
        }, DD_GUI.ChannelBox)
        ChannelConsole:enableCommandLine()
        setFontSize("ChannelConsole", 8)
end