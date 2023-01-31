function build_enemy_console()
  EnemyConsole = Geyser.MiniConsole:new({
    name="EnemyConsole",
    x = "4%", y = "13%",
    width="92%",
    height="83%",
    autoWrap = true,
    color = "black",
    scrollBar = false,
    fontSize = 10,
  }, DD_GUI.EnemyBox)

  EnemyTPConsoleTop = Geyser.MiniConsole:new({
    name="EnemyTPConsoleTop",
    x = "0%", y = "0%",
    width="100%",
    height="69%",
    autoWrap = true,
    color = "black",
    scrollBar = false,
    fontSize = 10,
  }, EnemyConsole)

  EnemyInfoConsole = Geyser.MiniConsole:new({
    name="EnemyInfoConsole",
    x = "0%", y = "72%",
    width="100%",
    height="30%",
    autoWrap = true,
    color = "black",
    scrollBar = false,
    fontSize = 10,
  }, EnemyConsole)

  EnemyConsoleHitpointsContainerCSS = CSSMan.new([[
    background-color: rgba(89,0,0,100);
    border-style: solid;
    border-width: 0px;
    border-radius: 5px;
    border-color: red;
    margin: 0px;
  ]])

  EnemyConsoleHitpointsContainer = Geyser.VBox:new({
    name = "EnemyConsoleHitpointsContainer",
    x = "0%", y = "45%",
    width = "100%", height = "35%",
  },EnemyInfoConsole)


  EnemyConsoleHitpointsGaugeBackCSS = CSSMan.new([[
      background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #bd3333, stop: 0.1 #bd2020, stop: 0.49 #990000, stop: 0.5 #700000, stop: 1 #990000);
      border-width: 1px;
      border-color: black;
      border-style: solid;
      border-radius: 7;
      padding: 5px;
  ]])

  EnemyConsoleHitpointsGaugeFrontCSS = CSSMan.new([[
      background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #f04141, stop: 0.1 #ef2929, stop: 0.49 #cc0000, stop: 0.5 #a40000, stop: 1 #cc0000);
      border-top: 1px black solid;
      border-left: 1px black solid;
      border-bottom: 1px black solid;
      border-radius: 7;
      padding: 5px;
  ]])

  EnemyConsoleHitpoints = Geyser.Gauge:new({ name = "EnemyConsoleHitpoints", }, EnemyConsoleHitpointsContainer)
  EnemyConsoleHitpoints.back:setStyleSheet(EnemyConsoleHitpointsGaugeBackCSS:getCSS())
  EnemyConsoleHitpoints.front:setStyleSheet(EnemyConsoleHitpointsGaugeFrontCSS:getCSS())

  EnemyHitpointsLabel = Geyser.Label:new({
    name = "EnemyHitpointsLabel",
    x = 0, y = "15%",
    width = "30%", height = "70%",
    fgColor = "black",
    message = [[&nbsp;Hits]]
  },EnemyConsoleHitpoints )
  EnemyHitpointsLabel:setColor(0,0,0,0)
  EnemyHitpointsLabel:setFgColor("Grey")
  EnemyHitpointsLabel:setFontSize(10)
end