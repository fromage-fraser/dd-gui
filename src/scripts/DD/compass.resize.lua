local function compass_surface_css()
  return [[
    background-color: rgb(0,0,0);
    border: 0px;
    border-radius: 0px;
    margin: 0px;
  ]]
end

local compass_action_commands = {
  nw = "equipment",
  sw = "scan",
}

function dd_gui_compass_handle_click(event)
  if not DD_GUI.Layout or not DD_GUI.Layout.enabled or
     not event or event.button ~= "LeftButton" or
     not compass or not compass.back then
    return
  end

  local mouse_x, mouse_y = getMousePosition()
  compass.handle_drag = {
    mouse_x = mouse_x,
    mouse_y = mouse_y,
    x = compass.back:get_x(),
    y = compass.back:get_y(),
    width = compass.back:get_width(),
    height = compass.back:get_height(),
  }

  if DD_GUI.set_adjustable_drag_outline then
    DD_GUI.set_adjustable_drag_outline(compass.back, true)
  end
  compass.handle:setCursor("ClosedHand")
end

function dd_gui_compass_handle_move(event)
  if not DD_GUI.Layout or not DD_GUI.Layout.enabled or
     not compass or not compass.back or not compass.handle_drag then
    return
  end

  local mouse_x, mouse_y = getMousePosition()
  local drag = compass.handle_drag
  local win_width, win_height = getMainWindowSize()
  local x = math.max(0, math.min(win_width - drag.width,
    drag.x + mouse_x - drag.mouse_x))
  local y = math.max(0, math.min(win_height - drag.height,
    drag.y + mouse_y - drag.mouse_y))

  compass.back:move(
    string.format("%.5f%%", (x / win_width) * 100),
    string.format("%.5f%%", (y / win_height) * 100))
end

function dd_gui_compass_handle_release(event)
  if not DD_GUI.Layout or not DD_GUI.Layout.enabled or
     not event or event.button ~= "LeftButton" or
     not compass or not compass.back then
    return
  end

  compass.handle_drag = nil
  if DD_GUI.set_adjustable_drag_outline then
    DD_GUI.set_adjustable_drag_outline(compass.back, false)
  end
  if compass.handle then
    compass.handle:setCursor("OpenHand")
  end
  if compass.back.save then
    compass.back:save()
  end
end

function build_compass()
  local mw, mh = getMainWindowSize()

  local previous_geometry
  if compass and compass.back and compass.back._dd_gui_adjustable then
    previous_geometry = {
      x = compass.back.x,
      y = compass.back.y,
      width = compass.back.width,
      height = compass.back.height,
    }
  end
  local previous_default_size = previous_geometry and
    (tostring(previous_geometry.width) == "8%" or
      tostring(previous_geometry.width) == "9%") and
    (tostring(previous_geometry.height) == "8%" or
      tostring(previous_geometry.height) == "9%")

  local compass_layout_path = ms_path .. "/layout/compass.back.lua"
  local saved_layout = io.exists and io.exists(compass_layout_path)

  if compass and compass.back and compass.back.delete then
    compass.back:delete()
  end

  compass = {
    buttons = {"nw", "n", "u", "w", "look", "e", "sw", "s", "d"},
    commands = {
      nw = compass_action_commands.nw,
      n = "north",
      u = "up",
      w = "west",
      look = "look",
      e = "east",
      sw = compass_action_commands.sw,
      s = "south",
      d = "down",
    },
    door_directions = {
      n = "n",
      u = "up",
      w = "w",
      e = "e",
      s = "s",
      d = "down",
    },
    ratio = mw / mh,
    labels = {
      nw = "EQ",
      n = "N",
      u = "UP",
      w = "W",
      look = "LOOK",
      e = "E",
      sw = "SCAN",
      s = "S",
      d = "DOWN",
    },
  }

  local compass_constraints = {
    name = "compass.back",
    x = "54%",
    y = "70%",
    width = "11%",
    height = "11%",
    padding = 4,
  }

  if previous_geometry then
    for key, value in pairs(previous_geometry) do
      compass_constraints[key] = value
    end
  end

  compass.back = DD_GUI.new_adjustable_container and
    DD_GUI.new_adjustable_container(compass_constraints, main) or
    Geyser.Label:new(compass_constraints, main)

  -- Migrate the old shipped position after Adjustable.Container has loaded
  -- the profile layout. This keeps the correction one-time and preserves any
  -- position the player has chosen themselves.
  local old_default_position =
    tostring(compass.back.x) == "52%" and
    tostring(compass.back.y) == "70%" and
    tostring(compass.back.width) == "11%" and
    tostring(compass.back.height) == "11%"
  if (tostring(compass.back.x) == "60%" and
      tostring(compass.back.y) == "82%") or old_default_position then
    compass.back:move("54%", "70%")
    compass.back:resize("11%", "11%")
    if compass.back.get_width then
      compass.back:resize("11%", compass.back:get_width())
    end
    if compass.back.save then
      compass.back:save()
    end
  end

  if compass.back._dd_gui_adjustable and previous_default_size then
    compass.back:resize("11%", "11%")
    if compass.back.get_width then
      compass.back:resize("11%", compass.back:get_width())
    end
    if compass.back.save then
      compass.back:save()
    end
  end

  if compass.back._dd_gui_adjustable and not saved_layout and
     (not previous_geometry or previous_default_size) then
    compass.back:resize(compass.back.width, compass.back:get_width())
  end

  local compass_parent = compass.back
  if compass.back._dd_gui_adjustable then
    local go_inside = compass.back.goInside
    compass.back.goInside = false
    compass.handle = Geyser.Label:new({
      name = "compass.handle",
      x = 0,
      y = 0,
      width = "100%",
      height = 16,
    }, compass.back)
    compass.back.goInside = go_inside
    compass.handle:setClickCallback("dd_gui_compass_handle_click")
    compass.handle:setReleaseCallback("dd_gui_compass_handle_release")
    compass.handle:setMoveCallback("dd_gui_compass_handle_move")

    compass.surface = Geyser.Label:new({
      name = "compass.surface",
      x = 0,
      y = 0,
      width = "100%",
      height = "100%",
    }, compass.back.Inside)
    compass.surface:setStyleSheet(compass_surface_css())
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(compass.surface, true)
    end
    compass_parent = compass.back.Inside
  else
    compass.back:setStyleSheet(compass_surface_css())
  end

  compass.box = Geyser.HBox:new({
    name = "compass.box",
    x = "3%",
    y = "3%",
    width = "94%",
    height = "94%",
  }, compass_parent)

  compass.row1 = Geyser.VBox:new({name = "compass.row1"}, compass.box)
  compass.row2 = Geyser.VBox:new({name = "compass.row2"}, compass.box)
  compass.row3 = Geyser.VBox:new({name = "compass.row3"}, compass.box)

  compass.nw = Geyser.Label:new({name = "compass.nw"}, compass.row1)
  compass.w = Geyser.Label:new({name = "compass.w"}, compass.row1)
  compass.sw = Geyser.Label:new({name = "compass.sw"}, compass.row1)
  compass.n = Geyser.Label:new({name = "compass.n"}, compass.row2)
  compass.look = Geyser.Label:new({name = "compass.look"}, compass.row2)
  compass.s = Geyser.Label:new({name = "compass.s"}, compass.row2)
  compass.u = Geyser.Label:new({name = "compass.u"}, compass.row3)
  compass.e = Geyser.Label:new({name = "compass.e"}, compass.row3)
  compass.d = Geyser.Label:new({name = "compass.d"}, compass.row3)

  local theme = DD_GUI.Theme

  function compass.door_status(name)
    local direction = compass.door_directions[name]
    if not direction then
      return nil
    end

    local room_id
    if gmcp and gmcp.Room and type(gmcp.Room.Info) == "table" then
      room_id = tonumber(gmcp.Room.Info.vnum)
    end
    if not room_id and type(map) == "table" and
       type(map.room_info) == "table" then
      room_id = tonumber(map.room_info.vnum)
    end
    if not room_id then
      return nil
    end

    local parsed_status = DD_GUI.exit_status_by_room and
      DD_GUI.exit_status_by_room[room_id]
    if parsed_status and parsed_status[name] ~= nil then
      return tonumber(parsed_status[name]) or 0
    end

    if type(getDoors) ~= "function" then
      return nil
    end

    local ok, doors = pcall(getDoors, room_id)
    if not ok or type(doors) ~= "table" then
      return nil
    end

    local status = doors[direction]
    if status == nil then
      status = doors[compass.commands[name]]
    end
    return tonumber(status)
  end

  function compass.send_movement(name, command)
    local status = compass.door_status(name)
    if status == 4 then
      return
    elseif status == 3 then
      if DD_GUI.note_exit_move then
        DD_GUI.note_exit_move(name)
      end
      sendAll(0.2, "unlock " .. command, "open " .. command, command)
    elseif status == 2 then
      if DD_GUI.note_exit_move then
        DD_GUI.note_exit_move(name)
      end
      sendAll(0.2, "open " .. command, command)
    else
      if DD_GUI.note_exit_move then
        DD_GUI.note_exit_move(name)
      end
      send(command)
    end
  end

  function compass.click(name)
    local command = compass.commands[name]
    if not command then
      return
    end

    if compass.activate then
      compass.activate(name)
    end
    if compass.door_directions[name] then
      compass.send_movement(name, command)
    else
      send(command)
    end
  end

  function compass.onEnter(name)
    compass[name]:setStyleSheet(theme and
      theme:compass_cell_css(true, false) or
      [[background-color: black; color: white; border: 2px solid white;]])
    compass[name]:echo(compass.labels[name], "white", "c")
  end

  function compass.onLeave(name)
    compass[name]:setStyleSheet(theme and
      theme:compass_cell_css(false, false) or
      [[background-color: black; color: white; border: 1px solid grey;]])
    compass[name]:echo(compass.labels[name], "white", "c")
  end

  function compass.activate(name)
    if not compass[name] then
      return
    end

    if compass.highlight_timer then
      killTimer(compass.highlight_timer)
      compass.highlight_timer = nil
    end

    if compass.active_name and compass.active_name ~= name then
      compass.onLeave(compass.active_name)
    end

    compass.active_name = name
    compass.onEnter(name)
    compass.highlight_timer = tempTimer(0.45, function()
      if compass and compass.active_name == name then
        compass.active_name = nil
        compass.onLeave(name)
      end
    end)
  end

  DD_GUI = DD_GUI or {}
  function DD_GUI.compass_press(name)
    if compass and compass.click then
      compass.click(name)
      return
    end

    local command = compass_action_commands[name]
    if command then
      send(command)
    end
  end

  for _, direction in ipairs(compass.buttons) do
    local cell = compass[direction]
    compass.onLeave(direction)
    if theme then
      theme:style_label(cell, 8, true)
    else
      cell:setFontSize(8)
      cell:setBold(1)
    end
    -- Route clicks through the stable public callback. This survives a live
    -- compass rebuild and keeps action cells interactive above frame layers.
    cell:setClickCallback("DD_GUI.compass_press", direction)
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(cell, false)
    end
    setLabelOnEnter("compass." .. direction, "compass.onEnter", direction)
    setLabelOnLeave("compass." .. direction, "compass.onLeave", direction)
  end

  function compass.refresh()
    if compass.surface then
      compass.surface:setStyleSheet(compass_surface_css())
    elseif compass.back and compass.back.setStyleSheet then
      compass.back:setStyleSheet(compass_surface_css())
    end

    if compass.box then
      if compass.box.raiseAll then
        compass.box:raiseAll()
      elseif compass.box.raise then
        compass.box:raise()
      end
    end

    if DD_GUI.Layout then
      DD_GUI.Layout:apply_compass()
    end
  end

  function compass.resize()
    if compass.back and not compass.back._dd_gui_adjustable then
      compass.back:resize(compass.back.width, compass.back:get_width())
    end
    compass.refresh()
  end

  if not DD_GUI.compass_handlers_registered then
    registerAnonymousEventHandler("sysWindowResizeEvent", function()
      if compass and compass.refresh then
        compass.refresh()
      end
    end)
    registerAnonymousEventHandler("AdjustableContainerReposition", function(_, name)
      if name == "compass.back" and compass and compass.refresh then
        compass.refresh()
      end
    end)
    DD_GUI.compass_handlers_registered = true
  end

  compass.resize()
end
