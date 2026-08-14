local function gauge_value(value, maximum)
    value = tonumber(value) or 0
    maximum = tonumber(maximum) or 0
    if maximum <= 0 then
      return 0
    end
    return math.max(0, math.min(1000, (value * 1000) / maximum))
end

local function gauge_ratio(value, maximum)
    value = tonumber(value) or 0
    maximum = tonumber(maximum) or 0
    if maximum <= 0 then
      return 0
    end
    return math.max(0, math.min(1, value / maximum))
end

local function gauge_front_css(color, ratio)
    local theme = DD_GUI.Theme
    local fill_color = color
    if theme and theme.gauge_fill_color then
      fill_color = theme:gauge_fill_color(color, ratio)
    end

    if theme and theme.gauge_front_css then
      return theme:gauge_front_css(fill_color)
    end

    return string.format([[
      background-color: %s;
      border: 1px solid black;
      border-radius: 0px;
    ]], fill_color or "grey")
end

local function update_gauge_fill_color(gauge, color, value, maximum)
    if not gauge or not gauge.front then
      return
    end

    local css = gauge_front_css(color, gauge_ratio(value, maximum))
    if gauge._dd_gui_fill_css == css then
      return
    end

    gauge._dd_gui_fill_css = css
    gauge.front:setStyleSheet(css)
end

local STATUS_GAUGE_TOOLTIP_DURATION = 6

local function format_gauge_number(value)
    local number = tonumber(value)
    if number then
      if number == math.floor(number) then
        return string.format("%.0f", number)
      end
      return tostring(number)
    end
    return tostring(value or 0)
end

local function set_status_gauge_tooltip(gauge, label, tooltip_label,
                                        value, maximum)
    if not tooltip_label then
      return
    end

    local tooltip = string.format("%s: %s / %s", tooltip_label,
      format_gauge_number(value), format_gauge_number(maximum))

    if gauge and gauge._dd_gui_tooltip == tooltip and
       (not label or label._dd_gui_tooltip == tooltip) then
      return
    end

    -- Geyser.Gauge puts its tooltip on the full-size text label. Keep the
    -- separate centered label in sync as well so the hint remains available
    -- across Mudlet versions with different click-through behaviour.
    if gauge and type(gauge.setToolTip) == "function" then
      pcall(gauge.setToolTip, gauge, tooltip,
        STATUS_GAUGE_TOOLTIP_DURATION)
      gauge._dd_gui_tooltip = tooltip
    end
    if label and type(label.setToolTip) == "function" then
      pcall(label.setToolTip, label, tooltip,
        STATUS_GAUGE_TOOLTIP_DURATION)
      label._dd_gui_tooltip = tooltip
    end
end

DD_GUI.update_status_gauge_tooltip = set_status_gauge_tooltip

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

local function new_status_gauge(name, parent, label_text, color, value, maximum,
                                constraints, tooltip_label)
    constraints = constraints or {}
    local theme = DD_GUI.Theme
    local gauge = Geyser.Gauge:new({
      name = name,
      -- Keep the coloured row clear of both braid edges. The slight lower
      -- inset compensates for the transparent tile pixels at the frame
      -- edges, so the black breathing room reads evenly above and below.
      x = constraints.x or "2%",
      y = constraints.y or "20%",
      width = constraints.width or "96%",
      height = constraints.height or "70%",
      strict = true,
    }, parent)

    gauge.back:setStyleSheet(theme and theme:gauge_back_css() or [[
      background-color: rgb(0,0,0);
      border: 1px solid grey;
      border-radius: 0px;
    ]])
    local native_set_value = gauge.setValue
    function gauge:setValue(current, limit, ...)
      update_gauge_fill_color(self, color, current, limit)
      return native_set_value(self, current, limit, ...)
    end
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

    set_status_gauge_tooltip(gauge, label, tooltip_label, value, maximum)

    return gauge, label
end

-- Character-panel condition bars share the exact construction and segmented
-- styling used by the footer gauges.
DD_GUI.new_status_gauge = new_status_gauge

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
      width = "23.61%", height = "100%",
      padding = 0,
    })

    DD_GUI.SecondColumn = new_gauge_column({
      name = "DD_GUI.SecondColumn",
      x = "29.17%", y = "0%",
      width = "23.61%", height = "100%",
      padding = 0,
    })

    DD_GUI.ThirdColumn = new_gauge_column({
      name = "DD_GUI.ThirdColumn",
      x = "52.78%", y = "0%",
      width = "23.61%", height = "100%",
      padding = 0,
    })

    DD_GUI.FourthColumn = new_gauge_column({
      name = "DD_GUI.FourthColumn",
      x = "76.39%", y = "0%",
      width = "23.61%", height = "100%",
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
      gmcp.Char.Vitals.hp, gmcp.Char.Vitals.maxhp, nil, "HITS")

    DD_GUI.Mana, ManaLabel = new_status_gauge(
      "DD_GUI.Mana", DD_GUI.SecondColumn, "MANA", colors.mana,
      gmcp.Char.Vitals.mana, gmcp.Char.Vitals.maxmana, nil, "MANA")

    local xplvl = tonumber(gmcp.Char.Worth.xplvl) or 0
    local xptnl = tonumber(gmcp.Char.Worth.xptnl) or 0
    local xp = tonumber(gmcp.Char.Worth.xp) or 0
    local maxxp = tonumber(gmcp.Char.Worth.maxxp) or 0
    local xp_value = xptnl > 0 and math.max(0, xplvl - xptnl) or 1
    local xp_maximum = xptnl > 0 and xplvl or 1
    DD_GUI.Xp, XpLabel = new_status_gauge(
      "DD_GUI.Xp", DD_GUI.ThirdColumn, "XP", colors.xp,
      xp_value, xp_maximum, nil, "XP")
    set_status_gauge_tooltip(DD_GUI.Xp, XpLabel, "XP", xp, maxxp)

    DD_GUI.Moves, MovesLabel = new_status_gauge(
      "DD_GUI.Moves", DD_GUI.FourthColumn, "MOVES", colors.moves,
      gmcp.Char.Vitals.move, gmcp.Char.Vitals.maxmove, nil, "MOVES")
end
