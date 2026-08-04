function build_affects_console()
    AffectsConsole = Geyser.MiniConsole:new({
      name="AffectsConsole",
      x = "2%", y = "14%",
      width="96%",
      height="82%",
      autoWrap = true,
      color = "black",
      scrollBar = true,
      horizontalScrollBar = false,
      fontSize = 10,
    }, DD_GUI.AffectBox)
    if DD_GUI.Theme then
      DD_GUI.Theme:style_console(AffectsConsole, 10)
    end
end
