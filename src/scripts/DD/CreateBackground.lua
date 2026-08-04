function create_background()
        local theme = DD_GUI.Theme
        local background_css = theme and theme:band_css() or [[
          background-color: rgb(0,0,0);
        ]]

        DD_GUI.BackgroundCSS = CSSMan.new(background_css)
        
        DD_GUI.Right = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Right",
          x = "-28%", y = "0%",
          width = "28%",
          height = "100%",
          padding = 0,
        }, nil, background_css)
        
        DD_GUI.Top = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Top",
          x = "0%", y = "0%",
          width = "100%",
          height = "36%",
          padding = 0,
        }, nil, background_css)
        
        DD_GUI.Bottom = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Bottom",
          x = "0%", y = "94%",
          width = "72%",
          height = "6%",
          padding = 0,
        }, nil, background_css, {direct = true})
end
