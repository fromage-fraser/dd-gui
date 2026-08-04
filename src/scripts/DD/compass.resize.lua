local function compass_surface_css()
  if DD_GUI.Theme then
    return DD_GUI.Theme:panel_css({ margin = 0 })
  end
  return [[
    background-color: rgb(0,0,0);
    border: 2px solid grey;
    border-radius: 0px;
    margin: 0px;
  ]]
end

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
    tostring(previous_geometry.width) == "8%" and
    tostring(previous_geometry.height) == "8%"

  local compass_layout_path = ms_path .. "/layout/compass.back.lua"
  local saved_layout = io.exists and io.exists(compass_layout_path)

  if compass and compass.back and compass.back.delete then
    compass.back:delete()
  end

  compass = {
    dirs = {"n", "u", "w", "look", "e", "s", "d"},
    ratio = mw / mh,
    labels = {
      n = "N",
      u = "UP",
      w = "W",
      look = "LOOK",
      e = "E",
      s = "S",
      d = "DOWN",
    },
  }

  local compass_constraints = {
    name = "compass.back",
    x = "52%",
    y = "70%",
    width = "8%",
    height = "8%",
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
  if tostring(compass.back.x) == "60%" and
     tostring(compass.back.y) == "82%" then
    compass.back:move("52%", "70%")
    compass.back:resize("8%", "8%")
    if compass.back.get_width then
      compass.back:resize("8%", compass.back:get_width())
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
  for _, blank in ipairs({"nw", "sw"}) do
    compass[blank]:setStyleSheet(theme and
      theme:compass_cell_css(false, true) or
      [[background-color: rgb(0,0,0); border: 1px solid grey;]])
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(compass[blank], true)
    end
  end

  function compass.click(name)
    send(name)
  end

  function compass.onEnter(name)
    compass[name]:setStyleSheet(theme and
      theme:compass_cell_css(true, false) or
      [[background-color: white; color: black; border: 1px solid grey;]])
    compass[name]:echo(compass.labels[name], "black", "c")
  end

  function compass.onLeave(name)
    compass[name]:setStyleSheet(theme and
      theme:compass_cell_css(false, false) or
      [[background-color: black; color: white; border: 1px solid grey;]])
    compass[name]:echo(compass.labels[name], "white", "c")
  end

  for _, direction in ipairs(compass.dirs) do
    local cell = compass[direction]
    compass.onLeave(direction)
    if theme then
      theme:style_label(cell, 8, true)
    else
      cell:setFontSize(8)
      cell:setBold(1)
    end
    cell:setClickCallback("compass.click", direction)
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
