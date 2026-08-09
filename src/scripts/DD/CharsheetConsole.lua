local function condition_gauge_value(value, maximum)
    value = tonumber(value) or 0
    maximum = tonumber(maximum) or 0
    if maximum <= 0 then
      return 0
    end

    return math.max(0, math.min(1000, (value * 1000) / maximum))
end

local function character_condition_gauges_visible()
    local char = gmcp and gmcp.Char
    local base = char and char.Base
    local vitals = char and char.Vitals
    local worth = char and char.Worth
    if type(base) ~= "table" or type(vitals) ~= "table" or
       type(worth) ~= "table" then
      return false
    end

    local level = tonumber(worth.level)
    local subclass = tostring(base.subclass or ""):lower()
    return level ~= nil and level < 100 and subclass ~= "vampire" and
           tonumber(vitals.maxthirst or 0) > 0 and
           tonumber(vitals.maxhunger or 0) > 0
end

local function set_condition_gauges_visible(visible)
    local widgets = {
      DD_GUI.CharsheetConditions,
      DD_GUI.Thirst,
      DD_GUI.Hunger,
      DD_GUI.ThirstLabel,
      DD_GUI.HungerLabel,
    }

    for _, widget in ipairs(widgets) do
      if widget then
        if visible and widget.show then
          widget:show()
        elseif not visible and widget.hide then
          widget:hide()
        end
      end
    end
end

function DD_GUI.update_character_condition_gauges()
    local visible = character_condition_gauges_visible()
    set_condition_gauges_visible(visible)
    if not visible then
      return
    end

    local vitals = gmcp.Char.Vitals
    if DD_GUI.Thirst then
      DD_GUI.Thirst:setValue(
        condition_gauge_value(vitals.thirst, vitals.maxthirst), 1000)
    end
    if DD_GUI.Hunger then
      DD_GUI.Hunger:setValue(
        condition_gauge_value(vitals.hunger, vitals.maxhunger), 1000)
    end
end

local PORTRAIT_ICON_BASE_SIZE = 15
local PORTRAIT_ICON_SIZE = 18
local PORTRAIT_ICON_GAP = 1
local PORTRAIT_ICON_COLUMNS = 5
local PORTRAIT_ICON_RIGHT = 2
local PORTRAIT_ICON_BOTTOM = 3

local function perceptual_icon_alpha(value, maximum)
    value = tonumber(value) or 0
    maximum = tonumber(maximum) or 0
    if value <= 0 or maximum <= 0 then
      return 0
    end

    local ratio = math.max(0, math.min(1, value / maximum))
    return math.floor(255 * (ratio ^ 0.65) + 0.5)
end

local function drunk_icon_alpha()
    local vitals = gmcp and gmcp.Char and gmcp.Char.Vitals
    local drunk = type(vitals) == "table" and tonumber(vitals.drunk) or 0
    if drunk <= 0 then
      return 0
    end

    local maximum = tonumber(vitals.maxdrunk) or 48
    if maximum <= 0 then
      maximum = 48
    end

    return perceptual_icon_alpha(drunk, maximum)
end

local function normalized_affect_text(value)
    local text = tostring(value or ""):lower()
    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalized_affect_duration(value)
    local duration = tonumber(value)
    if duration == nil then
      return 1
    elseif duration < 0 then
      return 20
    end

    -- DD4 reports zero while less than one tick remains. Keep the indicator
    -- faint until the affect actually disappears from the GMCP list.
    return math.max(1, duration)
end

local AFFECT_ICON_DEFINITIONS = {
  {
    key = "poison",
    matches = function(name, gives)
      return gives == "poison" or name == "poison" or name == "nausea"
    end,
  },
  {
    key = "hold",
    matches = function(name, gives)
      return gives == "hold" or name == "hold"
    end,
  },
  {
    key = "curse",
    matches = function(name, gives)
      return gives == "curse" or name == "curse"
    end,
  },
  {
    key = "slow",
    matches = function(name, gives)
      return gives == "slow" or name == "slow"
    end,
  },
  {
    key = "confusion",
    matches = function(name, gives)
      return gives == "confused" or name == "confusion" or
             name == "confused"
    end,
  },
  {
    key = "dazed",
    matches = function(name, gives)
      return gives == "dazed" or name == "dazed"
    end,
  },
  {
    key = "no_recall",
    matches = function(name, gives)
      return gives == "no_recall" or name == "no_recall" or
             name == "no recall"
    end,
  },
  {
    key = "swallowed",
    matches = function(name, gives)
      return gives == "swallowed" or name == "swallowed"
    end,
  },
  {
    key = "plague",
    matches = function(name, gives)
      return gives == "plague" or name == "plague"
    end,
  },
  {
    key = "dot",
    matches = function(name, gives)
      return gives == "dot" or name == "dot" or
             name == "damage over time"
    end,
  },
  {
    key = "prone",
    matches = function(name, gives)
      return gives == "prone" or name == "prone"
    end,
  },
  {
    key = "eye_trauma",
    matches = function(name, gives)
      return gives == "eye trauma" or name == "eye trauma"
    end,
  },
  {
    key = "head_trauma",
    matches = function(name, gives)
      return gives == "head trauma" or name == "head trauma"
    end,
  },
  {
    key = "arm_trauma",
    matches = function(name, gives)
      return gives == "arm trauma" or name == "arm trauma"
    end,
  },
  {
    key = "leg_trauma",
    matches = function(name, gives)
      return gives == "leg trauma" or name == "leg trauma"
    end,
  },
  {
    key = "heart_trauma",
    matches = function(name, gives)
      return gives == "heart trauma" or name == "heart trauma"
    end,
  },
  {
    key = "tail_trauma",
    matches = function(name, gives)
      return gives == "tail trauma" or name == "tail trauma"
    end,
  },
  {
    key = "torso_trauma",
    matches = function(name, gives)
      return gives == "torso trauma" or name == "torso trauma"
    end,
  },
  {
    key = "faerie_fire",
    matches = function(name, gives)
      return gives == "faerie fire" or name == "faerie fire"
    end,
  },
  {
    key = "sleep",
    matches = function(name, gives)
      return gives == "sleep" or name == "sleep"
    end,
  },
  {
    key = "charm",
    matches = function(name, gives)
      return gives == "charm" or name == "charm"
    end,
  },
  {
    key = "blind",
    matches = function(name, gives)
      return gives == "blindness" or name == "blind" or
             name == "blindness"
    end,
  },
}

local function ordered_child_tables(value)
    local numeric = {}
    local named = {}
    for key, child in pairs(value) do
      if type(child) == "table" then
        local entry = {key = key, value = child}
        if type(key) == "number" then
          table.insert(numeric, entry)
        else
          table.insert(named, entry)
        end
      end
    end

    table.sort(numeric, function(left, right)
      return left.key < right.key
    end)
    table.sort(named, function(left, right)
      return tostring(left.key) < tostring(right.key)
    end)

    local children = {}
    for _, entry in ipairs(numeric) do
      table.insert(children, entry.value)
    end
    for _, entry in ipairs(named) do
      table.insert(children, entry.value)
    end
    return children
end

local function collect_affect_icon_matches()
    local affect_data = gmcp and gmcp.Char and gmcp.Char.Affect
    local matches = {}
    if type(affect_data) ~= "table" then
      return matches
    end

    local seen = {}
    local record_index = 0
    local function scan(value)
      if type(value) ~= "table" or seen[value] then
        return
      end
      seen[value] = true

      if value.name ~= nil or value.gives ~= nil then
        record_index = record_index + 1
        local name = normalized_affect_text(value.name)
        local gives = normalized_affect_text(value.gives)
        local duration = normalized_affect_duration(value.duration)
        for definition_index, definition in ipairs(AFFECT_ICON_DEFINITIONS) do
          if definition.matches(name, gives, value) then
            local match = matches[definition.key]
            if not match then
              match = {
                duration = duration,
                first_seen = record_index,
                definition_index = definition_index,
              }
              matches[definition.key] = match
            else
              match.duration = math.max(match.duration, duration)
            end
          end
        end
      end

      for _, child in ipairs(ordered_child_tables(value)) do
        scan(child)
      end
    end

    scan(affect_data)
    return matches
end

local function affect_duration_alpha(duration)
    if not duration then
      return 0
    end
    return perceptual_icon_alpha(math.min(duration, 20), 20)
end

local function ensure_portrait_condition_registry()
    DD_GUI.PortraitConditionIcons = DD_GUI.PortraitConditionIcons or {}
    DD_GUI.PortraitConditionActivationOrder =
      DD_GUI.PortraitConditionActivationOrder or {}
    DD_GUI.PortraitConditionActivationSequence =
      DD_GUI.PortraitConditionActivationSequence or 0
    return DD_GUI.PortraitConditionIcons
end

function DD_GUI.layout_portrait_condition_icons()
    local active = {}
    for _, state in pairs(ensure_portrait_condition_registry()) do
      if state.active and state.icon then
        table.insert(active, state)
      end
    end

    table.sort(active, function(left, right)
      if left.activation_order == right.activation_order then
        return left.key < right.key
      end
      return left.activation_order < right.activation_order
    end)

    local signature_parts = {}
    for _, state in ipairs(active) do
      table.insert(signature_parts,
        state.key .. ":" .. tostring(state.activation_order))
    end
    local signature = table.concat(signature_parts, "|")
    if DD_GUI.PortraitConditionLayoutSignature == signature then
      return
    end
    DD_GUI.PortraitConditionLayoutSignature = signature

    for index, state in ipairs(active) do
      local slot = index - 1
      local column = slot % PORTRAIT_ICON_COLUMNS
      local row = math.floor(slot / PORTRAIT_ICON_COLUMNS)
      local x = -(PORTRAIT_ICON_RIGHT + PORTRAIT_ICON_SIZE +
                  column * (PORTRAIT_ICON_SIZE + PORTRAIT_ICON_GAP))
      local y = -(PORTRAIT_ICON_BOTTOM + PORTRAIT_ICON_SIZE +
                  row * (PORTRAIT_ICON_SIZE + PORTRAIT_ICON_GAP))
      state.icon:move(tostring(x) .. "px", tostring(y) .. "px")
      state.icon:show()
      if state.icon.raiseAll then
        state.icon:raiseAll()
      end
    end
end

local function set_portrait_condition_active(key, alpha, defer_layout)
    local registry = ensure_portrait_condition_registry()
    local state = registry[key]
    if not state or not state.icon then
      return
    end

    alpha = tonumber(alpha) or 0
    if alpha <= 0 then
      state.active = false
      state.alpha = 0
      state.activation_order = nil
      DD_GUI.PortraitConditionActivationOrder[key] = nil
      state.icon:hide()
    else
      local activation_order = DD_GUI.PortraitConditionActivationOrder[key]
      if not activation_order then
        DD_GUI.PortraitConditionActivationSequence =
          DD_GUI.PortraitConditionActivationSequence + 1
        activation_order = DD_GUI.PortraitConditionActivationSequence
        DD_GUI.PortraitConditionActivationOrder[key] = activation_order
      end
      state.active = true
      state.alpha = alpha
      state.activation_order = activation_order
    end

    if not defer_layout then
      DD_GUI.layout_portrait_condition_icons()
    end
end

local function scaled_alpha(alpha, factor)
    return math.max(0, math.min(255,
      math.floor((tonumber(alpha) or 0) * (factor or 1) + 0.5)))
end

local function scaled_icon_metric(value, minimum)
    local scaled = math.floor((tonumber(value) or 0) *
      PORTRAIT_ICON_SIZE / PORTRAIT_ICON_BASE_SIZE + 0.5)
    return math.max(minimum or 0, scaled)
end

local function rgba(color, alpha)
    return string.format("rgba(%d,%d,%d,%d)",
      color[1], color[2], color[3], alpha)
end

local function style_icon_part(part, alpha, style)
    if not part or not part.setStyleSheet then
      return
    end

    style = style or {}
    local background = "rgba(0,0,0,0)"
    if style.fill then
      background = rgba(style.fill,
        scaled_alpha(alpha, style.fill_opacity or 1))
    end

    local border = "border: 0px;"
    if style.border then
      border = string.format("border: %dpx solid %s;",
        style.border_width or 1,
        rgba(style.border,
          scaled_alpha(alpha, style.border_opacity or 1)))
    end

    part:setStyleSheet(string.format([[
      background-color: %s;
      %s
      border-radius: %dpx;
      %s
    ]], background, border, scaled_icon_metric(style.radius or 0),
      style.extra or ""))
end

local PORTRAIT_ICON_SPECS = {
  drunk = {
    root = "DrunkIcon",
    tooltip = "Drunk: your current intoxication.",
    parts = {
      {"Handle", 10, 7, 4, 6, {border = {255,190,55}, radius = 2,
        extra = "border-left: 0px;"}},
      {"Body", 2, 6, 9, 8, {fill = {174,91,8},
        border = {255,201,66}, radius = 1}},
      {"Shine", 4, 8, 1, 4, {fill = {255,213,91}, fill_opacity = 0.72}},
      {"Foam", 1, 4, 11, 4, {fill = {245,230,182},
        border = {255,247,218}, radius = 2}},
      {"BubbleLarge", 4, 1, 3, 3, {fill = {255,235,166}, radius = 2}},
      {"BubbleSmall", 9, 2, 2, 2, {fill = {255,235,166},
        fill_opacity = 0.72, radius = 1}},
    },
  },
  poison = {
    root = "PoisonIcon",
    tooltip = "Poisoned: poison or nausea is affecting you.",
    parts = {
      {"Stopper", 5, 1, 6, 3, {fill = {85,55,31}, border = {189,145,73},
        radius = 1}},
      {"Neck", 6, 4, 4, 3, {fill = {21,72,30}, fill_opacity = 0.68,
        border = {124,255,92}, radius = 1}},
      {"Bottle", 2, 6, 12, 8, {fill = {12,54,22}, fill_opacity = 0.68,
        border = {104,255,70}, radius = 3}},
      {"Liquid", 3, 10, 10, 3, {fill = {61,205,35}, radius = 1}},
      {"Shine", 4, 7, 1, 4, {fill = {190,255,139}, fill_opacity = 0.68}},
      {"BubbleLarge", 7, 8, 2, 2, {fill = {191,255,135}, radius = 1}},
      {"BubbleSmall", 10, 9, 1, 1, {fill = {191,255,135},
        fill_opacity = 0.68}},
    },
  },
  hold = {
    root = "HoldIcon",
    tooltip = "Held: you are trapped, paralysed, or otherwise restrained.",
    parts = {
      {"LeftCuff", 0, 4, 6, 8, {border = {174,201,211}, radius = 3}},
      {"RightCuff", 9, 4, 6, 8, {border = {174,201,211}, radius = 3}},
      {"Bridge", 5, 7, 5, 3, {fill = {42,59,68}, fill_opacity = 0.68,
        border = {213,229,234}, radius = 1}},
      {"LinkTop", 6, 5, 3, 2, {fill = {128,158,170}}},
      {"LinkBottom", 6, 10, 3, 2, {fill = {128,158,170}}},
      {"GlintLeft", 2, 5, 1, 1, {fill = {241,249,250},
        fill_opacity = 0.68}},
      {"GlintRight", 12, 5, 1, 1, {fill = {241,249,250},
        fill_opacity = 0.68}},
    },
  },
  curse = {
    root = "CurseIcon",
    tooltip = "Cursed: a magical curse is affecting you and may prevent recall.",
    parts = {
      {"Eye", 1, 4, 13, 8, {fill = {39,7,53}, fill_opacity = 0.72,
        border = {221,81,255}, radius = 6}},
      {"Iris", 5, 5, 5, 6, {fill = {135,32,178},
        border = {241,148,255}, radius = 3}},
      {"Pupil", 7, 6, 2, 4, {fill = {12,0,18}, radius = 1}},
      {"ThornTop", 7, 1, 2, 4, {fill = {197,58,235}}},
      {"ThornBottom", 7, 11, 2, 3, {fill = {197,58,235}}},
      {"ThornLeft", 0, 7, 3, 2, {fill = {197,58,235}}},
      {"ThornRight", 12, 7, 3, 2, {fill = {197,58,235}}},
      {"Glint", 6, 6, 1, 1, {fill = {255,222,255}, fill_opacity = 0.72}},
    },
  },
  slow = {
    root = "SlowIcon",
    tooltip = "Slowed: your actions and movement are slowed.",
    parts = {
      {"TopBar", 2, 1, 11, 2, {fill = {164,229,255}, radius = 1}},
      {"BottomBar", 2, 12, 11, 2, {fill = {164,229,255}, radius = 1}},
      {"Upper", 4, 3, 7, 5, {fill = {26,89,127}, fill_opacity = 0.72,
        border = {104,205,245}, radius = 2}},
      {"Lower", 4, 8, 7, 4, {fill = {42,147,186},
        border = {104,205,245}, radius = 2}},
      {"Waist", 6, 7, 3, 2, {fill = {218,247,255}}},
    },
  },
  confusion = {
    root = "ConfusionIcon",
    tooltip = "Confused: confusion is affecting your actions.",
    parts = {
      {"ArcTop", 4, 1, 8, 3, {fill = {240,77,224}, radius = 2}},
      {"ArcRight", 10, 3, 3, 7, {fill = {209,48,198}, radius = 2}},
      {"ArcBottom", 4, 10, 8, 3, {fill = {48,211,218}, radius = 2}},
      {"ArcLeft", 2, 6, 3, 6, {fill = {40,169,190}, radius = 2}},
      {"Core", 6, 5, 4, 4, {fill = {255,221,80},
        border = {255,244,166}, radius = 2}},
    },
  },
  dazed = {
    root = "DazedIcon",
    tooltip = "Dazed: you may be temporarily unable to act.",
    parts = {
      {"Horizontal", 2, 7, 11, 2, {fill = {245,185,38}}},
      {"Vertical", 7, 2, 2, 11, {fill = {245,185,38}}},
      {"Center", 5, 5, 6, 6, {fill = {255,220,73},
        border = {255,244,173}, radius = 3}},
      {"SparkTopLeft", 3, 3, 2, 2, {fill = {255,238,124}, radius = 1}},
      {"SparkBottomRight", 11, 11, 2, 2, {fill = {255,238,124}, radius = 1}},
    },
  },
  no_recall = {
    root = "NoRecallIcon",
    tooltip = "No recall: magical recall is blocked.",
    parts = {
      {"Top", 3, 2, 9, 2, {fill = {211,87,82}}},
      {"Left", 3, 3, 2, 10, {fill = {157,45,45}}},
      {"Right", 10, 3, 2, 10, {fill = {157,45,45}}},
      {"Door", 5, 4, 5, 9, {fill = {35,10,12},
        border = {211,87,82}}},
      {"Barrier", 1, 7, 13, 2, {fill = {255,62,62},
        border = {255,150,145}, radius = 1}},
    },
  },
  swallowed = {
    root = "SwallowedIcon",
    tooltip = "Swallowed: you are inside a creature.",
    parts = {
      {"TopJaw", 1, 2, 13, 5, {fill = {63,105,47},
        border = {145,211,91}, radius = 3}},
      {"BottomJaw", 1, 9, 13, 5, {fill = {63,105,47},
        border = {145,211,91}, radius = 3}},
      {"Mouth", 2, 6, 11, 4, {fill = {49,4,9},
        border = {176,54,61}, radius = 2}},
      {"ToothLeft", 3, 6, 2, 2, {fill = {238,232,199}}},
      {"ToothCenter", 7, 8, 2, 2, {fill = {238,232,199}}},
      {"ToothRight", 11, 6, 2, 2, {fill = {238,232,199}}},
    },
  },
  plague = {
    root = "PlagueIcon",
    tooltip = "Plagued: a virulent magical disease is affecting you.",
    parts = {
      {"Head", 3, 1, 9, 9, {fill = {94,116,31},
        border = {202,231,91}, radius = 5}},
      {"EyeLeft", 5, 4, 2, 2, {fill = {18,25,7}, radius = 1}},
      {"EyeRight", 9, 4, 2, 2, {fill = {18,25,7}, radius = 1}},
      {"Nose", 7, 6, 2, 2, {fill = {36,43,12}, radius = 1}},
      {"Jaw", 5, 9, 6, 4, {fill = {119,139,38},
        border = {202,231,91}, radius = 1}},
      {"ToothLeft", 6, 10, 1, 2, {fill = {226,235,163}}},
      {"ToothRight", 9, 10, 1, 2, {fill = {226,235,163}}},
      {"Pox", 2, 3, 2, 2, {fill = {222,184,47}, radius = 1}},
    },
  },
  dot = {
    root = "DotIcon",
    tooltip = "Damage over time: an ongoing effect is repeatedly hurting you.",
    parts = {
      {"Flame", 4, 3, 8, 11, {fill = {171,23,27},
        border = {255,91,45}, radius = 5}},
      {"Tip", 7, 1, 3, 5, {fill = {241,65,30}, radius = 2}},
      {"Core", 7, 7, 3, 5, {fill = {255,184,48},
        border = {255,231,123}, radius = 2}},
      {"Spark", 11, 2, 2, 3, {fill = {255,115,44}, radius = 1}},
    },
  },
  prone = {
    root = "ProneIcon",
    tooltip = "Prone: you have been knocked down.",
    parts = {
      {"Ground", 1, 12, 13, 2, {fill = {151,160,170}, radius = 1}},
      {"Head", 1, 7, 4, 4, {fill = {221,178,121},
        border = {255,220,167}, radius = 2}},
      {"Body", 5, 7, 7, 3, {fill = {121,54,48},
        border = {226,112,88}, radius = 1}},
      {"Arm", 6, 4, 2, 4, {fill = {226,112,88}, radius = 1}},
      {"Leg", 11, 9, 3, 3, {fill = {89,101,119}, radius = 1}},
      {"Dust", 2, 4, 2, 2, {fill = {186,193,200},
        fill_opacity = 0.72, radius = 1}},
    },
  },
  eye_trauma = {
    root = "EyeTraumaIcon",
    tooltip = "Eye trauma: your eyes have been injured.",
    parts = {
      {"Eye", 1, 5, 13, 7, {fill = {40,31,34},
        border = {220,202,190}, radius = 6}},
      {"Iris", 5, 6, 5, 5, {fill = {164,24,31},
        border = {255,93,91}, radius = 3}},
      {"Pupil", 7, 7, 2, 3, {fill = {12,4,5}, radius = 1}},
      {"Wound", 11, 2, 2, 5, {fill = {242,48,48}, radius = 1}},
      {"Blood", 12, 10, 2, 3, {fill = {176,18,28}, radius = 1}},
    },
  },
  head_trauma = {
    root = "HeadTraumaIcon",
    tooltip = "Head trauma: your head has been injured.",
    parts = {
      {"Head", 3, 2, 9, 10, {fill = {184,153,120},
        border = {239,211,171}, radius = 5}},
      {"Neck", 6, 11, 4, 3, {fill = {141,111,86}, radius = 1}},
      {"CrackTop", 8, 2, 2, 4, {fill = {225,43,48}}},
      {"CrackSide", 6, 5, 3, 2, {fill = {225,43,48}}},
      {"Impact", 11, 1, 3, 3, {fill = {255,126,66}, radius = 2}},
    },
  },
  arm_trauma = {
    root = "ArmTraumaIcon",
    tooltip = "Arm trauma: one of your arms has been injured.",
    parts = {
      {"Head", 6, 1, 4, 4, {fill = {204,211,217}, radius = 2}},
      {"Torso", 6, 5, 4, 6, {fill = {108,121,135}, radius = 1}},
      {"GoodArm", 2, 6, 5, 2, {fill = {157,169,180}, radius = 1}},
      {"HurtArm", 9, 6, 5, 2, {fill = {220,43,48},
        border = {255,121,104}, radius = 1}},
      {"LeftLeg", 5, 10, 2, 4, {fill = {108,121,135}, radius = 1}},
      {"RightLeg", 9, 10, 2, 4, {fill = {108,121,135}, radius = 1}},
    },
  },
  leg_trauma = {
    root = "LegTraumaIcon",
    tooltip = "Leg trauma: one of your legs has been injured.",
    parts = {
      {"Head", 6, 1, 4, 4, {fill = {204,211,217}, radius = 2}},
      {"Torso", 6, 5, 4, 6, {fill = {108,121,135}, radius = 1}},
      {"LeftArm", 2, 6, 5, 2, {fill = {157,169,180}, radius = 1}},
      {"RightArm", 9, 6, 5, 2, {fill = {157,169,180}, radius = 1}},
      {"GoodLeg", 5, 10, 2, 4, {fill = {108,121,135}, radius = 1}},
      {"HurtLeg", 9, 10, 2, 4, {fill = {220,43,48},
        border = {255,121,104}, radius = 1}},
    },
  },
  heart_trauma = {
    root = "HeartTraumaIcon",
    tooltip = "Heart trauma: your heart has been injured.",
    parts = {
      {"LeftLobe", 3, 3, 6, 6, {fill = {171,20,32},
        border = {255,82,83}, radius = 4}},
      {"RightLobe", 7, 3, 6, 6, {fill = {171,20,32},
        border = {255,82,83}, radius = 4}},
      {"Point", 5, 7, 6, 6, {fill = {194,24,35}, radius = 3}},
      {"Wound", 7, 4, 2, 7, {fill = {255,197,86}}},
      {"Pulse", 2, 8, 4, 2, {fill = {255,230,160}}},
    },
  },
  tail_trauma = {
    root = "TailTraumaIcon",
    tooltip = "Tail trauma: your tail has been injured.",
    parts = {
      {"Head", 2, 3, 4, 4, {fill = {181,190,199}, radius = 2}},
      {"Body", 5, 5, 6, 6, {fill = {105,119,132}, radius = 2}},
      {"LeftLeg", 5, 10, 2, 4, {fill = {105,119,132}, radius = 1}},
      {"RightLeg", 9, 10, 2, 4, {fill = {105,119,132}, radius = 1}},
      {"Tail", 10, 8, 4, 2, {fill = {220,43,48},
        border = {255,121,104}, radius = 1}},
      {"TailTip", 13, 6, 2, 4, {fill = {220,43,48}, radius = 1}},
    },
  },
  torso_trauma = {
    root = "TorsoTraumaIcon",
    tooltip = "Torso trauma: your body has been injured.",
    parts = {
      {"Head", 6, 1, 4, 4, {fill = {204,211,217}, radius = 2}},
      {"Torso", 6, 5, 4, 6, {fill = {220,43,48},
        border = {255,121,104}, radius = 1}},
      {"LeftArm", 2, 6, 5, 2, {fill = {157,169,180}, radius = 1}},
      {"RightArm", 9, 6, 5, 2, {fill = {157,169,180}, radius = 1}},
      {"LeftLeg", 5, 10, 2, 4, {fill = {108,121,135}, radius = 1}},
      {"RightLeg", 9, 10, 2, 4, {fill = {108,121,135}, radius = 1}},
    },
  },
  faerie_fire = {
    root = "FaerieFireIcon",
    tooltip = "Faerie fire: revealing magical flames surround you.",
    parts = {
      {"Flame", 4, 3, 8, 11, {fill = {116,35,170},
        border = {227,105,255}, radius = 5}},
      {"Tip", 7, 1, 3, 5, {fill = {195,68,241}, radius = 2}},
      {"Core", 7, 7, 3, 5, {fill = {67,222,239},
        border = {181,251,255}, radius = 2}},
      {"SparkLeft", 2, 5, 2, 3, {fill = {207,91,250}, radius = 1}},
      {"SparkRight", 12, 3, 2, 3, {fill = {93,225,241}, radius = 1}},
    },
  },
  sleep = {
    root = "SleepIcon",
    tooltip = "Asleep: magical sleep is preventing you from acting.",
    parts = {
      {"Bed", 1, 8, 13, 5, {fill = {35,58,101},
        border = {128,177,238}, radius = 2}},
      {"Pillow", 2, 6, 5, 4, {fill = {183,211,242},
        border = {230,244,255}, radius = 2}},
      {"Blanket", 7, 7, 6, 5, {fill = {61,101,165}, radius = 2}},
      {"PostLeft", 1, 7, 2, 7, {fill = {132,165,205}, radius = 1}},
      {"PostRight", 13, 9, 2, 5, {fill = {132,165,205}, radius = 1}},
      {"Dream", 9, 2, 4, 3, {fill = {151,207,255},
        fill_opacity = 0.72, radius = 2}},
    },
  },
  charm = {
    root = "CharmIcon",
    tooltip = "Charmed: another creature is influencing your will.",
    parts = {
      {"LeftLobe", 3, 3, 6, 6, {fill = {198,45,131},
        border = {255,133,207}, radius = 4}},
      {"RightLobe", 7, 3, 6, 6, {fill = {198,45,131},
        border = {255,133,207}, radius = 4}},
      {"Point", 5, 7, 6, 6, {fill = {220,51,143}, radius = 3}},
      {"ChainLeft", 1, 7, 5, 2, {fill = {169,184,197}, radius = 1}},
      {"ChainRight", 10, 7, 5, 2, {fill = {169,184,197}, radius = 1}},
      {"Lock", 7, 6, 2, 4, {fill = {235,221,139},
        border = {255,246,180}, radius = 1}},
    },
  },
  blind = {
    root = "BlindIcon",
    tooltip = "Blind: you cannot see normally.",
    parts = {
      {"Band", 1, 5, 13, 6, {fill = {28,31,37},
        border = {184,194,207}, radius = 2}},
      {"LeftTie", 0, 7, 3, 2, {fill = {126,139,154}}},
      {"RightTie", 12, 7, 3, 2, {fill = {126,139,154}}},
      {"LeftFold", 4, 7, 2, 2, {fill = {83,94,108}, radius = 1}},
      {"RightFold", 9, 7, 2, 2, {fill = {83,94,108}, radius = 1}},
      {"Knot", 7, 6, 2, 4, {fill = {216,225,232}, radius = 1}},
    },
  },
}

local PORTRAIT_ICON_BUILD_ORDER = {
  "drunk", "poison", "hold", "curse", "slow", "confusion", "dazed",
  "no_recall", "swallowed", "plague", "dot", "prone", "eye_trauma",
  "head_trauma", "arm_trauma", "leg_trauma", "heart_trauma",
  "tail_trauma", "torso_trauma", "faerie_fire", "sleep", "charm", "blind",
}

local function render_portrait_condition_icon(key, alpha, defer_layout)
    local spec = PORTRAIT_ICON_SPECS[key]
    local state = ensure_portrait_condition_registry()[key]
    if not spec or not state then
      return
    end

    alpha = tonumber(alpha) or 0
    if alpha > 0 and state.alpha ~= alpha then
      for _, part_spec in ipairs(spec.parts) do
        style_icon_part(DD_GUI[spec.root .. part_spec[1]], alpha,
          part_spec[6])
      end
    end
    set_portrait_condition_active(key, alpha, defer_layout)
end

function DD_GUI.update_drunk_icon()
    render_portrait_condition_icon("drunk", drunk_icon_alpha())
end

local function update_single_affect_icon(key, alpha, defer_layout)
    if alpha == nil then
      local match = collect_affect_icon_matches()[key]
      alpha = affect_duration_alpha(match and match.duration)
    end
    render_portrait_condition_icon(key, alpha, defer_layout)
end

for _, definition in ipairs(AFFECT_ICON_DEFINITIONS) do
    local key = definition.key
    DD_GUI["update_" .. key .. "_icon"] = function(alpha, defer_layout)
      update_single_affect_icon(key, alpha, defer_layout)
    end
end

function DD_GUI.update_affect_icons()
    local matches = collect_affect_icon_matches()
    local active = {}

    for _, definition in ipairs(AFFECT_ICON_DEFINITIONS) do
      local match = matches[definition.key]
      if match then
        match.key = definition.key
        table.insert(active, match)
      else
        render_portrait_condition_icon(definition.key, 0, true)
      end
    end

    table.sort(active, function(left, right)
      if left.first_seen == right.first_seen then
        return left.definition_index < right.definition_index
      end
      return left.first_seen < right.first_seen
    end)

    for _, match in ipairs(active) do
      render_portrait_condition_icon(match.key,
        affect_duration_alpha(match.duration), true)
    end
    DD_GUI.layout_portrait_condition_icons()
end

local PORTRAIT_TOOLTIP_DURATION = 6

local function configure_portrait_icon_hover(widget, tooltip)
    local configured = false
    if widget and type(widget.setToolTip) == "function" then
      configured = pcall(widget.setToolTip, widget, tooltip,
        PORTRAIT_TOOLTIP_DURATION)
    end
    if not configured and widget and widget.name and
       type(setLabelToolTip) == "function" then
      configured = pcall(setLabelToolTip, widget.name, tooltip,
        PORTRAIT_TOOLTIP_DURATION)
    end

    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(widget, not configured)
    end
end

local function new_portrait_icon(name)
    local icon = Geyser.Label:new({
      name = name,
      x = 0, y = 0,
      width = PORTRAIT_ICON_SIZE, height = PORTRAIT_ICON_SIZE,
    }, CharsheetPFPConsole)
    icon:setStyleSheet([[
      background-color: rgba(0,0,0,0);
      border: 0px;
    ]])
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(icon, false)
    end
    icon:hide()
    return icon
end

local function new_portrait_icon_part(parent, name, part_spec)
    local part = Geyser.Label:new({
      name = name,
      x = scaled_icon_metric(part_spec[2]),
      y = scaled_icon_metric(part_spec[3]),
      width = scaled_icon_metric(part_spec[4], 1),
      height = scaled_icon_metric(part_spec[5], 1),
    }, parent)
    part:setStyleSheet([[background-color: rgba(0,0,0,0); border: 0px;]])
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(part, true)
    end
    return part
end

local function new_portrait_icon_hover(parent, name, tooltip)
    local hover = Geyser.Label:new({
      name = name,
      x = 0, y = 0,
      width = "100%", height = "100%",
    }, parent)
    hover:setStyleSheet([[
      background-color: rgba(0,0,0,0);
      border: 0px;
    ]])
    configure_portrait_icon_hover(hover, tooltip)
    return hover
end

local function build_portrait_condition_icons()
    DD_GUI.PortraitConditionIcons = {}
    DD_GUI.PortraitConditionLayoutSignature = nil
    local registry = ensure_portrait_condition_registry()

    for _, key in ipairs(PORTRAIT_ICON_BUILD_ORDER) do
      local spec = PORTRAIT_ICON_SPECS[key]
      local root_name = "DD_GUI." .. spec.root
      local icon = new_portrait_icon(root_name)
      DD_GUI[spec.root] = icon
      local surfaces = {icon}

      for _, part_spec in ipairs(spec.parts) do
        local suffix = part_spec[1]
        local part = new_portrait_icon_part(icon,
          root_name .. "." .. suffix, part_spec)
        DD_GUI[spec.root .. suffix] = part
        table.insert(surfaces, part)
      end

      local hover = new_portrait_icon_hover(icon,
        root_name .. ".Hover", spec.tooltip)
      DD_GUI[spec.root .. "Hover"] = hover
      table.insert(surfaces, hover)

      registry[key] = {
        key = key,
        icon = icon,
        surfaces = surfaces,
        active = false,
      }
    end

    DD_GUI.update_affect_icons()
    DD_GUI.update_drunk_icon()
end

local function build_character_condition_gauges()
    if not DD_GUI.new_status_gauge then
      return
    end

    DD_GUI.CharsheetConditions = Geyser.Container:new({
      name = "DD_GUI.CharsheetConditions",
      x = "4%", y = "89%",
      width = "92%", height = "9%",
    }, DD_GUI.CharsheetBox)

    local colors = DD_GUI.Theme and DD_GUI.Theme.colors or {
      thirst = "rgb(35,112,153)",
      hunger = "rgb(145,103,34)",
    }
    local vitals = gmcp.Char.Vitals

    DD_GUI.Thirst, DD_GUI.ThirstLabel = DD_GUI.new_status_gauge(
      "DD_GUI.Thirst", DD_GUI.CharsheetConditions, "THIRST", colors.thirst,
      vitals.thirst, vitals.maxthirst,
      {x = "0%", y = "0%", width = "49%", height = "100%"})

    DD_GUI.Hunger, DD_GUI.HungerLabel = DD_GUI.new_status_gauge(
      "DD_GUI.Hunger", DD_GUI.CharsheetConditions, "HUNGER", colors.hunger,
      vitals.hunger, vitals.maxhunger,
      {x = "51%", y = "0%", width = "49%", height = "100%"})

    DD_GUI.update_character_condition_gauges()
end

function build_charsheet_console()

    CharsheetConsole = Geyser.MiniConsole:new({
      name="CharsheetConsole",
      x = "4%", y = "2%",
      width="92%",
      height="86%",
      autoWrap = false,
      color = "black",
      scrollBar = false,
      fontSize = 10,
    }, DD_GUI.CharsheetBox)
    if DD_GUI.Theme then
      DD_GUI.Theme:style_console(CharsheetConsole, 10)
    end

    CharsheetImageFrame = Geyser.Label:new({
      name="CharsheetImageFrame",
      x = "0%", y = "1%",
      width="105px",
      height="130px",
    }, CharsheetConsole)
    CharsheetImageFrame:setStyleSheet(DD_GUI.Theme and
      DD_GUI.Theme:image_frame_css() or [[border: 0px;]])
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(CharsheetImageFrame, true)
    end

    CharsheetPFPConsole = Geyser.MiniConsole:new({
      name="CharsheetPFPConsole",
      x = "3px", y = "4px",
      width="99px",
      height="124px",
      autoWrap = false,
      color = "black",
      scrollBar = false,
      fontSize = 10,
    }, CharsheetConsole)
    if DD_GUI.Theme then
      DD_GUI.Theme:style_console(CharsheetPFPConsole, 10)
    end

    local pfp_filename = DD_GUI.profile_avatar_filename and
      DD_GUI.profile_avatar_filename()
    if not pfp_filename then
      local chsex_string = 'male'

      if (gmcp.Char.Base.sex == 0) then
        chsex_string = 'neutral'
      elseif (gmcp.Char.Base.sex == 2) then
        chsex_string = 'female'
      end

      pfp_filename = firstToLower(gmcp.Char.Base.race) .. '_'
                         ..firstToLower(gmcp.Char.Base.class) .. '_'
                         ..chsex_string .. '_1.png'
    end
    --display(pfp_filename)

    -- A character-named avatar is selected automatically when it exists.

    local asset_path = DD_GUI.asset_path or function(relative_path)
      return ms_path .. '/' .. relative_path
    end
    local pfp_path = asset_path('avatars/' .. pfp_filename)
    local default_path = asset_path('avatars/default_char.png')
    if not file_exists(pfp_path) then
      pfp_path = default_path
    end

    DD_GUI.ImageFit:set(
      CharsheetPFPConsole,
      CharsheetConsole,
      pfp_path,
      {
        fallback = { width = 160, height = 200 },
        frame = CharsheetImageFrame,
      }
    )

    build_portrait_condition_icons()
    build_character_condition_gauges()
end
