debug.setmetatable(nil, { __index=function () end })

function update_inventory()
  local quantity_ordered = {}
  
  for key, value in orderedPairs(gmcp.Char.Items[1]) do
    quantity_ordered[key] = value.quan
  end
  
  --display(dump(quantity_ordered))
  local sorted_quan_keys = getKeysSortedByValue(quantity_ordered, function(a, b) return tonumber(a) > tonumber(b) end)
  --display(dump(sorted_quan_keys))
  
  InventoryConsole:clear()
  InventoryConsole:resetAutoWrap ()
  
  for i, count in ipairs(sorted_quan_keys) do
    --local has_mod = 0
    if (gmcp.Char.Items[1][count].quan) ~= nil then
      local desc_string = gmcp.Char.Items[1][count].short_desc
      --display(desc_string)
      desc_string = ansi2string(desc_string)
      --display(desc_string)
      desc_string = string.gsub(desc_string, "%b()", "")
      desc_string = string.gsub(desc_string, "^%s+", "")
      --display(desc_string)
      InventoryConsole:cecho("<white>" ..string.format("(%3d)", gmcp.Char.Items[1][count].quan).. "<reset> ")
      if (#desc_string) > 34 then
        local tmp_string = replace_char(28, desc_string, '.')
        local tmp_string = replace_char(27, tmp_string, '.')
        InventoryConsole:echo(string.format("%.28s", tmp_string) .."\n")
      else
        InventoryConsole:echo(string.format("%-28s", desc_string).."\n")
      end
    end
    
  end
end