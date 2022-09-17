function build_affects_box()

        DD_GUI.AffectsTopRow = Geyser.HBox:new({ 
          name = "DD_GUI.AffectsTopRow", 
          x = "5%", y = "3%", 
          width = "100%", height = "10%", 
        },DD_GUI.AffectBox ) 
        
        AffectsTitleLabel = Geyser.Label:new({
          name = "AffectsTitleLabel",
          x = 0, y = "10%",
          width = "50%", height = "70%",
          message = [[You are affected by:]]
        }, DD_GUI.AffectsTopRow )
        AffectsTitleLabel:setColor(0,0,0,0)
        AffectsTitleLabel:setFgColor("Cyan")
        AffectsTitleLabel:setFontSize(10)
        AffectsTitleLabel:setBold(1)
end