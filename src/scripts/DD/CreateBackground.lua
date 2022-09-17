function create_background()
        DD_GUI.BackgroundCSS = CSSMan.new([[
          background-color: rgb(90,0,0);
        ]])
        
        DD_GUI.Right = Geyser.Label:new({
          name = "DD_GUI.Right",
          x = "-26%", y = "0%",
          width = "26%",
          height = "100%",
        })
        DD_GUI.Right:setStyleSheet(DD_GUI.BackgroundCSS:getCSS())
        
        DD_GUI.Top = Geyser.Label:new({
          name = "DD_GUI.Top",
          x = "0%", y = "0%",
          width = "100%",
          height = "36%",
        })
        DD_GUI.Top:setStyleSheet(DD_GUI.BackgroundCSS:getCSS())
        
        DD_GUI.Bottom = Geyser.Label:new({
          name = "DD_GUI.Bottom",
          x = "0%", y = "94%",
          width = "74%",
          height = "6%",
        })
        DD_GUI.Bottom:setStyleSheet(DD_GUI.BackgroundCSS:getCSS())
end