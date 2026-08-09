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
    local drunk = type(vitals) == "table" and
      tonumber(vitals.drunk) or 0
    if drunk <= 0 then
      return 0
    end

    local maximum = tonumber(vitals.maxdrunk) or 48
    if maximum <= 0 then
      maximum = 48
    end

    -- A perceptual curve keeps low intoxication faintly legible while still
    -- reaching true transparency at zero and full brightness at the maximum.
    return perceptual_icon_alpha(drunk, maximum)
end

local function normalized_affect_text(value)
    local text = tostring(value or ""):lower()
    return text:gsub("^%s+", ""):gsub("%s+$", "")
end

local function strongest_affect_duration(matches)
    local affect_data = gmcp and gmcp.Char and gmcp.Char.Affect
    if type(affect_data) ~= "table" then
      return nil
    end

    local strongest
    local seen = {}
    local function scan(value)
      if type(value) ~= "table" or seen[value] then
        return
      end
      seen[value] = true

      local name = normalized_affect_text(value.name)
      local gives = normalized_affect_text(value.gives)
      if matches(name, gives, value) then
        local duration = tonumber(value.duration)
        if duration == nil then
          duration = 1
        elseif duration < 0 then
          duration = 20
        else
          -- DD4 reports zero while less than one tick remains. Keep the icon
          -- faint until the affect actually disappears from the GMCP list.
          duration = math.max(1, duration)
        end
        strongest = math.max(strongest or 0, duration)
      end

      for _, child in pairs(value) do
        if type(child) == "table" then
          scan(child)
        end
      end
    end

    scan(affect_data)
    return strongest
end

local function affect_duration_alpha(duration)
    if not duration then
      return 0
    end
    return perceptual_icon_alpha(math.min(duration, 20), 20)
end

local function poison_icon_alpha()
    return affect_duration_alpha(strongest_affect_duration(
      function(name, gives)
        return name == "poison" or name == "nausea" or gives == "poison"
      end))
end

local function hold_icon_alpha()
    return affect_duration_alpha(strongest_affect_duration(
      function(_, gives)
        return gives == "hold"
      end))
end

local function set_icon_part_style(part, stylesheet)
    if part and part.setStyleSheet then
      part:setStyleSheet(stylesheet)
    end
end

function DD_GUI.update_drunk_icon()
    local icon = DD_GUI.DrunkIcon
    if not icon then
      return
    end

    local alpha = drunk_icon_alpha()
    if alpha <= 0 then
      icon:hide()
      return
    end

    local soft_alpha = math.floor(alpha * 0.72 + 0.5)
    set_icon_part_style(DD_GUI.DrunkIconHandle, string.format([[
      background-color: rgba(0,0,0,0);
      border: 2px solid rgba(255,190,55,%d);
      border-left: 0px;
      border-radius: 2px;
    ]], alpha))
    set_icon_part_style(DD_GUI.DrunkIconBody, string.format([[
      background-color: rgba(174,91,8,%d);
      border: 1px solid rgba(255,201,66,%d);
      border-radius: 1px;
    ]], alpha, alpha))
    set_icon_part_style(DD_GUI.DrunkIconShine, string.format([[
      background-color: rgba(255,213,91,%d);
      border: 0px;
    ]], soft_alpha))
    set_icon_part_style(DD_GUI.DrunkIconFoam, string.format([[
      background-color: rgba(245,230,182,%d);
      border: 1px solid rgba(255,247,218,%d);
      border-radius: 2px;
    ]], alpha, alpha))
    set_icon_part_style(DD_GUI.DrunkIconBubbleLarge, string.format([[
      background-color: rgba(255,235,166,%d);
      border: 0px;
      border-radius: 2px;
    ]], alpha))
    set_icon_part_style(DD_GUI.DrunkIconBubbleSmall, string.format([[
      background-color: rgba(255,235,166,%d);
      border: 0px;
      border-radius: 2px;
    ]], soft_alpha))

    icon:show()
    if icon.raiseAll then
      icon:raiseAll()
    end
end

function DD_GUI.update_poison_icon()
    local icon = DD_GUI.PoisonIcon
    if not icon then
      return
    end

    local alpha = poison_icon_alpha()
    if alpha <= 0 then
      icon:hide()
      return
    end

    local soft_alpha = math.floor(alpha * 0.68 + 0.5)
    set_icon_part_style(DD_GUI.PoisonIconStopper, string.format([[
      background-color: rgba(85,55,31,%d);
      border: 1px solid rgba(189,145,73,%d);
      border-radius: 1px;
    ]], alpha, alpha))
    set_icon_part_style(DD_GUI.PoisonIconNeck, string.format([[
      background-color: rgba(21,72,30,%d);
      border: 1px solid rgba(124,255,92,%d);
      border-radius: 1px;
    ]], soft_alpha, alpha))
    set_icon_part_style(DD_GUI.PoisonIconBottle, string.format([[
      background-color: rgba(12,54,22,%d);
      border: 1px solid rgba(104,255,70,%d);
      border-radius: 4px;
    ]], soft_alpha, alpha))
    set_icon_part_style(DD_GUI.PoisonIconLiquid, string.format([[
      background-color: rgba(61,205,35,%d);
      border: 0px;
      border-radius: 2px;
    ]], alpha))
    set_icon_part_style(DD_GUI.PoisonIconShine, string.format([[
      background-color: rgba(190,255,139,%d);
      border: 0px;
    ]], soft_alpha))
    set_icon_part_style(DD_GUI.PoisonIconBubbleLarge, string.format([[
      background-color: rgba(191,255,135,%d);
      border: 0px;
      border-radius: 2px;
    ]], alpha))
    set_icon_part_style(DD_GUI.PoisonIconBubbleSmall, string.format([[
      background-color: rgba(191,255,135,%d);
      border: 0px;
      border-radius: 1px;
    ]], soft_alpha))

    icon:show()
    if icon.raiseAll then
      icon:raiseAll()
    end
end

function DD_GUI.update_hold_icon()
    local icon = DD_GUI.HoldIcon
    if not icon then
      return
    end

    local alpha = hold_icon_alpha()
    if alpha <= 0 then
      icon:hide()
      return
    end

    local soft_alpha = math.floor(alpha * 0.68 + 0.5)
    set_icon_part_style(DD_GUI.HoldIconLeftCuff, string.format([[
      background-color: rgba(0,0,0,0);
      border: 2px solid rgba(174,201,211,%d);
      border-radius: 5px;
    ]], alpha))
    set_icon_part_style(DD_GUI.HoldIconRightCuff, string.format([[
      background-color: rgba(0,0,0,0);
      border: 2px solid rgba(174,201,211,%d);
      border-radius: 5px;
    ]], alpha))
    set_icon_part_style(DD_GUI.HoldIconBridge, string.format([[
      background-color: rgba(42,59,68,%d);
      border: 2px solid rgba(213,229,234,%d);
      border-radius: 2px;
    ]], soft_alpha, alpha))
    set_icon_part_style(DD_GUI.HoldIconLinkTop, string.format([[
      background-color: rgba(128,158,170,%d);
      border: 0px;
      border-radius: 1px;
    ]], alpha))
    set_icon_part_style(DD_GUI.HoldIconLinkBottom, string.format([[
      background-color: rgba(128,158,170,%d);
      border: 0px;
      border-radius: 1px;
    ]], alpha))
    set_icon_part_style(DD_GUI.HoldIconGlintLeft, string.format([[
      background-color: rgba(241,249,250,%d);
      border: 0px;
      border-radius: 1px;
    ]], soft_alpha))
    set_icon_part_style(DD_GUI.HoldIconGlintRight, string.format([[
      background-color: rgba(241,249,250,%d);
      border: 0px;
      border-radius: 1px;
    ]], soft_alpha))

    icon:show()
    if icon.raiseAll then
      icon:raiseAll()
    end
end

local function new_portrait_icon(name, x)
    local icon = Geyser.Label:new({
      name = name,
      x = x, y = "-29px",
      width = "26px", height = "26px",
    }, CharsheetPFPConsole)
    icon:setStyleSheet([[
      background-color: rgba(0,0,0,0);
      border: 0px;
    ]])
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(icon, true)
    end
    return icon
end

local function new_portrait_icon_part(parent, name, constraints)
    constraints.name = name
    local part = Geyser.Label:new(constraints, parent)
    part:setStyleSheet([[background-color: rgba(0,0,0,0); border: 0px;]])
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(part, true)
    end
    return part
end

local function build_drunk_icon()
    DD_GUI.DrunkIcon = new_portrait_icon("DD_GUI.DrunkIcon", "-28px")

    DD_GUI.DrunkIconHandle = new_portrait_icon_part(DD_GUI.DrunkIcon,
      "DD_GUI.DrunkIcon.Handle",
      {x = "16px", y = "11px", width = "7px", height = "9px"})
    DD_GUI.DrunkIconBody = new_portrait_icon_part(DD_GUI.DrunkIcon,
      "DD_GUI.DrunkIcon.Body",
      {x = "3px", y = "9px", width = "15px", height = "14px"})
    DD_GUI.DrunkIconShine = new_portrait_icon_part(DD_GUI.DrunkIcon,
      "DD_GUI.DrunkIcon.Shine",
      {x = "6px", y = "12px", width = "2px", height = "8px"})
    DD_GUI.DrunkIconFoam = new_portrait_icon_part(DD_GUI.DrunkIcon,
      "DD_GUI.DrunkIcon.Foam",
      {x = "2px", y = "6px", width = "17px", height = "6px"})
    DD_GUI.DrunkIconBubbleLarge = new_portrait_icon_part(DD_GUI.DrunkIcon,
      "DD_GUI.DrunkIcon.BubbleLarge",
      {x = "7px", y = "1px", width = "4px", height = "4px"})
    DD_GUI.DrunkIconBubbleSmall = new_portrait_icon_part(DD_GUI.DrunkIcon,
      "DD_GUI.DrunkIcon.BubbleSmall",
      {x = "14px", y = "3px", width = "3px", height = "3px"})

    DD_GUI.update_drunk_icon()
end

local function build_poison_icon()
    DD_GUI.PoisonIcon = new_portrait_icon("DD_GUI.PoisonIcon", "-56px")

    DD_GUI.PoisonIconStopper = new_portrait_icon_part(DD_GUI.PoisonIcon,
      "DD_GUI.PoisonIcon.Stopper",
      {x = "9px", y = "2px", width = "9px", height = "4px"})
    DD_GUI.PoisonIconNeck = new_portrait_icon_part(DD_GUI.PoisonIcon,
      "DD_GUI.PoisonIcon.Neck",
      {x = "10px", y = "6px", width = "7px", height = "6px"})
    DD_GUI.PoisonIconBottle = new_portrait_icon_part(DD_GUI.PoisonIcon,
      "DD_GUI.PoisonIcon.Bottle",
      {x = "4px", y = "10px", width = "18px", height = "14px"})
    DD_GUI.PoisonIconLiquid = new_portrait_icon_part(DD_GUI.PoisonIcon,
      "DD_GUI.PoisonIcon.Liquid",
      {x = "6px", y = "17px", width = "14px", height = "5px"})
    DD_GUI.PoisonIconShine = new_portrait_icon_part(DD_GUI.PoisonIcon,
      "DD_GUI.PoisonIcon.Shine",
      {x = "7px", y = "12px", width = "2px", height = "8px"})
    DD_GUI.PoisonIconBubbleLarge = new_portrait_icon_part(DD_GUI.PoisonIcon,
      "DD_GUI.PoisonIcon.BubbleLarge",
      {x = "11px", y = "13px", width = "3px", height = "3px"})
    DD_GUI.PoisonIconBubbleSmall = new_portrait_icon_part(DD_GUI.PoisonIcon,
      "DD_GUI.PoisonIcon.BubbleSmall",
      {x = "16px", y = "15px", width = "2px", height = "2px"})

    DD_GUI.update_poison_icon()
end

local function build_hold_icon()
    DD_GUI.HoldIcon = new_portrait_icon("DD_GUI.HoldIcon", "-84px")

    DD_GUI.HoldIconLeftCuff = new_portrait_icon_part(DD_GUI.HoldIcon,
      "DD_GUI.HoldIcon.LeftCuff",
      {x = "1px", y = "7px", width = "10px", height = "13px"})
    DD_GUI.HoldIconRightCuff = new_portrait_icon_part(DD_GUI.HoldIcon,
      "DD_GUI.HoldIcon.RightCuff",
      {x = "15px", y = "7px", width = "10px", height = "13px"})
    DD_GUI.HoldIconBridge = new_portrait_icon_part(DD_GUI.HoldIcon,
      "DD_GUI.HoldIcon.Bridge",
      {x = "9px", y = "11px", width = "8px", height = "6px"})
    DD_GUI.HoldIconLinkTop = new_portrait_icon_part(DD_GUI.HoldIcon,
      "DD_GUI.HoldIcon.LinkTop",
      {x = "11px", y = "8px", width = "4px", height = "4px"})
    DD_GUI.HoldIconLinkBottom = new_portrait_icon_part(DD_GUI.HoldIcon,
      "DD_GUI.HoldIcon.LinkBottom",
      {x = "11px", y = "16px", width = "4px", height = "4px"})
    DD_GUI.HoldIconGlintLeft = new_portrait_icon_part(DD_GUI.HoldIcon,
      "DD_GUI.HoldIcon.GlintLeft",
      {x = "4px", y = "9px", width = "2px", height = "2px"})
    DD_GUI.HoldIconGlintRight = new_portrait_icon_part(DD_GUI.HoldIcon,
      "DD_GUI.HoldIcon.GlintRight",
      {x = "20px", y = "9px", width = "2px", height = "2px"})

    DD_GUI.update_hold_icon()
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

    build_hold_icon()
    build_poison_icon()
    build_drunk_icon()
    build_character_condition_gauges()
end
