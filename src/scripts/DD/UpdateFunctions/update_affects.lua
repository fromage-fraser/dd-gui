debug.setmetatable(nil, { __index=function () end })

function update_affects()
  local duration_ordered = {}
  for key, value in orderedPairs(gmcp.Char.Affect[1]) do
    duration_ordered[key] = value.duration
  end
  
  --display(dump(duration_ordered))
  local sorted_dur_keys = getKeysSortedByValue(duration_ordered, function(a, b) return tonumber(a) < tonumber(b) end)
  --display(dump(sorted_dur_keys))
  
  AffectsConsole:clear()
  AffectsConsole:resetAutoWrap ()
  
  for i, count in ipairs(sorted_dur_keys) do
    local has_mod = 0
    --display(name)
    if (gmcp.Char.Affect[1][count].name) ~= nil then
      if (#gmcp.Char.Affect[1][count].name) > 18 then
        local tmp_string = replace_char(18, gmcp.Char.Affect[1][count].name, '.')
        local tmp_string = replace_char(17, tmp_string, '.')
        AffectsConsole:cecho("<white>"..string.format("%.18s",tmp_string).."<reset>")
      else
        AffectsConsole:cecho("<white>"..string.format("%-18s", gmcp.Char.Affect[1][count].name).."<reset>")
      end
    end
    --[[if gmcp.Char.Affect[1][count].gives ~= nil then
      if gmcp.Char.Affect[1][count].gives ~= "some unknown effect" then
        AffectsConsole:cecho("gives: <green>"     ..gmcp.Char.Affect[1][count].gives..      "<reset>\n")
      end
    end]]--
    if gmcp.Char.Affect[1][count].modifies ~= nil then
      if gmcp.Char.Affect[1][count].modifies ~= "none" then
        AffectsConsole:cecho("\n<green>"..string.format("%-13s", gmcp.Char.Affect[1][count].modifies).."<reset>")
      end
    end
    if gmcp.Char.Affect[1][count].mod_amount ~= nil then
      if tonumber(gmcp.Char.Affect[1][count].mod_amount) ~= 0 then
        has_mod = 1
        AffectsConsole:cecho("<yellow>"       ..string.format("%11s", gmcp.Char.Affect[1][count].mod_amount).. "<reset>")
      end
    end
    if gmcp.Char.Affect[1][count].duration ~= nil then
      if tonumber(gmcp.Char.Affect[1][count].duration) < 0 then
        AffectsConsole:cecho("<green>" ..string.format("%17s","indefinite").. "<reset>\n")
      elseif tonumber(gmcp.Char.Affect[1][count].duration) == 0 and has_mod == 1 then
        AffectsConsole:cecho("<green>" ..string.format("%13s","< 1").. "<reset>\n")
        has_mod = 0
      elseif tonumber(gmcp.Char.Affect[1][count].duration) == 0 and has_mod == 0 then
        AffectsConsole:cecho("<green>" ..string.format("%17s","< 1").. "<reset>\n")
      elseif has_mod == 1 then
        AffectsConsole:cecho("<green>"  ..string.format("%9s",gmcp.Char.Affect[1][count].duration)..   "<reset> hrs\n")
        has_mod = 0
      else
        AffectsConsole:cecho("<green>"  ..string.format("%15s",gmcp.Char.Affect[1][count].duration)..   "<reset> hrs\n")
      end
    end
  end
end