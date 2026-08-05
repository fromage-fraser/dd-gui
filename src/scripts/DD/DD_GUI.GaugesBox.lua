local function gauge_value(value, maximum)
    value = tonumber(value) or 0
    maximum = tonumber(maximum) or 0
    if maximum <= 0 then
      return 0
    end
    return math.max(0, math.min(1000, (value * 1000) / maximum))
end

local function delete_existing_widget(widget)
    if not widget then
      return
    end

    if type(widget.delete) == "function" then
      pcall(function() widget:delete() end)
    elseif widget.name and type(deleteLabel) == "function" then
      pcall(deleteLabel, widget.name)
    end
end

local function add_gauge_segments(gauge, name)
    for index = 1, 9 do
      local separator = Geyser.Label:new({
        name = name .. ".Segment." .. index,
        x = tostring(index * 10) .. "%",
        y = 0,
        width = 1,
        height = "100%",
      }, gauge)
      separator:setStyleSheet([[
        background-color: rgba(0,0,0,185);
        border: 0px;
        margin: 0px;
      ]])
      if DD_GUI.set_widget_clickthrough then
        DD_GUI.set_widget_clickthrough(separator, true)
      end
    end
end

local function new_status_gauge(name, parent, label_text, color, value, maximum)
    local theme = DD_GUI.Theme
    local gauge = Geyser.Gauge:new({
      name = name,
      x = "0%", y = "15%",
      width = "100%", height = "70%",
      strict = true,
    }, parent)

    gauge.back:setStyleSheet(theme and theme:gauge_back_css() or [[
      background-color: rgb(0,0,0);
      border: 1px solid grey;
      border-radius: 0px;
    ]])
    gauge.front:setStyleSheet(theme and theme:gauge_front_css(color) or [[
      background-color: grey;
      border: 1px solid black;
      border-radius: 0px;
    ]])
    gauge:setValue(gauge_value(value, maximum), 1000)
    add_gauge_segments(gauge, name)

    local label = Geyser.Label:new({
      name = name .. ".Label",
      x = 0, y = 0,
      width = "100%", height = "100%",
    }, gauge)
    label:setColor(0, 0, 0, 0)
    label:setFgColor("white")
    label:echo(label_text, "white", "c")
    if theme then
      theme:style_label(label, 9, true)
    else
      label:setFontSize(9)
      label:setBold(1)
    end
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(label, true)
    end

    return gauge, label
end

function build_gauges()
    -- Package upgrades used shorter legacy label names. Remove both those
    -- labels and the previous gauge tree before rebuilding so an in-session
    -- update cannot leave old text beneath the segmented bars.
    if type(deleteLabel) == "function" then
      for _, legacy_name in ipairs({
        "HitpointsLabel", "ManaLabel", "XpLabel", "MovesLabel",
      }) do
        pcall(deleteLabel, legacy_name)
      end
    end
    delete_existing_widget(HitpointsLabel)
    delete_existing_widget(ManaLabel)
    delete_existing_widget(XpLabel)
    delete_existing_widget(MovesLabel)
    delete_existing_widget(DD_GUI.Hitpoints)
    delete_existing_widget(DD_GUI.Mana)
    delete_existing_widget(DD_GUI.Xp)
    delete_existing_widget(DD_GUI.Moves)
    delete_existing_widget(DD_GUI.FirstColumn)
    delete_existing_widget(DD_GUI.SecondColumn)
    delete_existing_widget(DD_GUI.ThirdColumn)
    delete_existing_widget(DD_GUI.FourthColumn)

    DD_GUI.GaugesBox = DD_GUI.Bottom
    DD_GUI.Footer = DD_GUI.Bottom

    local function new_gauge_column(constraints)
      local column = DD_GUI.new_adjustable_container and
        DD_GUI.new_adjustable_container(constraints, DD_GUI.Bottom, {direct = true})
      return column or Geyser.Container:new(constraints, DD_GUI.Bottom)
    end

    DD_GUI.FirstColumn = new_gauge_column({
      name = "DD_GUI.FirstColumn",
      x = "5.56%", y = "0%",
      width = "23.36%", height = "100%",
      padding = 0,
    })

    DD_GUI.SecondColumn = new_gauge_column({
      name = "DD_GUI.SecondColumn",
      x = "28.92%", y = "0%",
      width = "23.36%", height = "100%",
      padding = 0,
    })

    DD_GUI.ThirdColumn = new_gauge_column({
      name = "DD_GUI.ThirdColumn",
      x = "52.28%", y = "0%",
      width = "23.36%", height = "100%",
      padding = 0,
    })

    DD_GUI.FourthColumn = new_gauge_column({
      name = "DD_GUI.FourthColumn",
      x = "75.64%", y = "0%",
      width = "23.36%", height = "100%",
      padding = 0,
    })

    local colors = DD_GUI.Theme and DD_GUI.Theme.colors or {
      hp = "rgb(181,42,48)",
      mana = "rgb(46,92,184)",
      xp = "rgb(188,145,43)",
      moves = "rgb(38,139,126)",
    }

    DD_GUI.Hitpoints, HitpointsLabel = new_status_gauge(
      "DD_GUI.Hitpoints", DD_GUI.FirstColumn, "HITS", colors.hp,
      gmcp.Char.Vitals.hp, gmcp.Char.Vitals.maxhp)

    DD_GUI.Mana, ManaLabel = new_status_gauge(
      "DD_GUI.Mana", DD_GUI.SecondColumn, "MANA", colors.mana,
      gmcp.Char.Vitals.mana, gmcp.Char.Vitals.maxmana)

    local xplvl = tonumber(gmcp.Char.Worth.xplvl) or 0
    local xptnl = tonumber(gmcp.Char.Worth.xptnl) or 0
    local xp_value = xptnl > 0 and math.max(0, xplvl - xptnl) or 1
    local xp_maximum = xptnl > 0 and xplvl or 1
    DD_GUI.Xp, XpLabel = new_status_gauge(
      "DD_GUI.Xp", DD_GUI.ThirdColumn, "XP", colors.xp,
      xp_value, xp_maximum)

    DD_GUI.Moves, MovesLabel = new_status_gauge(
      "DD_GUI.Moves", DD_GUI.FourthColumn, "MOVES", colors.moves,
      gmcp.Char.Vitals.move, gmcp.Char.Vitals.maxmove)
end
