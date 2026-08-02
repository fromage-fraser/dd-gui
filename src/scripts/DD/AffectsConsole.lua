function build_affects_console()
    AffectsConsole = Geyser.MiniConsole:new({
      name="AffectsConsole",
      x = "4%", y = "14%",
      width="92%",
      height="82%",
      autoWrap = false,
      color = "black",
      scrollBar = true,
      fontSize = 10,
    }, DD_GUI.AffectBox)
end
