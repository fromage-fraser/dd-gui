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
elseif target == "cleanup" then
  if DD_GUI and DD_GUI.remove_conflicting_generic_mapper then
    local removed = DD_GUI.remove_conflicting_generic_mapper(true)
    if removed then
      cecho("<yellow>Removed generic_mapper. Restart Mudlet before reconnecting if its map load was freezing this profile.<reset>\n")
    else
      cecho("<white>The conflicting generic_mapper package is not installed, or could not be removed.<reset>\n")
    end
  else
    cecho("<red>DD_GUI mapper cleanup is unavailable until bootstrap completes.<reset>\n")
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
elseif target == "reset" then
  if DD_GUI and DD_GUI.mapper_confirm_pending_area_reset then
    DD_GUI.mapper_confirm_pending_area_reset()
  else
    cecho("<red>No mapper area reset is waiting for confirmation.<reset>\n")
  end
elseif target == "cancel" then
  if DD_GUI and DD_GUI.mapper_cancel_area_reset then
    DD_GUI.mapper_cancel_area_reset()
  end
else
  cecho("<red>Do not understand mapper option \"" .. target .. "\"<reset>\n")
end
