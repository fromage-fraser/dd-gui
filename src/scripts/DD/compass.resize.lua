function build_compass() 

local mw, mh = getMainWindowSize()
 
  compass = {
    dirs = {"n","u","w","look","e","s","d"},
    ratio = mw / mh
  }
  
  compass.back = Geyser.Label:new({
    name = "compass.back",
    x = "60%",
    y = "82%",
    width = "8%",
    height = "8%",
  },main)
  
  compass.back:setStyleSheet([[
    background-color: QRadialGradient(cx:.3,cy:1,radius:1,stop:0 rgb(28,0,0),stop:.5 rgb(100,0,0),stop:1 rgb(255,0,0));
    border-radius: ]]..tostring(compass.back:get_width()/2-36)..[[px;
    margin: 12px;
  ]])
  
  compass.box = Geyser.HBox:new({
    name = "compass.box",
    x = 0,
    y = 0,
    width = "100%",
    height = "100%",
  },compass.back)
    
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

function compass.resize()
  compass.back:resize(compass.back.width, compass.back:get_width())
end

compass.resize()
end