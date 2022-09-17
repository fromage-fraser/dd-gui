function build_charsheet_box()
        DD_GUI.CharsheetTopRow = Geyser.HBox:new({ 
          name = "DD_GUI.CharsheetTopRow", 
          x = "5%", y = "3%", 
          width = "100%", height = "10%", 
        },DD_GUI.CharsheetBox ) 
        
        CharsheetLabel = Geyser.Label:new({
          name = "CharsheetLabel",
          x = 0, y = "10%",
          width = "50%", height = "70%",
          message = [[Character Info]]
        }, DD_GUI.CharsheetTopRow )
        CharsheetLabel:setColor(0,0,0,0)
        CharsheetLabel:setFgColor("Cyan")
        CharsheetLabel:setFontSize(10)
        CharsheetLabel:setBold(1)
end
      