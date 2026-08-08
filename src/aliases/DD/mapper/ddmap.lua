target = matches[2]
map = map or {}

if target == "on" then
  enableScript("GMCPMapper")
  cecho("<white>The Dragons Domain GMCPMapper is ON.<reset>\n")
  load_dd_mapper()
elseif target == "off" then
  disableScript("GMCPMapper")
  cecho("<white>The Dragons Domain GMCPMapper is OFF.<reset>\n")
  if DD_GUI and DD_GUI.MapperState and DD_GUI.MapperState.route then
    local route = DD_GUI.MapperState.route
    if route.timeout_timer then
      pcall(killTimer, route.timeout_timer)
    end
    DD_GUI.MapperState.route = nil
  end
  if DD_GUI and DD_GUI.MapperState and DD_GUI.MapperState.handlers then
    for _, handler_id in pairs(DD_GUI.MapperState.handlers) do
      if handler_id then
        pcall(killAnonymousEventHandler, handler_id)
      end
    end
    DD_GUI.MapperState.handlers = {}
  end
  if type(removeMapMenu) == "function" then
    pcall(removeMapMenu, "DD_GUI.Mapper")
  end
elseif target == "audit" then
  if DD_GUI and DD_GUI.mapper_audit then
    DD_GUI.mapper_audit()
  else
    cecho("<red>The Dragons Domain mapper is not loaded.<reset>\n")
  end
elseif target == "fit" then
  if DD_GUI and DD_GUI.mapper_fit_area then
    DD_GUI.mapper_fit_area()
  end
elseif target == "safe" then
  map.configs = map.configs or {}
  map.configs.dd_safe_speedwalk = true
  cecho("<white>Mapper speedwalk safety is ON.<reset>\n")
elseif target == "fast" then
  map.configs = map.configs or {}
  map.configs.dd_safe_speedwalk = false
  cecho("<yellow>Mapper speedwalk safety is OFF; routes send without room confirmation.<reset>\n")
else
  cecho("<red>Do not understand mapper option \"" .. target .. "\"<reset>\n")
end
