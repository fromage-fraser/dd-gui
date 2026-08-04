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

    -- Keep descriptive text outside the native EnemyConsole viewport.
    -- MiniConsole can repaint its own surface over nested child consoles.
    EnemyInfoConsole = Geyser.MiniConsole:new({
      name="EnemyInfoConsole",
      x = "4%", y = "72%",
      width="92%",
      height="14%",
      autoWrap = false,
      color = "black",
      scrollBar = false,
      fontSize = 10,
    }, DD_GUI.EnemyBox)
    if DD_GUI.Theme then
      DD_GUI.Theme:style_console(EnemyInfoConsole, 10)
    end

    -- Keep the complete gauge outside both MiniConsole viewports. Native
    -- console surfaces can repaint over nested gauges, so the bar uses
    -- direct sibling labels for deterministic stacking.
    EnemyConsoleHitpointsContainer = Geyser.Label:new({
      name = "EnemyConsoleHitpointsContainer",
      x = "4%", y = "85%",
      width = "92%", height = "10%",
    }, DD_GUI.EnemyBox)
    local theme = DD_GUI.Theme
    EnemyConsoleHitpointsGaugeBackCSS = CSSMan.new(theme and
      theme:gauge_back_css() or [[background-color: rgb(0,0,0);]])
    EnemyConsoleHitpointsGaugeFrontCSS = CSSMan.new(theme and
      theme:gauge_front_css(theme.colors.hp) or
      [[background-color: rgb(180,0,0);]])

    EnemyConsoleHitpointsContainer:setStyleSheet(
      EnemyConsoleHitpointsGaugeBackCSS:getCSS()
    )

    EnemyConsoleHitpoints = Geyser.Label:new({
      name = "EnemyConsoleHitpoints",
      x = "4%", y = "85%",
      width = "0%", height = "10%",
    }, DD_GUI.EnemyBox)
    EnemyConsoleHitpoints:setStyleSheet(
      EnemyConsoleHitpointsGaugeFrontCSS:getCSS()
    )

    function EnemyConsoleHitpoints:setValue(value, maximum)
      local current = tonumber(value) or 0
      local limit = tonumber(maximum) or 100
      local ratio = 0
      if limit > 0 then
        ratio = math.max(0, math.min(1, current / limit))
      end
      self:resize(string.format("%.3f%%", ratio * 100), "10%")
    end

    EnemyHitpointsLabel = Geyser.Label:new({
      name = "EnemyHitpointsLabel",
      x = "4%", y = "85%",
      width = "92%", height = "10%",
      fgColor = "black",
      message = [[HITS]]
    }, DD_GUI.EnemyBox)
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
