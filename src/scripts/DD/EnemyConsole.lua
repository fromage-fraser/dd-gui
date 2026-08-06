local function enemy_panel_css(border)
  if DD_GUI.Theme and DD_GUI.Theme.panel_css then
    return DD_GUI.Theme:panel_css({border = border})
  end

  return string.format([[
    background-color: rgba(0,0,0,0);
    border-style: solid;
    border-width: 2px;
    border-color: %s;
    border-radius: 0px;
    margin: 1px;
  ]], border)
end

function DD_GUI.set_enemy_panel_border(border)
  if not DD_GUI.EnemyBox or not border then
    return
  end

  DD_GUI.EnemyBox:setStyleSheet(enemy_panel_css(border))
  DD_GUI.enemy_panel_border = border
end

function DD_GUI.cancel_enemy_panel_flash()
  DD_GUI.enemy_panel_flash_token =
    (DD_GUI.enemy_panel_flash_token or 0) + 1
  DD_GUI.enemy_panel_flash_active = false
end

function DD_GUI.flash_enemy_panel()
  if not tempTimer then
    DD_GUI.enemy_panel_flash_active = false
    DD_GUI.set_enemy_panel_border(
      DD_GUI.Theme and DD_GUI.Theme.colors.frame or "rgb(151,27,39)"
    )
    return
  end

  DD_GUI.cancel_enemy_panel_flash()
  local token = DD_GUI.enemy_panel_flash_token
  local theme = DD_GUI.Theme
  local colors = theme and theme.colors or {}
  local bright = colors.bright_frame or "rgb(205,48,60)"
  local middle = colors.frame_flash or "rgb(181,37,49)"
  local regular = colors.frame or "rgb(151,27,39)"

  DD_GUI.enemy_panel_flash_active = true
  DD_GUI.set_enemy_panel_border(bright)
  tempTimer(0.12, function()
    if DD_GUI.enemy_panel_flash_token == token then
      DD_GUI.set_enemy_panel_border(middle)
    end
  end)
  tempTimer(0.42, function()
    if DD_GUI.enemy_panel_flash_token == token then
      DD_GUI.enemy_panel_flash_active = false
      DD_GUI.set_enemy_panel_border(regular)
    end
  end)
end

function DD_GUI.cancel_enemy_combat_pulse()
  DD_GUI.enemy_combat_pulse_token =
    (DD_GUI.enemy_combat_pulse_token or 0) + 1
  DD_GUI.enemy_combat_pulse_active = false
end

local function rgb_channels(color)
  local red, green, blue = tostring(color):match(
    "^rgb%s*%(%s*(%d+)%s*,%s*(%d+)%s*,%s*(%d+)%s*%)$"
  )
  return tonumber(red), tonumber(green), tonumber(blue)
end

local function blend_rgb(from, to, amount)
  local from_red, from_green, from_blue = rgb_channels(from)
  local to_red, to_green, to_blue = rgb_channels(to)
  if not from_red or not to_red then
    return to
  end

  return string.format(
    "rgb(%d,%d,%d)",
    math.floor(from_red + (to_red - from_red) * amount + 0.5),
    math.floor(from_green + (to_green - from_green) * amount + 0.5),
    math.floor(from_blue + (to_blue - from_blue) * amount + 0.5)
  )
end

function DD_GUI.start_enemy_combat_pulse()
  if DD_GUI.enemy_combat_pulse_active then
    return
  end

  DD_GUI.cancel_enemy_combat_pulse()
  local token = DD_GUI.enemy_combat_pulse_token
  local theme = DD_GUI.Theme
  local colors = theme and theme.colors or {}
  local bright = colors.bright_frame or "rgb(205,48,60)"
  local regular = colors.frame or "rgb(151,27,39)"
  local middle = colors.frame_flash or "rgb(181,37,49)"
  local soft = blend_rgb(regular, middle, 0.5)
  local high = blend_rgb(middle, bright, 0.5)
  local pulse_stages = {
    {color = regular, duration = 0.70},
    {color = soft, duration = 0.20},
    {color = middle, duration = 0.25},
    {color = high, duration = 0.25},
    {color = bright, duration = 0.32},
    {color = high, duration = 0.25},
    {color = middle, duration = 0.25},
    {color = soft, duration = 0.20},
  }

  DD_GUI.enemy_combat_pulse_active = true
  if not tempTimer then
    DD_GUI.set_enemy_panel_border(bright)
    return
  end

  local stage = 1
  local function pulse()
    if DD_GUI.enemy_combat_pulse_token ~= token or
       DD_GUI.enemy_panel_mode ~= "combat" then
      DD_GUI.enemy_combat_pulse_active = false
      return
    end

    local current = pulse_stages[stage]
    DD_GUI.set_enemy_panel_border(current.color)
    stage = stage % #pulse_stages + 1
    tempTimer(current.duration, pulse)
  end

  pulse()
end

function DD_GUI.enemy_panel_room_changed(vnum)
  local current = vnum == nil and "" or tostring(vnum)
  local previous = DD_GUI.enemy_panel_room_vnum
  DD_GUI.enemy_panel_room_vnum = current
  return previous ~= nil and previous ~= "" and
    current ~= "" and previous ~= current
end

function DD_GUI.enemy_panel_same_room(room)
  if type(room) ~= "table" or room.vnum == nil then
    return false
  end

  return DD_GUI.enemy_panel_room_vnum ~= nil and
    tostring(room.vnum) == tostring(DD_GUI.enemy_panel_room_vnum)
end

function DD_GUI.maybe_start_enemy_defeat_transition()
  local room = gmcp and gmcp.Room and gmcp.Room.Info
  local same_room = DD_GUI.enemy_panel_same_room and
    DD_GUI.enemy_panel_same_room(room)

  if DD_GUI.enemy_defeat_active then
    if not same_room and DD_GUI.cancel_enemy_defeat_transition then
      DD_GUI.cancel_enemy_defeat_transition()
      return false
    end
    return true
  end

  if DD_GUI.enemy_panel_mode ~= "combat" or not same_room or
     not DD_GUI.start_enemy_defeat_transition then
    return false
  end

  return DD_GUI.start_enemy_defeat_transition(function()
    if type(update_travel) == "function" then
      pcall(update_travel)
    end
  end) == true
end

local function shatter_css(alpha)
  local theme = DD_GUI.Theme
  local colors = theme and theme.colors or {}
  local edge = colors.bright_frame or "rgb(205,48,60)"

  return string.format([[
    background-color: rgba(151,27,39,%d);
    border-style: solid;
    border-width: 1px;
    border-color: %s;
    border-radius: 0px;
    margin: 0px;
  ]], alpha, edge)
end

local function remove_enemy_shatter_shards()
  for _, shard in ipairs(DD_GUI.EnemyShatterShards or {}) do
    if shard and shard.delete then
      pcall(function() shard:delete() end)
    end
  end
  DD_GUI.EnemyShatterShards = {}
end

function DD_GUI.cancel_enemy_defeat_transition()
  DD_GUI.enemy_defeat_token = (DD_GUI.enemy_defeat_token or 0) + 1
  DD_GUI.enemy_defeat_active = false
  remove_enemy_shatter_shards()
  if EnemyShatterLayer and EnemyShatterLayer.hide then
    EnemyShatterLayer:hide()
  end
end

function DD_GUI.start_enemy_defeat_transition(on_complete)
  if DD_GUI.enemy_defeat_active then
    return true
  end

  if not EnemyShatterLayer or not Geyser or not Geyser.Label then
    if type(on_complete) == "function" then
      on_complete()
    end
    return false
  end

  DD_GUI.enemy_defeat_active = true
  DD_GUI.enemy_defeat_token = (DD_GUI.enemy_defeat_token or 0) + 1
  local token = DD_GUI.enemy_defeat_token
  local layer = EnemyShatterLayer
  local layer_width = math.max(1, tonumber(layer:get_width()) or 0)
  local layer_height = math.max(1, tonumber(layer:get_height()) or 0)
  local columns = 6
  local rows = 4
  local cell_width = layer_width / columns
  local cell_height = layer_height / rows
  local symbols = {"/", "\\", "+", "-", "*"}

  DD_GUI.cancel_enemy_panel_flash()
  if DD_GUI.cancel_enemy_combat_pulse then
    DD_GUI.cancel_enemy_combat_pulse()
  end
  DD_GUI.set_enemy_panel_border(
    DD_GUI.Theme and DD_GUI.Theme.colors.bright_frame or
      "rgb(205,48,60)"
  )
  remove_enemy_shatter_shards()
  layer:show()

  for row = 0, rows - 1 do
    for column = 0, columns - 1 do
      local x = math.floor(column * cell_width + 2)
      local y = math.floor(row * cell_height + 2)
      local width = math.max(8, math.floor(cell_width - 4))
      local height = math.max(8, math.floor(cell_height - 4))
      local shard = Geyser.Label:new({
        name = string.format("DD_GUI.EnemyShatter.%d.%d", row, column),
        x = x,
        y = y,
        width = width,
        height = height,
        color = "black",
      }, layer)
      shard:setStyleSheet(shatter_css(90))
      shard:echo(symbols[(row + column) % #symbols + 1], "white", "cb9")
      if DD_GUI.set_widget_clickthrough then
        DD_GUI.set_widget_clickthrough(shard, true)
      end
      local desired_drift_x = (column - (columns - 1) / 2) * 34 +
        (row % 2 == 0 and -8 or 8)
      local desired_drift_y =
        28 + row * 18 + math.abs(column - (columns - 1) / 2) * 12
      local min_drift_x = 2 - x
      local max_drift_x = layer_width - x - width - 2
      local max_drift_y = layer_height - y - height - 2
      table.insert(DD_GUI.EnemyShatterShards, {
        widget = shard,
        x = x,
        y = y,
        width = width,
        height = height,
        drift_x = math.max(min_drift_x, math.min(max_drift_x, desired_drift_x)),
        drift_y = math.max(0, math.min(max_drift_y, desired_drift_y)),
      })
    end
  end

  layer:raiseAll()
  local frame = 0
  local frame_count = 12

  local function finish()
    if DD_GUI.enemy_defeat_token ~= token then
      return
    end

    DD_GUI.enemy_defeat_active = false
    DD_GUI.enemy_panel_mode = "travel"
    remove_enemy_shatter_shards()
    layer:hide()
    if type(on_complete) == "function" then
      pcall(on_complete)
    end
  end

  local function animate()
    if DD_GUI.enemy_defeat_token ~= token then
      return
    end

    frame = frame + 1
    local progress = math.min(1, frame / frame_count)
    local alpha = math.floor(90 + 130 * progress)
    for _, state in ipairs(DD_GUI.EnemyShatterShards) do
      local shard = state.widget
      local scale = 1 - progress * 0.45
      local width = math.max(3, math.floor(state.width * scale))
      local height = math.max(3, math.floor(state.height * scale))
      local x = state.x + state.drift_x * progress +
        (state.width - width) / 2
      local y = state.y + state.drift_y * progress +
        (state.height - height) / 2

      shard:move(math.floor(x), math.floor(y))
      shard:resize(width, height)
      shard:setStyleSheet(shatter_css(alpha))
    end

    if frame >= frame_count then
      tempTimer(0.08, finish)
    else
      tempTimer(0.07, animate)
    end
  end

  animate()
  return true
end

function build_enemy_console()
  if DD_GUI.cancel_enemy_defeat_transition then
    DD_GUI.cancel_enemy_defeat_transition()
  end
  if DD_GUI.cancel_enemy_combat_pulse then
    DD_GUI.cancel_enemy_combat_pulse()
  end
  if EnemyShatterLayer and EnemyShatterLayer.delete then
    pcall(function() EnemyShatterLayer:delete() end)
  end
  EnemyShatterLayer = nil


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

    -- This must be a sibling of the native MiniConsole rather than its
    -- child. MiniConsole can repaint over child widgets during a refresh,
    -- making the defeat animation appear to skip straight to travel mode.
    EnemyShatterLayer = Geyser.Container:new({
      name = "DD_GUI.EnemyShatterLayer",
      x = "4%",
      y = "6%",
      width = "92%",
      height = "63%",
    }, DD_GUI.EnemyBox)
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(EnemyShatterLayer, true)
    end
    EnemyShatterLayer:hide()

  end
