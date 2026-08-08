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

    local ratio = math.max(0, math.min(1, drunk / maximum))
    -- A perceptual curve keeps low intoxication faintly legible while still
    -- reaching true transparency at zero and full brightness at the maximum.
    return math.floor(255 * (ratio ^ 0.65) + 0.5)
end

local function set_drunk_part_style(part, stylesheet)
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
    set_drunk_part_style(DD_GUI.DrunkIconHandle, string.format([[
      background-color: rgba(0,0,0,0);
      border: 2px solid rgba(255,190,55,%d);
      border-left: 0px;
      border-radius: 2px;
    ]], alpha))
    set_drunk_part_style(DD_GUI.DrunkIconBody, string.format([[
      background-color: rgba(174,91,8,%d);
      border: 1px solid rgba(255,201,66,%d);
      border-radius: 1px;
    ]], alpha, alpha))
    set_drunk_part_style(DD_GUI.DrunkIconShine, string.format([[
      background-color: rgba(255,213,91,%d);
      border: 0px;
    ]], soft_alpha))
    set_drunk_part_style(DD_GUI.DrunkIconFoam, string.format([[
      background-color: rgba(245,230,182,%d);
      border: 1px solid rgba(255,247,218,%d);
      border-radius: 2px;
    ]], alpha, alpha))
    set_drunk_part_style(DD_GUI.DrunkIconBubbleLarge, string.format([[
      background-color: rgba(255,235,166,%d);
      border: 0px;
      border-radius: 2px;
    ]], alpha))
    set_drunk_part_style(DD_GUI.DrunkIconBubbleSmall, string.format([[
      background-color: rgba(255,235,166,%d);
      border: 0px;
      border-radius: 2px;
    ]], soft_alpha))

    icon:show()
    if icon.raiseAll then
      icon:raiseAll()
    end
end

local function new_drunk_icon_part(name, constraints)
    constraints.name = name
    local part = Geyser.Label:new(constraints, DD_GUI.DrunkIcon)
    part:setStyleSheet([[background-color: rgba(0,0,0,0); border: 0px;]])
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(part, true)
    end
    return part
end

local function build_drunk_icon()
    DD_GUI.DrunkIcon = Geyser.Label:new({
      name = "DD_GUI.DrunkIcon",
      x = "-28px", y = "-29px",
      width = "26px", height = "26px",
    }, CharsheetPFPConsole)
    DD_GUI.DrunkIcon:setStyleSheet([[
      background-color: rgba(0,0,0,0);
      border: 0px;
    ]])
    if DD_GUI.set_widget_clickthrough then
      DD_GUI.set_widget_clickthrough(DD_GUI.DrunkIcon, true)
    end

    DD_GUI.DrunkIconHandle = new_drunk_icon_part(
      "DD_GUI.DrunkIcon.Handle",
      {x = "16px", y = "11px", width = "7px", height = "9px"})
    DD_GUI.DrunkIconBody = new_drunk_icon_part(
      "DD_GUI.DrunkIcon.Body",
      {x = "3px", y = "9px", width = "15px", height = "14px"})
    DD_GUI.DrunkIconShine = new_drunk_icon_part(
      "DD_GUI.DrunkIcon.Shine",
      {x = "6px", y = "12px", width = "2px", height = "8px"})
    DD_GUI.DrunkIconFoam = new_drunk_icon_part(
      "DD_GUI.DrunkIcon.Foam",
      {x = "2px", y = "6px", width = "17px", height = "6px"})
    DD_GUI.DrunkIconBubbleLarge = new_drunk_icon_part(
      "DD_GUI.DrunkIcon.BubbleLarge",
      {x = "7px", y = "1px", width = "4px", height = "4px"})
    DD_GUI.DrunkIconBubbleSmall = new_drunk_icon_part(
      "DD_GUI.DrunkIcon.BubbleSmall",
      {x = "14px", y = "3px", width = "3px", height = "3px"})

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

    build_drunk_icon()
    build_character_condition_gauges()
end
