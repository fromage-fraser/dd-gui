function build_gauges()

    DD_GUI.Footer = Geyser.HBox:new({
      name = "DD_GUI.Footer",
      x = "5%", y = "15%",
      width = "94%", height = "70%",
    },DD_GUI.Bottom )

    DD_GUI.FirstColumn = Geyser.VBox:new({
      name = "DD_GUI.FirstColumn",
      x = "0%", y = "0%",
      width = "25%", height = "100%",
    },DD_GUI.Footer)

    DD_GUI.SecondColumn = Geyser.VBox:new({
      name = "DD_GUI.SecondColumn",
      x = "0%", y = "0%",
      width = "25%", height = "100%",
    },DD_GUI.Footer)

    DD_GUI.ThirdColumn = Geyser.VBox:new({
      name = "DD_GUI.ThirdColumn",
      x = "0%", y = "0%",
      width = "25%", height = "100%",
    },DD_GUI.Footer)

    DD_GUI.FourthColumn = Geyser.VBox:new({
      name = "DD_GUI.FourthColumn",
      x = "0%", y = "0%",
      width = "25%", height = "100%",
    },DD_GUI.Footer)


    --Hitpoints

    DD_GUI.HitpointsGaugeBackCSS = CSSMan.new([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #bd3333, stop: 0.1 #bd2020, stop: 0.49 #990000, stop: 0.5 #700000, stop: 1 #990000);
        border-width: 1px;
        border-color: black;
        border-style: solid;
        border-radius: 7;
        padding: 10px;
    ]])

    DD_GUI.HitpointsGaugeFrontCSS = CSSMan.new([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #f04141, stop: 0.1 #ef2929, stop: 0.49 #cc0000, stop: 0.5 #a40000, stop: 1 #cc0000);
        border-top: 1px black solid;
        border-left: 1px black solid;
        border-bottom: 1px black solid;
        border-radius: 7;
        padding: 10px;
    ]])

    DD_GUI.Hitpoints = Geyser.Gauge:new({ name = "DD_GUI.Hitpoints", },DD_GUI.FirstColumn)
    DD_GUI.Hitpoints.back:setStyleSheet(DD_GUI.HitpointsGaugeBackCSS:getCSS())
    DD_GUI.Hitpoints.front:setStyleSheet(DD_GUI.HitpointsGaugeFrontCSS:getCSS())
    if (gmcp.Char.Vitals.hp > gmcp.Char.Vitals.maxhp) then
      gmcp.Char.Vitals.maxhp = gmcp.Char.Vitals.hp
    end
    DD_GUI.Hitpoints:setValue(((gmcp.Char.Vitals.hp * 1000) / gmcp.Char.Vitals.maxhp),1000)

    HitpointsLabel = Geyser.Label:new({
      name = "HitpointsLabel",
      x = 0, y = "15%",
      width = "50%", height = "70%",
      fgColor = "black",
      message = [[&nbsp;Hits]]
    }, DD_GUI.Hitpoints )
    HitpointsLabel:setColor(0,0,0,0)
    HitpointsLabel:setFgColor("Grey")
    HitpointsLabel:setFontSize(10)

    --Mana

    DD_GUI.ManaGaugeBackCSS = CSSMan.new([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #3833bd, stop: 0.1 #2020bd, stop: 0.49 #000399, stop: 0.5 #000470, stop: 1 #000399);
        border-top: 1px black solid;
        border-left: 1px black solid;
        border-bottom: 1px black solid;
        border-radius: 7;
        padding: 10px;
    ]])

    DD_GUI.ManaGaugeFrontCSS = CSSMan.new([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #4147f0, stop: 0.1 #2929f0, stop: 0.49 #0007cc, stop: 0.5 #0000a3, stop: 1 #0007cc);
        border-width: 1px;
        border-color: black;
        border-style: solid;
        border-radius: 7;
        padding: 10px;
    ]])

    DD_GUI.Mana = Geyser.Gauge:new({ name = "DD_GUI.Mana", },DD_GUI.SecondColumn)
    DD_GUI.Mana.back:setStyleSheet(DD_GUI.ManaGaugeBackCSS:getCSS())
    DD_GUI.Mana.front:setStyleSheet(DD_GUI.ManaGaugeFrontCSS:getCSS())
    if (gmcp.Char.Vitals.mana > gmcp.Char.Vitals.maxmana) then
      gmcp.Char.Vitals.maxmana = gmcp.Char.Vitals.mana
    end
    DD_GUI.Mana:setValue(((gmcp.Char.Vitals.mana * 1000) / gmcp.Char.Vitals.maxmana),1000)

    ManaLabel = Geyser.Label:new({
      name = "ManaLabel",
      x = 0, y = "15%",
      width = "50%", height = "70%",
      fgColor = "Black",
      message = [[&nbsp;Mana]]
    }, DD_GUI.Mana )
    ManaLabel:setColor(0,0,0,0)
    ManaLabel:setFgColor("Grey")
    ManaLabel:setFontSize(10)

    -- XP

    DD_GUI.XpGaugeBackCSS = CSSMan.new([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #78bd33, stop: 0.1 #6ebd20, stop: 0.49 #4c9900, stop: 0.5 #387000, stop: 1 #4c9900);
        border-top: 1px black solid;
        border-left: 1px black solid;
        border-bottom: 1px black solid;
        border-radius: 7;
        padding: 10px;
    ]])

    DD_GUI.XpGaugeFrontCSS = CSSMan.new([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #98f041, stop: 0.1 #8cf029, stop: 0.49 #66cc00, stop: 0.5 #52a300, stop: 1 #66cc00);
        border-width: 1px;
        border-color: black;
        border-style: solid;
        border-radius: 7;
        padding: 10px;
    ]])

    DD_GUI.Xp = Geyser.Gauge:new({ name = "DD_GUI.Xp", },DD_GUI.ThirdColumn)
    DD_GUI.Xp.back:setStyleSheet(DD_GUI.XpGaugeBackCSS:getCSS())
    DD_GUI.Xp.front:setStyleSheet(DD_GUI.XpGaugeFrontCSS:getCSS())
    --DD_GUI.Xp:setValue(((gmcp.Char.Worth.xplvl * 1000) / (gmcp.Char.Worth.xplvl - gmcp.Char.Worth.xptnl)), 1000)
    DD_GUI.Xp:setValue((((gmcp.Char.Worth.xplvl - gmcp.Char.Worth.xptnl) * 1000) / gmcp.Char.Worth.xplvl), 1000)

    XpLabel = Geyser.Label:new({
      name = "XpLabel",
      x = 0, y = "15%",
      width = "50%", height = "70%",
      fgColor = "Black",
      message = [[&nbsp;Xp]]
    }, DD_GUI.Xp )
    XpLabel:setColor(0,0,0,0)
    XpLabel:setFgColor("White")
    XpLabel:setFontSize(10)

    --Moves

    DD_GUI.MovesGaugeBackCSS = CSSMan.new([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #33bdb4, stop: 0.1 #20bdb0, stop: 0.49 #009996, stop: 0.5 #00706e, stop: 1 #009996);
        border-top: 1px black solid;
        border-left: 1px black solid;
        border-bottom: 1px black solid;
        border-radius: 7;
        padding: 10px;
    ]])

    DD_GUI.MovesGaugeFrontCSS = CSSMan.new([[
        background-color: QLinearGradient( x1: 0, y1: 0, x2: 0, y2: 1, stop: 0 #41f0d6, stop: 0.1 #29f0df, stop: 0.49 #00ccc9, stop: 0.5 #009ea3, stop: 1 #00ccc9);
        border-width: 1px;
        border-color: black;
        border-style: solid;
        border-radius: 7;
        padding: 10px;
    ]])

    DD_GUI.Moves = Geyser.Gauge:new({ name = "DD_GUI.Moves", }, DD_GUI.FourthColumn)
    DD_GUI.Moves.back:setStyleSheet(DD_GUI.MovesGaugeBackCSS:getCSS())
    DD_GUI.Moves.front:setStyleSheet(DD_GUI.MovesGaugeFrontCSS:getCSS())
    if (gmcp.Char.Vitals.move > gmcp.Char.Vitals.maxmove) then
      gmcp.Char.Vitals.maxmove = gmcp.Char.Vitals.move
    end
    DD_GUI.Moves:setValue(((gmcp.Char.Vitals.move * 1000) / gmcp.Char.Vitals.maxmove),1000)

    MovesLabel = Geyser.Label:new({
      name = "MovesLabel",
      x = 0, y = "15%",
      width = "50%", height = "70%",
      fgColor = "Black",
      message = [[&nbsp;Moves]]
    }, DD_GUI.Moves )
    MovesLabel:setColor(0,0,0,0)
    MovesLabel:setFgColor("White")
    MovesLabel:setFontSize(10)

  end