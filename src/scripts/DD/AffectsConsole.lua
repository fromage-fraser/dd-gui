function build_affects_console()
    if AffectsConsole and AffectsConsole.hide then
      AffectsConsole:hide()
    end
    if QuestStatusConsole and QuestStatusConsole.hide then
      QuestStatusConsole:hide()
    end

    DD_GUI.Affects.consoles = {}

    AffectsConsole = Geyser.MiniConsole:new({
      name = "AffectsConsole",
      x = "0%", y = "0%",
      width = "100%",
      height = "100%",
      autoWrap = true,
      color = "black",
      scrollBar = true,
      horizontalScrollBar = false,
      fontSize = 10,
    }, DD_GUI.Affects.content_stack)
    if DD_GUI.Theme then
      DD_GUI.Theme:style_console(AffectsConsole, 10)
    end

    QuestStatusConsole = Geyser.MiniConsole:new({
      name = "QuestStatusConsole",
      x = "0%", y = "0%",
      width = "100%",
      height = "100%",
      autoWrap = true,
      color = "black",
      scrollBar = true,
      horizontalScrollBar = false,
      fontSize = 10,
    }, DD_GUI.Affects.content_stack)
    if DD_GUI.Theme then
      DD_GUI.Theme:style_console(QuestStatusConsole, 10)
    end

    DD_GUI.Affects.consoles.affects = AffectsConsole
    DD_GUI.Affects.consoles.quest = QuestStatusConsole
    DD_GUI.Affects:switch_tab(DD_GUI.Affects.current_tab or "affects")
end
