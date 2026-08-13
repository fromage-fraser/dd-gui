debug.setmetatable(nil, { __index=function () end })

local function current_affect_name()
    local affects = gmcp and gmcp.Char and gmcp.Char.Affect
    if type(affects) ~= "table" or type(affects[1]) ~= "table" or
       type(affects[1][1]) ~= "table" then
        return ""
    end

    return tostring(affects[1][1].name or "")
end

local CHARACTER_SHEET_FIELDS = {
    base = {"name", "race", "class", "subclass", "sex"},
    stats = {
        "str", "str_mod", "int", "int_mod", "wis", "wis_mod",
        "dex", "dex_mod", "con", "con_mod", "fame", "crit", "swift",
        "hitroll", "damroll", "ac", "r_acid", "r_lightning", "r_heat",
        "r_cold", "save_vs",
    },
    worth = {
        "level", "alignment", "xplvl", "xptnl", "platinum", "gold",
        "silver", "copper", "steel", "titanium", "adamantite", "electrum",
        "starmetal",
    },
    vitals = {"form"},
}

local function character_sheet_signature()
    local char = gmcp and gmcp.Char or {}
    local signature = {}

    for _, scope_name in ipairs({"base", "stats", "worth", "vitals"}) do
        local scope = char[scope_name == "base" and "Base" or
            scope_name == "stats" and "Stats" or
            scope_name == "worth" and "Worth" or "Vitals"] or {}
        for _, field in ipairs(CHARACTER_SHEET_FIELDS[scope_name]) do
            signature[#signature + 1] = scope_name .. ":" .. field .. "=" ..
                tostring(scope[field] or "")
        end
    end

    signature[#signature + 1] = "affect=" .. current_affect_name()
    local profile_avatar = DD_GUI.profile_avatar_filename and
        DD_GUI.profile_avatar_filename() or ""
    signature[#signature + 1] = "avatar=" .. tostring(profile_avatar)
    return table.concat(signature, "\31")
end

local function normalized_gauge_value(value, maximum)
    value = tonumber(value) or 0
    maximum = tonumber(maximum) or 0
    if maximum <= 0 then
        return 0
    end

    return math.max(0, math.min(1000, (value * 1000) / maximum))
end

function update_vitals()
    if not gmcp or not gmcp.Char or type(gmcp.Char.Vitals) ~= "table" or
       type(gmcp.Char.Base) ~= "table" or type(gmcp.Char.Stats) ~= "table" or
       type(gmcp.Char.Worth) ~= "table" then
        return
    end

  if DD_GUI.prioritize_content_queue then
      DD_GUI.prioritize_content_queue()
  end

    if not hasFocus() then
        lost_focus = true
      end

    if lost_focus == true and hasFocus() then
        -- Focus recovery used to duplicate bootstrap's widget construction.
        -- That path could leave named adjustable panels hidden while their
        -- child consoles remained visible. Reuse the idempotent bootstrap so
        -- all roots, borders, and gauge columns are restored together.
        lost_focus = false
        if type(bootstrap) == "function" then
                bootstrap()
                return
        end
    end

  local hp      = tonumber(gmcp.Char.Vitals.hp) or 0
  local maxhp   = tonumber(gmcp.Char.Vitals.maxhp) or 0
  local mana    = tonumber(gmcp.Char.Vitals.mana) or 0
  local maxmana = tonumber(gmcp.Char.Vitals.maxmana) or 0
  local move    = tonumber(gmcp.Char.Vitals.move) or 0
  local maxmove = tonumber(gmcp.Char.Vitals.maxmove) or 0

  if (hp > maxhp) then
      hp = maxhp
  end
  if (mana > maxmana) then
      mana = maxmana
  end
  if (move > maxmove) then
      move = maxmove
  end
  --GUI.Hitpoints:setValue((100/tonumber(gmcp.Char.Vitals.maxhp))*tonumber(gmcp.Char.Vitals.hp),100,tonumber(gmcp.Char.Vitals.hp))
  DD_GUI.Hitpoints:setValue(normalized_gauge_value(hp, maxhp),1000)
  DD_GUI.Mana:setValue(normalized_gauge_value(mana, maxmana),1000)
  DD_GUI.Moves:setValue(normalized_gauge_value(move, maxmove),1000)
  if DD_GUI.update_character_condition_gauges then
      DD_GUI.update_character_condition_gauges()
  end

  --DD_GUI.Xp:setValue(((gmcp.Char.Worth.xp * 1000) / gmcp.Char.Worth.maxxp), 1000)
  local xplvl = tonumber(gmcp.Char.Worth.xplvl) or 0
  local xptnl = tonumber(gmcp.Char.Worth.xptnl) or 0
  if xptnl > 0 then
      DD_GUI.Xp:setValue(normalized_gauge_value(xplvl - xptnl, xplvl),1000)
  else
      DD_GUI.Xp:setValue(1000, 1000)
  end

  -- Vitals arrive frequently. Avoid clearing and repainting the complete
  -- character sheet, including its image, when only a gauge changed.
  local sheet_signature = character_sheet_signature()
  if DD_GUI.character_sheet_signature == sheet_signature then
      if DD_GUI.update_drunk_icon then
          DD_GUI.update_drunk_icon()
      end
      return
  end
  DD_GUI.character_sheet_signature = sheet_signature

  CharsheetConsole:clear()
  CharsheetConsole:resetAutoWrap()

  local chsex_string = 'male'

  if (tonumber(gmcp.Char.Base.sex) == 0) then
    chsex_string = 'neuter'
  elseif (tonumber(gmcp.Char.Base.sex) == 2) then
    chsex_string = 'female'
  end

  local race_name = tostring(gmcp.Char.Base.race or "unknown")
  local pfp_filename = race_name:lower():gsub("-", "_") .. '_'
  ..chsex_string .. '_1.png'

  local profile_avatar = DD_GUI.profile_avatar_filename and
    DD_GUI.profile_avatar_filename()
  if profile_avatar then
    pfp_filename = profile_avatar
  end

  --[[
        Right now all pfp filenames end in _1; at some point make it so a random default number for them
        can be chosen based on how many exist, and that this will persist across sessions for the profile.
  ]]--

  -- display(gmcp.Char.Base.race:lower():gsub("-", "_"))
  -- display(pfp_filename)
  -- Shifter stuff
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "hawk") then
    pfp_filename = 'hawk_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "chameleon") then
    pfp_filename = 'chameleon_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "cat") then
    pfp_filename = 'cat_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "snake") then
    pfp_filename = 'snake_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "scorpion") then
    pfp_filename = 'scorpion_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "spider") then
    pfp_filename = 'spider_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "bear") then
    pfp_filename = 'bear_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "tiger") then
    pfp_filename = 'tiger_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "hydra") then
    pfp_filename = 'hydra_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "phoenix") then
    pfp_filename = 'phoenix_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "demon") then
    pfp_filename = 'demon_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "dragon") then
    pfp_filename = 'dragon_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "fly") then
    pfp_filename = 'fly_form.png'
  end
  if (gmcp.Char.Base.class == "Shape Shifter") and (gmcp.Char.Vitals.form == "griffin") then
    pfp_filename = 'griffin_form.png'
  end

  --Werewolf stuff
  if (gmcp.Char.Base.subclass == "Werewolf") and (gmcp.Char.Vitals.form == "wolf") then
    pfp_filename = 'wolf_form.png'
  end
  if (gmcp.Char.Base.subclass == "Werewolf") and (gmcp.Char.Vitals.form == "direwolf") then
    pfp_filename = 'direwolf_form.png'
  end

  --Vampire stuff
  if (gmcp.Char.Base.subclass == "Vampire") and (gmcp.Char.Vitals.form == "bat") then
    pfp_filename = 'bat_form.png'
  end

  if (current_affect_name() == "mist walk") then
    pfp_filename = 'mist_form.png'
  end

  local asset_path = DD_GUI.asset_path or function(relative_path)
    return ms_path .. '/' .. relative_path
  end
  local char_image = asset_path('avatars/' .. pfp_filename)
  local def_image = asset_path('avatars/default_char.png')

  if file_exists(char_image) then
        DD_GUI.ImageFit:set(
          CharsheetPFPConsole,
          CharsheetConsole,
          char_image,
          {
            fallback = { width = 160, height = 200 },
            frame = CharsheetImageFrame,
          }
        )
  else
        DD_GUI.ImageFit:set(
          CharsheetPFPConsole,
          CharsheetConsole,
          def_image,
          {
            fallback = { width = 160, height = 200 },
            frame = CharsheetImageFrame,
          }
        )
  end

  if DD_GUI.update_drunk_icon then
        DD_GUI.update_drunk_icon()
  end

  --CharsheetPFPConsole:setBackgroundImage( [[
  --  background-image: url(]] .. ms_path .. '/avatars/' .. pfp_filename .. [[);
  --  background-position: top left;
  --  background-repeat: no-repeat;
  --]],
  --"style")

CharsheetConsole:cecho(
    "<white>"
    ..string.format("                Name:  <ansi_white>%s\n",
        gmcp.Char.Base.name)
    ..string.format("                <white>Race:  <ansi_white>%s",
        gmcp.Char.Base.race)
    .."<reset>\n"
 )

 if (gmcp.Char.Base.subclass == "none") then
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("                <white>Class: <ansi_white>%s",
            gmcp.Char.Base.class)
        .."<reset>\n"
    )
else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("                <white>Class: <ansi_white>%s",
            gmcp.Char.Base.subclass)
        .."<reset>\n"
    )
end

CharsheetConsole:cecho(
    "<white>"
    ..string.format("                <white>Level: <ansi_white>%d <white>Sex: <ansi_white>%s\n",
        gmcp.Char.Worth.level, firstToUpper(chsex_string))
    .."<reset>"
)

if (gmcp.Char.Base.class == "Shape Shifter") or (gmcp.Char.Base.subclass == "Werewolf") then
    if (current_affect_name() ~= "mist walk") then
    CharsheetConsole:cecho(
      "<white>"
      ..string.format("                <white>Form:  <ansi_white>%s\n",
          firstToUpper(gmcp.Char.Vitals.form))
      .."<reset>"
    )
    end
end

if (current_affect_name() == "mist walk")  then
    CharsheetConsole:cecho(
      "<white>"
      ..string.format("                <white>Form:  <ansi_white>Mist\n")
      .."<reset>"
    )
end

CharsheetConsole:cecho(""
    ..string.format("\n                <white>Str: <cyan>%s<reset>(<ansi_cyan>%s<reset>)",
        gmcp.Char.Stats.str_mod,
        gmcp.Char.Stats.str)
    ..string.format(" <white>Int: <cyan>%s<reset>(<ansi_cyan>%s<reset>)\n",
        gmcp.Char.Stats.int_mod,
        gmcp.Char.Stats.int)
    ..string.format("                <white>Wis: <cyan>%s<reset>(<ansi_cyan>%s<reset>)",
        gmcp.Char.Stats.wis_mod,
        gmcp.Char.Stats.wis)
    ..string.format(" <white>Dex: <cyan>%s<reset>(<ansi_cyan>%s<reset>)\n",
        gmcp.Char.Stats.dex_mod,
        gmcp.Char.Stats.dex)
    ..string.format("                <white>Con: <cyan>%s<reset>(<ansi_cyan>%s<reset>)",
        gmcp.Char.Stats.con_mod,
        gmcp.Char.Stats.con)
    ..string.format(" <white>Fame: <cyan>%s<reset>\n",
        gmcp.Char.Stats.fame)

    .."<reset>\n"
)

local made_return = false

if (tonumber(gmcp.Char.Worth.alignment) == 50000) and
   (tonumber(gmcp.Char.Stats.save_vs) == 50000) and
   (made_return == false) then
    made_return = true
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("\n")
    )
end

if (gmcp.Char.Base.class) ~= "Smithy" and
   (gmcp.Char.Base.subclass) ~= "Runesmith" and
   (gmcp.Char.Base.subclass) ~= "Engineer" and
   (made_return == false) then
    made_return = true
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("\n")
    )
end


if (tonumber(gmcp.Char.Worth.alignment) ~= 50000) then
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("<white>Alignment: <cyan>%-7s<white>",
            gmcp.Char.Worth.alignment)
    )
else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("<white>Alignment: <cyan>??   <white>")
    )
end

if (tonumber(gmcp.Char.Stats.save_vs) ~= 50000) then
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("Save vs Magic: <cyan>%-4s",
            gmcp.Char.Stats.save_vs)
        .."<reset>\n"
    )
else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("Save vs Magic: <cyan>??")
        .."<reset>\n"
    )
end

if (tonumber(gmcp.Char.Stats.crit) ~= 50000) then
    local crit_w_perc = gmcp.Char.Stats.crit .. "%"
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("<white>Critical:  <cyan>%-7s<white>",
            crit_w_perc)
    )
--[[
else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("<white>Critical:  <cyan>??  <white>")
    )
--]]
end

if (tonumber(gmcp.Char.Stats.swift) ~= 50000) then
    local swift_w_perc = gmcp.Char.Stats.swift .. "%"
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("Swiftness:     <cyan>%-4s\n",
            swift_w_perc)
        .."<reset>"
    )

else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("\n")
        .."<reset>"
    )

end

if (tonumber(gmcp.Char.Stats.hitroll) ~= 50000) then
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("<white>Hitroll: <red>%s<reset>  <white>Damroll: <red>%s<reset>",
            gmcp.Char.Stats.hitroll,
            gmcp.Char.Stats.damroll)
    )
else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("<white>Hitroll: <red>??<reset>  <white>Damroll: <red>??<reset>")
    )
end

if (tonumber(gmcp.Char.Stats.ac) ~= 50000) then
    CharsheetConsole:cecho(
    "<white>"
    ..string.format("  A/C: <red>%s<reset>\n",
    gmcp.Char.Stats.ac)
    )
else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("  A/C: <red>??<reset>\n")
    )
end

if (tonumber(gmcp.Char.Stats.r_acid) ~= 50000) then

    local acid_w_perc  = gmcp.Char.Stats.r_acid .. "%"
    local light_w_perc = gmcp.Char.Stats.r_lightning .. "%"
    local heat_w_perc  = gmcp.Char.Stats.r_heat .. "%"
    local cold_w_perc  = gmcp.Char.Stats.r_cold .. "%"
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("Res: A: <green>%-4s <white>L: <cyan>%-4s <white>H: <orange>%-4s <white>C: <SkyBlue>%-4s<reset>\n",
          acid_w_perc,
          light_w_perc,
          heat_w_perc,
          cold_w_perc)
    )
else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("\n")
    )
end

CharsheetConsole:cecho(
    "<white>"
    ..string.format("[<green>$<white>]: <white>P: <light_steel_blue>%-4d<white> G: <yellow>%-4d<reset> <white>S: <DimGrey>%-4d<reset> <white>C: <ansi_yellow>%-4d<reset>\n",
        gmcp.Char.Worth.platinum,
        gmcp.Char.Worth.gold,
        gmcp.Char.Worth.silver,
        gmcp.Char.Worth.copper)

    .."<reset>"
  )

  if (gmcp.Char.Base.class) == "Smithy"
  or (gmcp.Char.Base.subclass) == "Runesmith"
  or (gmcp.Char.Base.subclass) == "Engineer" then
      CharsheetConsole:cecho(
        string.format("Mat: <white>S: <light_steel_blue>%-3d<white> T: <ansi_yellow>%-3d<white> A: <yellow>%-3d<white> E: <white>%-3d<white> S: <red>%-3d",
          gmcp.Char.Worth.steel,
          gmcp.Char.Worth.titanium,
          gmcp.Char.Worth.adamantite,
          gmcp.Char.Worth.electrum,
          gmcp.Char.Worth.starmetal)
        .."<reset>"
      )
  end
end
