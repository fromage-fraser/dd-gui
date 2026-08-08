local function clean_quest_text(value)
  local text = tostring(value or "")
  if type(ansi2string) == "function" then
    local ok, plain = pcall(ansi2string, text)
    if ok and plain then
      text = plain
    end
  end

  text = string.gsub(text, "\27%[[0-9;]*m", "")
  text = string.gsub(text, "{%a", "")
  text = string.gsub(text, "<[^>]+>", "")
  text = string.gsub(text, "[\r\n]+", " ")
  text = string.gsub(text, "%s+", " ")
  text = string.gsub(text, "^%s+", "")
  text = string.gsub(text, "%s+$", "")
  return text
end

local function quest_number(value)
  local number = tonumber(value)
  if not number then
    return 0
  end
  return math.floor(number)
end

local function quest_flag(value)
  return value == true or tostring(value or "") == "1" or
         string.lower(tostring(value or "")) == "true"
end

local function quest_data()
  local char = gmcp and gmcp.Char
  local quest = char and char.Quest
  if type(quest) ~= "table" then
    return nil
  end

  if quest.status == nil and type(quest[1]) == "table" then
    quest = quest[1]
  end
  return quest
end

local function format_minutes(value)
  local minutes = math.max(0, quest_number(value))
  if minutes == 1 then
    return "1 minute"
  end
  return tostring(minutes) .. " minutes"
end

local function named_reference(name, vnum, fallback)
  local text = clean_quest_text(name)
  local number = quest_number(vnum)
  if text == "" then
    text = fallback or "Unknown"
  end
  if number > 0 then
    text = text .. " [#" .. tostring(number) .. "]"
  end
  return text
end

local function emit_quest_row(label, value, colour)
  local text = clean_quest_text(value)
  if text == "" then
    text = "-"
  end

  QuestStatusConsole:cecho(
    "<white>" .. string.format("%-15s", label) .. "<reset>" ..
    (colour or "<white>") .. text .. "<reset>\n"
  )
end

local function resolved_status(quest)
  local status = string.lower(clean_quest_text(quest.status))
  if status == "available" or status == "cooldown" or
     status == "active" or status == "return" then
    return status
  end

  if quest_flag(quest.active) then
    return quest_flag(quest.complete) and "return" or "active"
  end
  if quest_number(quest.nextquest) > 0 then
    return "cooldown"
  end
  return "available"
end

local status_display = {
  available = { text = "Available",       colour = "<green>" },
  cooldown  = { text = "Cooldown",        colour = "<yellow>" },
  active    = { text = "Active",          colour = "<cyan>" },
  ["return"] = { text = "Ready to return", colour = "<green>" },
}

function update_quest_status()
  if not QuestStatusConsole then
    return
  end

  QuestStatusConsole:clear()
  QuestStatusConsole:resetAutoWrap()

  local quest = quest_data()
  if not quest then
    QuestStatusConsole:cecho("<white>Quest data unavailable.<reset>")
    return
  end

  local status = resolved_status(quest)
  local display = status_display[status] or status_display.available
  local active = quest_flag(quest.active)
  local complete = quest_flag(quest.complete)
  local objective_type = string.lower(clean_quest_text(quest.type))

  emit_quest_row("Status", display.text, display.colour)

  if active then
    local objective = "Unknown"
    local target_vnum = 0
    if objective_type == "kill" then
      objective = "Kill target"
      target_vnum = quest_number(quest.mob_vnum)
    elseif objective_type == "retrieve" then
      objective = "Retrieve object"
      target_vnum = quest_number(quest.object_vnum)
    end

    local target_fallback = "Unknown target"
    if objective_type == "kill" and complete then
      target_fallback = "Target defeated"
    end

    emit_quest_row("Objective", objective, "<yellow>")
    emit_quest_row(
      "Target",
      named_reference(quest.target_name, target_vnum, target_fallback),
      "<white>"
    )
    emit_quest_row(
      "Progress",
      complete and "Complete - return to questgiver" or "In progress",
      complete and "<green>" or "<cyan>"
    )
    emit_quest_row(
      "Area",
      clean_quest_text(quest.area_name) ~= "" and quest.area_name or "Unknown",
      "<white>"
    )
    emit_quest_row(
      "Room",
      named_reference(quest.room_name, quest.room_vnum, "Unknown"),
      "<white>"
    )
    emit_quest_row(
      "Questgiver",
      named_reference(quest.giver_name, quest.giver_vnum, "Unknown"),
      "<white>"
    )
    emit_quest_row("Time remaining", format_minutes(quest.countdown), "<yellow>")
  elseif status == "cooldown" then
    QuestStatusConsole:cecho("\n<white>No active autoquest.<reset>\n")
    emit_quest_row("Next quest", format_minutes(quest.nextquest), "<yellow>")
  else
    QuestStatusConsole:cecho("\n<white>No active autoquest.<reset>\n")
    emit_quest_row("Next quest", "Available now", "<green>")
  end

  QuestStatusConsole:decho("\n")
  emit_quest_row("Quest points", quest_number(quest.points), "<yellow>")
  emit_quest_row("Lifetime QP", quest_number(quest.total_points), "<yellow>")

  local required = quest_number(quest.level_qp_required)
  local shortfall = quest_number(quest.level_qp_shortfall)
  if required <= 0 then
    emit_quest_row("Level gate", "No requirement at this level", "<green>")
  elseif shortfall <= 0 then
    emit_quest_row(
      "Level gate",
      tostring(required) .. " required - met",
      "<green>"
    )
  else
    emit_quest_row(
      "Level gate",
      tostring(required) .. " required - " .. tostring(shortfall) .. " remaining",
      "<yellow>"
    )
  end
end
