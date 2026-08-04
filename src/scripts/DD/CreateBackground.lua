function create_background()
        local theme = DD_GUI.Theme
        local background_css = theme and theme:band_css() or [[
          background-color: rgb(0,0,0);
        ]]
        local right_css = theme and theme:band_css("left") or background_css
        local top_css = theme and theme:band_css("bottom") or background_css
        local bottom_css = theme and theme:band_css("top") or background_css

        DD_GUI.BackgroundCSS = CSSMan.new(background_css)
        
        DD_GUI.Right = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Right",
          x = "-26%", y = "0%",
          width = "26%",
          height = "100%",
          padding = 0,
        }, nil, right_css)
        
        DD_GUI.Top = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Top",
          x = "0%", y = "0%",
          width = "100%",
          height = "36%",
          padding = 0,
        }, nil, top_css)
        
        DD_GUI.Bottom = DD_GUI.new_adjustable_region({
          name = "DD_GUI.Bottom",
          x = "0%", y = "94%",
          width = "74%",
          height = "6%",
          padding = 0,
        }, nil, bottom_css, {direct = true})
end
