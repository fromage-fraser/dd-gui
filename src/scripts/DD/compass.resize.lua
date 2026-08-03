local function compass_background_css(width)
  local radius = math.max(0, (tonumber(width) or 0) / 2 - 36)

  return [[
    background-color: QRadialGradient(cx:.3,cy:1,radius:1,stop:0 rgb(28,0,0),stop:.5 rgb(100,0,0),stop:1 rgb(255,0,0));
    border-radius: ]] .. tostring(radius) .. [[px;
    margin: 12px;
  ]]
end

function dd_gui_compass_handle_click(event)
  if not event or event.button ~= "LeftButton" or
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
  if not compass or not compass.back or not compass.handle_drag then
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
  if not event or event.button ~= "LeftButton" or
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

  -- Vitals can rebuild the compass after the initial bootstrap. Remove the
  -- previous native widget tree so its drag surface cannot remain visible or
  -- steal mouse events from the current handle.
  if compass and compass.back and compass.back.delete then
    compass.back:delete()
  end

  compass = {
    dirs = {"n","u","w","look","e","s","d"},
    ratio = mw / mh
  }

  local compass_constraints = {
    name = "compass.back",
    x = "60%",
    y = "82%",
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

  if compass.back._dd_gui_adjustable and not saved_layout and
     (not previous_geometry or previous_default_size) then
    -- Preserve the old compass' square default while allowing later resizing.
    compass.back:resize(compass.back.width, compass.back:get_width())
  end

  local compass_parent = compass.back
  if compass.back._dd_gui_adjustable then
    -- The adjustable container's native drag label is covered by the
    -- compass contents. Keep a full-width top rail above those contents and
    -- forward its mouse events to the native adjustable handlers.
    local go_inside = compass.back.goInside
    compass.back.goInside = false
    compass.handle = Geyser.Label:new({
      name = "compass.handle",
      x = 0,
      y = 0,
      width = "100%",
      height = 14,
    }, compass.back)
    compass.back.goInside = go_inside
    compass.handle:setStyleSheet([[
      background-color: rgba(0,0,0,0);
      border: 0px;
      margin: 0px;
    ]])
    compass.handle:echo("")
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
    compass_parent = compass.back.Inside
  else
    compass.back:setStyleSheet(compass_background_css(compass.back:get_width()))
  end

  compass.box = Geyser.HBox:new({
    name = "compass.box",
    x = 0,
    y = 0,
    width = "100%",
    height = "100%",
  },compass_parent)

  compass.row1 = Geyser.VBox:new({
    name = "compass.row1",
  },compass.box)
  compass.row2 = Geyser.VBox:new({
    name = "compass.row2",
  },compass.box)
  compass.row3 = Geyser.VBox:new({
    name = "compass.row3",
  },compass.box)

  compass.nw = Geyser.Label:new({
    name = "compass.nw",
  },compass.row1)

  compass.nw:setStyleSheet([[
    background-color: rgba(0,0,0,0%);
  ]])

  compass.w = Geyser.Label:new({
    name = "compass.w",
  },compass.row1)

  compass.sw = Geyser.Label:new({
    name = "compass.sw",
  },compass.row1)

  compass.sw:setStyleSheet([[
    background-color: rgba(0,0,0,0%);
  ]])

  compass.n = Geyser.Label:new({
    name = "compass.n",
  },compass.row2)

  compass.look = Geyser.Label:new({
    name = "compass.look",
  },compass.row2)

  compass.s = Geyser.Label:new({
    name = "compass.s",
  },compass.row2)

  compass.u = Geyser.Label:new({
    name = "compass.u",
  },compass.row3)

  compass.e = Geyser.Label:new({
    name = "compass.e",
  },compass.row3)

  compass.d = Geyser.Label:new({
    name = "compass.d",
  },compass.row3)


function compass.click(name)
  send(name)
end

function compass.onEnter(name)
  compass[name]:setStyleSheet([[
    border-image: url("]]..getMudletHomeDir()..[[/DD_GUI/compass/]]..name..[[hover.png");
    margin: 5px;
  ]])
end

function compass.onLeave(name)
  compass[name]:setStyleSheet([[
    border-image: url("]]..getMudletHomeDir()..[[/DD_GUI/compass/]]..name..[[.png");
    margin: 5px;
  ]])
end

for k,v in pairs(compass.dirs) do
  compass[v]:setStyleSheet([[
    border-image: url("]]..getMudletHomeDir()..[[/DD_GUI/compass/]]..v..[[.png");
    margin: 5px;
  ]])
  compass[v]:setClickCallback("compass.click",v)
  setLabelOnEnter("compass."..v,"compass.onEnter",v)
  setLabelOnLeave("compass."..v,"compass.onLeave",v)
end

function compass.refresh()
  if compass.surface then
    compass.surface:setStyleSheet(compass_background_css(compass.surface:get_width()))
  elseif compass.back and compass.back.setStyleSheet then
    compass.back:setStyleSheet(compass_background_css(compass.back:get_width()))
  end

  -- Keep the navigation cells above the adjustable drag surface.
  if compass.box then
    if compass.box.raiseAll then
      compass.box:raiseAll()
    elseif compass.box.raise then
      compass.box:raise()
    end
  end

  if compass.handle and compass.handle.raise then
    compass.handle:raise()
  end
end

function compass.resize()
  -- The legacy label stays square.  Adjustable users control both dimensions.
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
