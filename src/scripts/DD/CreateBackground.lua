function create_background()
        local theme = DD_GUI.Theme
        local background_css = theme and theme:band_css() or [[
          background-color: rgb(0,0,0);
        ]]

        DD_GUI.BackgroundCSS = CSSMan.new(background_css)
        
        DD_GUI.Right = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Right",
          x = "-28%", y = "3%",
          width = "28%",
          height = "94%",
          padding = 0,
        }, nil, background_css)
        
        DD_GUI.Top = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Top",
          x = "0%", y = "3%",
          width = "100%",
          height = "33%",
          padding = 0,
        }, nil, background_css)
        
        DD_GUI.Bottom = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Bottom",
          x = "0%", y = "93%",
          width = "72%",
          height = "4%",
          padding = 0,
        }, nil, background_css, {direct = true})
end
