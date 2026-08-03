local function compass_background_css(width)
  local radius = math.max(0, (tonumber(width) or 0) / 2 - 36)

  return [[
    background-color: QRadialGradient(cx:.3,cy:1,radius:1,stop:0 rgb(28,0,0),stop:.5 rgb(100,0,0),stop:1 rgb(255,0,0));
    border-radius: ]] .. tostring(radius) .. [[px;
    margin: 12px;
  ]]
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
