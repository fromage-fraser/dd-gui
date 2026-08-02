local equipped_slot_labels = {
  light = "Light",
  finger_l = "Finger L",
  finger_r = "Finger R",
  neck_1 = "Neck 1",
  neck_2 = "Neck 2",
  body = "Body",
  head = "Head",
  legs = "Legs",
  feet = "Feet",
  hands = "Hands",
  arms = "Arms",
  shield = "Shield",
  about = "About",
  waist = "Waist",
  wrist_l = "Wrist L",
  wrist_r = "Wrist R",
  wield = "Wield",
  hold = "Held",
  dual = "Dual",
  float = "Float",
  pouch = "Pouch",
  ranged_weapon = "Ranged",
}

local function worn_entries()
  if not gmcp or not gmcp.Char or type(gmcp.Char.Worn) ~= "table" then
    return {}
  end

  local worn = gmcp.Char.Worn
  local first = worn[1]
  if type(first) == "table" and first.slot == nil and first.name == nil then
    return first
  end

  return worn
end

local function compact_equipped_name(value)
  local name = ansi2string(tostring(value or ""))
  name = string.gsub(name, "%b()", "")
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%[.+%]", "")
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%s+$", "")
  return name
end

local function fit_equipped_name(name, width)
  if #name > width then
    name = replace_char(width, name, ".")
    name = replace_char(width - 1, name, ".")
    return string.format("%." .. width .. "s", name)
  end

  return string.format("%-" .. width .. "s", name)
end

local function equipped_slot_label(slot)
  slot = string.lower(tostring(slot or ""))
  if equipped_slot_labels[slot] then
    return equipped_slot_labels[slot]
  end

  slot = string.gsub(slot, "_", " ")
  if slot == "" then
    return "Other"
  end

  return string.upper(string.sub(slot, 1, 1)) .. string.sub(slot, 2)
end

function update_equipped()
  if not EquippedConsole then
    return
  end

  EquippedConsole:clear()
  EquippedConsole:resetAutoWrap()

  local found = false
  for _, item in ipairs(worn_entries()) do
    if type(item) == "table" then
      local name = compact_equipped_name(item.name or item.short_desc)
      if name ~= "" then
        found = true
        local slot = equipped_slot_label(item.slot)
        EquippedConsole:cecho("<white>" .. string.format("%-10s", slot) .. "<reset>")
        EquippedConsole:decho(fit_equipped_name(name, 24) .. "\n")
      end
    end
  end

  if not found then
    EquippedConsole:cecho("Nothing.<reset>")
  end
end
