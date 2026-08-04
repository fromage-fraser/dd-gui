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

-- This is the order used by DD4's equipment command.
local paper_doll_slots = {
  { key = "float", column = 17 },
  { key = "head", column = 6 },
  { key = "neck_1", column = 4 },
  { key = "neck_2", column = 4 },
  { key = "arms", column = 10 },
  { key = "wrist_l", column = 14 },
  { key = "wrist_r", column = 14 },
  { key = "hands", column = 9 },
  { key = "finger_l", column = 3 },
  { key = "finger_r", column = 3 },
  { key = "body", column = 5 },
  { key = "about", column = 12 },
  { key = "waist", column = 13 },
  { key = "pouch", column = 18 },
  { key = "legs", column = 7 },
  { key = "feet", column = 8 },
  { key = "light", column = 1 },
  { key = "hold", column = 16 },
  { key = "shield", column = 11 },
  { key = "wield", column = 15 },
  { key = "dual", column = 15 },
  { key = "ranged_weapon", column = 19 },
}

local wear_loc_slots = {
  [0] = "light",
  [1] = "finger_l",
  [2] = "finger_r",
  [3] = "neck_1",
  [4] = "neck_2",
  [5] = "body",
  [6] = "head",
  [7] = "legs",
  [8] = "feet",
  [9] = "hands",
  [10] = "arms",
  [11] = "shield",
  [12] = "about",
  [13] = "waist",
  [14] = "wrist_l",
  [15] = "wrist_r",
  [16] = "wield",
  [17] = "hold",
  [18] = "dual",
  [19] = "float",
  [20] = "pouch",
  [21] = "ranged_weapon",
}

-- Columns match DD4's form_wear_table:
-- light, take, finger, neck, body, head, legs, feet, hands, arms,
-- shield, about, waist, wrist, wield, held, float, pouch, ranged.
local form_wear_table = {
  normal = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
  chameleon = { 1, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1, 0 },
  hawk = { 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 1, 1, 0 },
  cat = { 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0 },
  snake = { 1, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0 },
  scorpion = { 1, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0 },
  spider = { 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0 },
  bear = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
  tiger = { 1, 1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0 },
  ghost = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0 },
  hydra = { 1, 1, 0, 1, 0, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 1, 1, 1, 0 },
  phoenix = { 1, 1, 1, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 1, 0, 1, 1, 1, 0 },
  demon = { 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0 },
  dragon = { 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1, 0, 1, 1, 1, 0 },
  direwolf = { 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0 },
  vampire = { 0, 1, 1, 1, 0, 0, 1, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 0 },
  werehuman = { 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0 },
  fly = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
  griffin = { 1, 1, 1, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0 },
  wolf = { 1, 1, 0, 1, 1, 0, 1, 0, 0, 1, 0, 1, 1, 1, 0, 1, 1, 1, 0 },
  bat = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
}

-- Only the non-default location restrictions are listed here. The source
-- table uses the effective subclass row whenever a subclass is present.
local class_slot_restrictions = {
  mage = { hands = true, shield = true },
  thief = { shield = true },
  psionic = { head = true },
  psionicist = { head = true },
  brawler = { shield = true, wield = true, dual = true },
}

local subclass_slot_restrictions = {
  necromancer = { shield = true },
  ninja = { shield = true },
  witch = { body = true },
  vampire = { light = true },
  monk = { shield = true, wield = true, dual = true },
  martialartist = { shield = true, wield = true, dual = true },
  martist = { shield = true, wield = true, dual = true },
  bard = { shield = true },
}

-- The server exposes the equipment slot but not learned[] for the dual skill.
-- These are the professions with a DD4 dual skill prerequisite.
local dual_professions = {
  thief = true,
  warrior = true,
  ranger = true,
  bounty = true,
  bountyhunter = true,
  knight = true,
  ninja = true,
  templar = true,
  warlock = true,
  vampire = true,
  werewolf = true,
  barbarian = true,
  bard = true,
  bhunter = true,
}

local form_number_names = {
  [0] = "normal",
  [1] = "chameleon",
  [2] = "hawk",
  [3] = "cat",
  [4] = "snake",
  [5] = "scorpion",
  [6] = "spider",
  [7] = "bear",
  [8] = "tiger",
  [9] = "ghost",
  [10] = "hydra",
  [11] = "phoenix",
  [12] = "demon",
  [13] = "dragon",
  [14] = "direwolf",
  [15] = "none",
  [16] = "werehuman",
  [17] = "fly",
  [18] = "griffin",
  [19] = "wolf",
  [20] = "bat",
}

local function normalize_key(value)
  local key = string.lower(tostring(value or ""))
  key = string.gsub(key, "[^%a%d]", "")
  return key
end

local function character_wear_context()
  local base = {}
  local vitals = {}

  if gmcp and gmcp.Char then
    if type(gmcp.Char.Base) == "table" then
      base = gmcp.Char.Base
    end

    if type(gmcp.Char.Vitals) == "table" then
      vitals = gmcp.Char.Vitals
    end
  end

  local subclass = normalize_key(base.subclass)
  if subclass == "none" then
    subclass = ""
  end

  local form_number = tonumber(vitals.form)
  local form = form_number_names[form_number]
  if not form then
    form = normalize_key(vitals.form)
  end

  if form == "" or form == "none" then
    form = "normal"
  end

  return {
    class = normalize_key(base.class),
    subclass = subclass,
    form = form,
  }
end

local function item_slot_key(item)
  local raw_slot = item.slot
  local numeric_slot = tonumber(raw_slot)

  if numeric_slot ~= nil and wear_loc_slots[numeric_slot] then
    return wear_loc_slots[numeric_slot]
  end

  if raw_slot == nil then
    local wear_loc = tonumber(item.wear_loc)
    if wear_loc ~= nil and wear_loc_slots[wear_loc] then
      return wear_loc_slots[wear_loc]
    end
  end

  local normalized = normalize_key(raw_slot)
  local aliases = {
    fingerl = "finger_l",
    fingerr = "finger_r",
    neck1 = "neck_1",
    neck2 = "neck_2",
    wristl = "wrist_l",
    wristr = "wrist_r",
    dualwield = "dual",
    held = "hold",
    ranged = "ranged_weapon",
    rangedweapon = "ranged_weapon",
  }

  return aliases[normalized] or normalized
end

local function worn_entries()
  if not gmcp or not gmcp.Char or type(gmcp.Char.Worn) ~= "table" then
    return {}
  end

  local worn = gmcp.Char.Worn
  local first = worn[1]
  if type(first) == "table" and first.slot == nil and first.wear_loc == nil then
    return first
  end

  return worn
end

local function worn_by_slot(entries)
  local equipped = {}

  for _, item in ipairs(entries) do
    if type(item) == "table" then
      local slot = item_slot_key(item)
      if slot ~= "" then
        equipped[slot] = item
      end
    end
  end

  return equipped
end

local function slot_is_allowed(slot, context)
  if slot.key == "ranged_weapon" then
    return context.subclass == "knight"
        or (context.class == "ranger" and context.subclass == "")
  end

  local form_row = form_wear_table[context.form] or form_wear_table.normal
  if form_row[slot.column] ~= 1 then
    return false
  end

  local restrictions
  if context.subclass ~= "" then
    restrictions = subclass_slot_restrictions[context.subclass]
  else
    restrictions = class_slot_restrictions[context.class]
  end

  if restrictions and restrictions[slot.key] then
    return false
  end

  if slot.key == "dual" then
    local profession = context.subclass
    if profession == "" then
      profession = context.class
    end

    if not dual_professions[profession] then
      return false
    end
  end

  return true
end

local function compact_equipped_name(value)
  local name = tostring(value or "")
  if type(ansi2string) == "function" then
    name = ansi2string(name)
  end

  name = string.gsub(name, "\27%[[0-9;]*m", "")
  name = string.gsub(name, "%b()", "")
  name = string.gsub(name, "%b[]", "")
  name = string.gsub(name, "^%s+", "")
  name = string.gsub(name, "%s+$", "")
  return name
end

local function format_equipped_name(name, width)
  return string.format("%-" .. width .. "s", name)
end

local function equipped_signature(entries, context)
  local parts = { context.class, context.subclass, context.form }

  for _, item in ipairs(entries) do
    if type(item) == "table" then
      table.insert(parts, item_slot_key(item) .. "=" .. tostring(item.name or item.short_desc or ""))
    end
  end

  return table.concat(parts, "|")
end

local last_rendered_console
local last_equipped_signature

function update_equipped()
  if not EquippedConsole then
    return
  end

  local entries = worn_entries()
  local context = character_wear_context()
  local signature = equipped_signature(entries, context)

  if last_rendered_console == EquippedConsole
      and last_equipped_signature == signature then
    return
  end

  last_rendered_console = EquippedConsole
  last_equipped_signature = signature

  EquippedConsole:clear()
  EquippedConsole:disableAutoWrap()
  EquippedConsole:setWrap(10000)
  EquippedConsole:disableHorizontalScrollBar()

  local equipped = worn_by_slot(entries)
  for _, slot in ipairs(paper_doll_slots) do
    local label = equipped_slot_labels[slot.key] or slot.key
    EquippedConsole:cecho("<white>" .. string.format("%-15s", label) .. "<reset>")

    local item = equipped[slot.key]
    if item then
      local name = compact_equipped_name(item.name or item.short_desc)
      EquippedConsole:decho(format_equipped_name(name, 27) .. "\n")
    elseif slot_is_allowed(slot, context) then
      EquippedConsole:cecho("<yellow>[empty]<reset>\n")
    else
      EquippedConsole:cecho("<red>[prohibited]<reset>\n")
    end
  end
end
