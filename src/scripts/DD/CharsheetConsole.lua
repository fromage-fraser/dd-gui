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

    build_character_condition_gauges()
end
