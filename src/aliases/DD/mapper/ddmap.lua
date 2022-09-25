target = matches[2]

if target == "on" then
  enableScript("GMCPMapper")
  cecho("<white>The Dragons Domain GMCPMapper is ON.<reset>\n")
  load_dd_mapper()
elseif target == "off" then
  disableScript("GMCPMapper")
  cecho("<white>The Dragons Domain GMCPMapper is OFF.<reset>\n")
  killAnonymousEventHandler(mapper_event_1)
  killAnonymousEventHandler(mapper_event_2)
  killAnonymousEventHandler(mapper_event_3)
else
  cecho("<red>Do not understand mapper option \"" .. target .. "\"<reset>\n")
end