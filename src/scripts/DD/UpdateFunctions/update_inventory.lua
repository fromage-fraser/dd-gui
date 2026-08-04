debug.setmetatable(nil, { __index=function () end })

local function is_inventory_entry(value)
  return type(value) == "table"
      and value.quan ~= nil
      and (value.short_desc ~= nil or value.name ~= nil)
end

local function collect_inventory_entries(value, entries, visited)
  if type(value) ~= "table" or visited[value] then
    return
  end

  visited[value] = true

  if is_inventory_entry(value) then
    table.insert(entries, value)
    return
  end

  for _, child in pairs(value) do
    collect_inventory_entries(child, entries, visited)
  end
end

local function inventory_entries()
  if not gmcp or not gmcp.Char or type(gmcp.Char.Items) ~= "table" then
    return {}
  end

  local entries = {}
  collect_inventory_entries(gmcp.Char.Items, entries, {})
  return entries
end

local function compact_inventory_name(value)
  local name = tostring(value or "")
  name = string.gsub(name, "\27%[[0-9;]*m", "")
  name = string.gsub(name, "%b()", "")
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%b[]", "")
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%s+$", "")
  return name
end

local function display_stat(value)
  local number = tonumber(value)
  if number then
    return tostring(math.floor(number))
  end

  if value == nil or tostring(value) == "" then
    return "?"
  end

  return tostring(value)
end

local function update_inventory_stats()
  if not InventoryStatsLabel then
    return
  end

  local char = gmcp and gmcp.Char
  local stats = char and char.Stats
  if type(stats) ~= "table" then
    stats = char and char.Items and char.Items.Stats
  end
  if type(stats) ~= "table" then
    InventoryStatsLabel:hide()
    return
  end

  local current_number = stats.carry_num
  local maximum_number = stats.maxcarry_num
  local current_weight = stats.carry_wt
  local maximum_weight = stats.maxcarry_wt

  if current_number == nil and maximum_number == nil and
     current_weight == nil and maximum_weight == nil then
    InventoryStatsLabel:hide()
    return
  end

  local message = string.format(
    "Items: %s / %s<br/>Weight: %s / %s",
    display_stat(current_number),
    display_stat(maximum_number),
    display_stat(current_weight),
    display_stat(maximum_weight)
  )
  InventoryStatsLabel:show()
  InventoryStatsLabel:echo(message, "white", "r9")
  if InventoryStatsLabel.raise then
    InventoryStatsLabel:raise()
  end
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
  update_inventory_stats()

  if #entries == 0 then
    InventoryConsole:cecho("Nothing.<reset>")
    return
  end

  for _, item in ipairs(entries) do
    local quantity = tonumber(item.quan) or 0
    local desc_string = compact_inventory_name(item.short_desc or item.name)

    InventoryConsole:cecho(
      "<white>" .. string.format("(%3d)", quantity) .. "<reset> ")
    InventoryConsole:decho(desc_string .. "\n")
  end
end
