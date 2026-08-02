debug.setmetatable(nil, { __index=function () end })

local function inventory_entries()
  if not gmcp or not gmcp.Char or type(gmcp.Char.Items) ~= "table" then
    return {}
  end

  local items = gmcp.Char.Items
  local first = items[1]
  if type(first) == "table"
      and first.quan == nil
      and first.short_desc == nil
      and first.name == nil then
    return first
  end

  return items
end

local function compact_inventory_name(value)
  local name = ansi2string(tostring(value or ""))
  name = string.gsub(name, "%b()", "")
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%b[]", "")
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%s+$", "")
  return name
end

local function fit_inventory_name(name, width)
  if #name > width then
    name = replace_char(width, name, ".")
    name = replace_char(width - 1, name, ".")
    return string.format("%." .. width .. "s", name)
  end

  return string.format("%-" .. width .. "s", name)
end

function update_inventory()
  if not InventoryConsole then
    return
  end

  local entries = {}
  for _, item in ipairs(inventory_entries()) do
    if type(item) == "table" and item.quan ~= nil then
      table.insert(entries, item)
    end
  end

  table.sort(entries, function(a, b)
    return (tonumber(a.quan) or 0) > (tonumber(b.quan) or 0)
  end)

  InventoryConsole:clear()
  InventoryConsole:resetAutoWrap()

  if #entries == 0 then
    InventoryConsole:cecho("Nothing.<reset>")
    return
  end

  for _, item in ipairs(entries) do
    local quantity = tonumber(item.quan) or 0
    local desc_string = compact_inventory_name(item.short_desc or item.name)

    InventoryConsole:cecho(
      "<white>" .. string.format("(%3d)", quantity) .. "<reset> ")
    InventoryConsole:decho(fit_inventory_name(desc_string, 28) .. "\n")
  end
end
