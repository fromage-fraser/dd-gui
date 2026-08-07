function DD_GUI.set_enemy_panel_border(border)
  if not border then
    return
  end

  DD_GUI.enemy_panel_border = border
  if DD_GUI.FrameGrid and DD_GUI.FrameGrid.set_region_color then
    DD_GUI.FrameGrid:set_region_color("EnemyBox", border)
  elseif DD_GUI.EnemyBox and DD_GUI.panel_surface_css then
    DD_GUI.EnemyBox:setStyleSheet(DD_GUI.panel_surface_css())
  end
end

local function enemy_hitpoint_widgets()
  return {
    EnemyConsoleHitpointsContainer,
    EnemyConsoleHitpoints,
    EnemyHitpointsLabel,
  }
end

function DD_GUI.set_enemy_hitpoints_visible(visible)
  for _, widget in ipairs(enemy_hitpoint_widgets()) do
    if widget then
      if visible and widget.show then
        pcall(function() widget:show() end)
      elseif not visible and widget.hide then
        pcall(function() widget:hide() end)
      end
    end
  end
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
  local black = "rgb(0,0,0)"
  local ember = blend_rgb(black, regular, 0.18)
  local glow = blend_rgb(black, regular, 0.38)
  local dim = blend_rgb(black, regular, 0.62)
  local base = blend_rgb(black, regular, 0.82)
  local low = blend_rgb(regular, middle, 0.25)
  local soft = blend_rgb(regular, middle, 0.5)
  local high = blend_rgb(middle, bright, 0.5)
  local very_high = blend_rgb(bright, colors.white or "rgb(255,255,255)", 0.08)
  local peak = blend_rgb(
    bright,
    colors.white or "rgb(255,255,255)",
    0.18
  )
  local pulse_stages = {
    {color = black, duration = 0.26},
    {color = ember, duration = 0.12},
    {color = glow, duration = 0.14},
    {color = dim, duration = 0.16},
    {color = base, duration = 0.16},
    {color = low, duration = 0.16},
    {color = soft, duration = 0.16},
    {color = middle, duration = 0.18},
    {color = high, duration = 0.18},
    {color = very_high, duration = 0.16},
    {color = peak, duration = 0.22},
    {color = very_high, duration = 0.16},
    {color = high, duration = 0.18},
    {color = middle, duration = 0.18},
    {color = soft, duration = 0.16},
    {color = low, duration = 0.16},
    {color = base, duration = 0.16},
    {color = dim, duration = 0.16},
    {color = glow, duration = 0.14},
    {color = ember, duration = 0.12},
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

local function first_enemy_for_transition(enemies)
  if type(enemies) ~= "table" or type(enemies[1]) ~= "table" then
    return nil
  end

  if enemies[1].name ~= nil or enemies[1].hp ~= nil or
     enemies[1].maxhp ~= nil then
    return enemies[1]
  end

  if type(enemies[1][1]) == "table" then
    return enemies[1][1]
  end

  return nil
end

function DD_GUI.maybe_start_enemy_defeat_transition()
  local room = gmcp and gmcp.Room and gmcp.Room.Info
  local same_room = DD_GUI.enemy_panel_same_room and
    DD_GUI.enemy_panel_same_room(room)

  if DD_GUI.enemy_defeat_active then
    if DD_GUI.enemy_defeat_phase == "fade_in" then
      return false
    end
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
    local enemies = gmcp and gmcp.Char and gmcp.Char.Enemies
    local enemy = first_enemy_for_transition(enemies)
    local position = gmcp and gmcp.Char and gmcp.Char.Vitals and
      tonumber(gmcp.Char.Vitals.position)

    if type(enemy) == "table" and position == 6 and
       type(update_enemy) == "function" then
      pcall(update_enemy)
    elseif type(update_travel) == "function" then
      pcall(update_travel)
    end
  end) == true
end

local function enemy_fade_css(alpha)
  return string.format([[
    background-color: rgba(0,0,0,%d);
    border: 0px;
    border-radius: 0px;
    margin: 0px;
  ]], math.max(0, math.min(255, tonumber(alpha) or 0)))
end

local function set_enemy_fade_alpha(alpha)
  DD_GUI.enemy_defeat_alpha = math.max(0, math.min(255, tonumber(alpha) or 0))
  if EnemyFadeLayer and EnemyFadeLayer.setStyleSheet then
    EnemyFadeLayer:setStyleSheet(enemy_fade_css(DD_GUI.enemy_defeat_alpha))
  end
end

function DD_GUI.cancel_enemy_defeat_transition()
  DD_GUI.enemy_defeat_token = (DD_GUI.enemy_defeat_token or 0) + 1
  DD_GUI.enemy_defeat_active = false
  DD_GUI.enemy_defeat_phase = nil
  set_enemy_fade_alpha(0)
  if EnemyFadeLayer and EnemyFadeLayer.hide then
    EnemyFadeLayer:hide()
  end
end

function DD_GUI.start_enemy_defeat_transition(on_complete)
  if DD_GUI.enemy_defeat_active then
    return true
  end

  if not EnemyFadeLayer or not Geyser or not Geyser.Label then
    if type(on_complete) == "function" then
      on_complete()
    end
    return false
  end

  DD_GUI.enemy_defeat_active = true
  DD_GUI.enemy_defeat_phase = "fade_out"
  DD_GUI.enemy_defeat_token = (DD_GUI.enemy_defeat_token or 0) + 1
  local token = DD_GUI.enemy_defeat_token
  local layer = EnemyFadeLayer
  local frame_count = 15
  local frame_delay = 0.06

  DD_GUI.cancel_enemy_panel_flash()
  if DD_GUI.cancel_enemy_combat_pulse then
    DD_GUI.cancel_enemy_combat_pulse()
  end
  DD_GUI.set_enemy_panel_border(
    DD_GUI.Theme and DD_GUI.Theme.colors.bright_frame or
      "rgb(205,48,60)"
  )
  set_enemy_fade_alpha(0)
  layer:show()
  if layer.raise then
    layer:raise()
  end

  if not tempTimer then
    set_enemy_fade_alpha(255)
    DD_GUI.enemy_defeat_active = false
    DD_GUI.enemy_defeat_phase = "replacement"
    if type(on_complete) == "function" then
      pcall(on_complete)
    end
    DD_GUI.enemy_defeat_active = false
    DD_GUI.enemy_defeat_phase = nil
    set_enemy_fade_alpha(0)
    layer:hide()
    return true
  end

  local frame = 0

  local function fade_in_replacement()
    if DD_GUI.enemy_defeat_token ~= token then
      return
    end

    frame = frame + 1
    local progress = math.min(1, frame / frame_count)
    set_enemy_fade_alpha(math.floor(255 * (1 - progress) + 0.5))

    if progress >= 1 then
      DD_GUI.enemy_defeat_active = false
      DD_GUI.enemy_defeat_phase = nil
      set_enemy_fade_alpha(0)
      layer:hide()
    else
      tempTimer(frame_delay, fade_in_replacement)
    end
  end

  local function replace_under_black()
    if DD_GUI.enemy_defeat_token ~= token then
      return
    end

    DD_GUI.enemy_defeat_active = false
    DD_GUI.enemy_defeat_phase = "replacement"
    DD_GUI.enemy_panel_mode = "travel"
    if type(on_complete) == "function" then
      pcall(on_complete)
    end

    if DD_GUI.enemy_defeat_token ~= token then
      return
    end

    DD_GUI.enemy_defeat_active = true
    DD_GUI.enemy_defeat_phase = "fade_in"
    frame = 0
    if layer.raise then
      layer:raise()
    end
    fade_in_replacement()
  end

  local function fade_out_enemy()
    if DD_GUI.enemy_defeat_token ~= token then
      return
    end

    frame = frame + 1
    local progress = math.min(1, frame / frame_count)
    set_enemy_fade_alpha(math.floor(255 * progress + 0.5))

    if progress >= 1 then
      replace_under_black()
    else
      tempTimer(frame_delay, fade_out_enemy)
    end
  end

  fade_out_enemy()
  return true
end

function build_enemy_console()
  if DD_GUI.cancel_enemy_defeat_transition then
    DD_GUI.cancel_enemy_defeat_transition()
  end
  if DD_GUI.cancel_enemy_combat_pulse then
    DD_GUI.cancel_enemy_combat_pulse()
  end
  if type(deleteLabel) == "function" then
    -- A package rebuild can leave named sibling labels alive after their Lua
    -- references are replaced. Remove the old combat gauge before creating
    -- its replacement so travel mode cannot reveal a stale HITS bar.
    for _, name in ipairs({
      "EnemyConsoleHitpointsContainer",
      "EnemyConsoleHitpoints",
      "EnemyHitpointsLabel",
    }) do
      pcall(deleteLabel, name)
    end
  end
  for _, layer in ipairs({EnemyFadeLayer, EnemyShatterLayer}) do
    if layer and layer.delete then
      pcall(function() layer:delete() end)
    end
  end
  EnemyFadeLayer = nil
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
      -- The track starts at 4% and is 92% wide. Resize the fill against
      -- that track rather than the whole panel, or a full bar overruns the
      -- image/info frame by the track's right inset.
      self:resize(string.format("%.3f%%", ratio * 92), "10%")
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
    -- so the fade overlay stays deterministic while the image underneath
    -- is replaced.
    EnemyFadeLayer = Geyser.Label:new({
      name = "DD_GUI.EnemyFadeLayer",
      x = "4%",
      y = "6%",
      width = "92%",
      height = "63%",
    }, DD_GUI.EnemyBox)
    set_enemy_fade_alpha(0)
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(EnemyFadeLayer, true)
    end
    EnemyFadeLayer:hide()
    DD_GUI.set_enemy_hitpoints_visible(false)

  end
