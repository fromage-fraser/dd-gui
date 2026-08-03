function create_background()
        DD_GUI.BackgroundCSS = CSSMan.new([[
          background-color: rgb(0,0,0);
        ]])
        
        DD_GUI.Right = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Right",
          x = "-26%", y = "0%",
          width = "26%",
          height = "100%",
          padding = 0,
        }, nil, DD_GUI.BackgroundCSS:getCSS())
        
        DD_GUI.Top = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Top",
          x = "0%", y = "0%",
          width = "100%",
          height = "36%",
          padding = 0,
        }, nil, DD_GUI.BackgroundCSS:getCSS())
        
        DD_GUI.Bottom = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Bottom",
          x = "0%", y = "94%",
          width = "74%",
          height = "6%",
          padding = 0,
        }, nil, DD_GUI.BackgroundCSS:getCSS(), {direct = true})
end
