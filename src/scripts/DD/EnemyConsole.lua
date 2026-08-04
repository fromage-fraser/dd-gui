function build_enemy_console()

    EnemyConsole = Geyser.MiniConsole:new({
      name="EnemyConsole",
      x = "4%", y = "6%",
      width="92%",
      height="91%",
      autoWrap = false,
      color = "black",
      scrollBar = false,
      fontSize = 10,
    }, DD_GUI.EnemyBox)
    if DD_GUI.Theme then
      DD_GUI.Theme:style_console(EnemyConsole, 10)
    end

    EnemyImageFrame = Geyser.Label:new({
      name="EnemyImageFrame",
      x = "0%", y = "0%",
      width="100%",
      height="69%",
    }, EnemyConsole)
    EnemyImageFrame:setStyleSheet(DD_GUI.Theme and
      DD_GUI.Theme:image_frame_css() or [[border: 0px;]])
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(EnemyImageFrame, true)
    end

    EnemyTPConsoleTop = Geyser.MiniConsole:new({
      name="EnemyTPConsoleTop",
      x = "0%", y = "0%",
      width="100%",
      height="69%",
      autoWrap = false,
      color = "black",
      scrollBar = false,
      fontSize = 10,
    }, EnemyConsole)
    if DD_GUI.Theme then
      DD_GUI.Theme:style_console(EnemyTPConsoleTop, 10)
    end

    EnemyInfoConsole = Geyser.MiniConsole:new({
      name="EnemyInfoConsole",
      x = "0%", y = "72%",
      width="100%",
      height="30%",
      autoWrap = false,
      color = "black",
      scrollBar = false,
      fontSize = 10,
    }, EnemyConsole)
    if DD_GUI.Theme then
      DD_GUI.Theme:style_console(EnemyInfoConsole, 10)
    end

    EnemyConsoleHitpointsContainerCSS = CSSMan.new([[
      background-color: rgb(0,0,0);
      border-style: solid;
      border-width: 0px;
      border-radius: 5px;
      border-color: red;
      margin: 0px;
    ]])

    EnemyConsoleHitpointsContainer = Geyser.VBox:new({
      name = "EnemyConsoleHitpointsContainer",
      x = "0%", y = "50%",
      width = "100%", height = "35%",
    },EnemyInfoConsole)


    local theme = DD_GUI.Theme
    EnemyConsoleHitpointsGaugeBackCSS = CSSMan.new(theme and
      theme:gauge_back_css() or [[background-color: rgb(0,0,0);]])
    EnemyConsoleHitpointsGaugeFrontCSS = CSSMan.new(theme and
      theme:gauge_front_css(theme.colors.hp) or
      [[background-color: rgb(180,0,0);]])

    EnemyConsoleHitpoints = Geyser.Gauge:new({ name = "EnemyConsoleHitpoints", }, EnemyConsoleHitpointsContainer)
    EnemyConsoleHitpoints.back:setStyleSheet(EnemyConsoleHitpointsGaugeBackCSS:getCSS())
    EnemyConsoleHitpoints.front:setStyleSheet(EnemyConsoleHitpointsGaugeFrontCSS:getCSS())

    for index = 1, 9 do
      local separator = Geyser.Label:new({
        name = "EnemyConsoleHitpoints.Segment." .. index,
        x = tostring(index * 10) .. "%",
        y = 0,
        width = 1,
        height = "100%",
      }, EnemyConsoleHitpoints)
      separator:setStyleSheet([[
        background-color: rgba(0,0,0,185);
        border: 0px;
      ]])
      if DD_GUI.set_widget_clickthrough then
        DD_GUI.set_widget_clickthrough(separator, true)
      end
    end

    EnemyHitpointsLabel = Geyser.Label:new({
      name = "EnemyHitpointsLabel",
      x = 0, y = 0,
      width = "100%", height = "100%",
      fgColor = "black",
      message = [[HITS]]
    },EnemyConsoleHitpoints )
    EnemyHitpointsLabel:setColor(0,0,0,0)
    EnemyHitpointsLabel:setFgColor("white")
    EnemyHitpointsLabel:echo("HITS", "white", "c")
    if theme then
      theme:style_label(EnemyHitpointsLabel, 9, true)
    else
      EnemyHitpointsLabel:setFontSize(9)
    end
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(EnemyHitpointsLabel, true)
    end

  end
