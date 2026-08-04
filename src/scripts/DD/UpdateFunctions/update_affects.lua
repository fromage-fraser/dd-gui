debug.setmetatable(nil, { __index=function () end })

local function get_duration_text(value)
  if value == nil then
    return ""
  end

  local duration = tonumber(value)
  if duration and duration < 0 then
    return "indefinite"
  elseif duration and duration == 0 then
    return "< 1"
  end

  return tostring(value) .. " hrs"
end

local function get_console_width()
  local width = tonumber(AffectsConsole:getColumnCount())
  if not width or width < 1 then
    return 60
  end

  return width
end

local function right_align(value, width)
  value = tostring(value or "")
  if #value >= width then
    return value
  end

  return string.rep(" ", width - #value) .. value
end

local function center_align(value, width)
  value = tostring(value or "")
  if #value >= width then
    return value
  end

  local padding = width - #value
  local left_padding = math.floor(padding / 2)
  return string.rep(" ", left_padding) .. value .. string.rep(" ", padding - left_padding)
end

local function emit_name_line(name, duration, width, duration_width)
  name = tostring(name or "")
  duration = tostring(duration or "")

  if duration == "" then
    AffectsConsole:cecho("<white>" .. name .. "<reset>\n")
    return
  end

  local gap = width - #name - duration_width
  if gap < 1 then
    -- Keep long names intact and let the console wrap them before the duration.
    AffectsConsole:cecho("<white>" .. name .. "<reset>\n")
    AffectsConsole:cecho("<green>" .. right_align(duration, duration_width) .. "<reset>\n")
    return
  end

  AffectsConsole:cecho("<white>" .. name .. "<reset>")
  AffectsConsole:decho(string.rep(" ", gap))
  AffectsConsole:cecho("<green>" .. right_align(duration, duration_width) .. "<reset>\n")
end

function update_affects()
  local duration_ordered = {}
  local affects = gmcp.Char.Affect[1]
  for key, value in orderedPairs(affects) do
    duration_ordered[key] = value.duration
  end

  local sorted_dur_keys = getKeysSortedByValue(
    duration_ordered,
    function(a, b) return tonumber(b) < tonumber(a) end
  )

  AffectsConsole:clear()
  AffectsConsole:resetAutoWrap()
  if next(sorted_dur_keys) == nil then
    AffectsConsole:cecho("Nothing.<reset>")
    return
  end

  local rows = {}
  local duration_width = 0
  local modifier_width = 0

  for _, count in ipairs(sorted_dur_keys) do
    local affect = affects[count]
    local modifier = tostring(affect.modifies or "")
    if string.lower(modifier) == "none" then
      modifier = ""
    end

    local amount = ""
    if affect.mod_amount ~= nil and tonumber(affect.mod_amount) ~= 0 then
      amount = tostring(affect.mod_amount)
    end

    local duration = get_duration_text(affect.duration)
    rows[#rows + 1] = {
      name = affect.name or "",
      modifier = modifier,
      amount = amount,
      duration = duration,
      has_detail = modifier ~= "" or amount ~= ""
    }

    duration_width = math.max(duration_width, #duration)
    modifier_width = math.max(modifier_width, #modifier)
  end

  local width = get_console_width()
  duration_width = math.max(1, duration_width)

  -- Reserve the final column for durations, and center amounts in everything
  -- between the left-hand modifier column and that duration column.
  local left_width = math.max(1, modifier_width)
  local available_left = math.max(1, width - duration_width - 3)
  left_width = math.min(left_width, available_left)
  local middle_width = math.max(1, width - left_width - duration_width - 2)

  for _, row in ipairs(rows) do
    if row.has_detail then
      emit_name_line(row.name, "", width, duration_width)

      local modifier_field = string.rep(" ", left_width)
      if row.modifier ~= "" then
        modifier_field = row.modifier
      end

      local amount_field = center_align(row.amount, middle_width)
      AffectsConsole:cecho(
        "<green>" .. modifier_field .. "<reset> " ..
        "<yellow>" .. amount_field .. "<reset> " ..
        "<green>" .. right_align(row.duration, duration_width) .. "<reset>\n"
      )
    else
      emit_name_line(row.name, row.duration, width, duration_width)
    end
  end
end
