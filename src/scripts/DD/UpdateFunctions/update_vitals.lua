debug.setmetatable(nil, { __index=function () end })

function update_vitals()
    if not hasFocus() then
        lost_focus = true
      end

    if lost_focus == true then
    if hasFocus() then
        set_borders()
        ui_container()
        create_background()
        define_boxes()
        build_gauges()
        build_affects_box()
        build_affects_console()
        build_inventory_box()
        build_inventory_console()
        build_channel_box()
        build_channel_console()
        build_charsheet_box()
        build_charsheet_console()
        build_enemy_box()
        build_enemy_console()
        build_compass()
        lost_focus = false
    end
  end

  if (gmcp.Char.Vitals.hp > gmcp.Char.Vitals.maxhp) then
      gmcp.Char.Vitals.maxhp = gmcp.Char.Vitals.hp
  end
  if (gmcp.Char.Vitals.mana > gmcp.Char.Vitals.maxmana) then
      gmcp.Char.Vitals.maxmana = gmcp.Char.Vitals.mana
  end
  if (gmcp.Char.Vitals.move > gmcp.Char.Vitals.maxmove) then
      gmcp.Char.Vitals.maxmove = gmcp.Char.Vitals.move
  end

  --GUI.Hitpoints:setValue((100/tonumber(gmcp.Char.Vitals.maxhp))*tonumber(gmcp.Char.Vitals.hp),100,tonumber(gmcp.Char.Vitals.hp))
  DD_GUI.Hitpoints:setValue(((gmcp.Char.Vitals.hp * 1000) / gmcp.Char.Vitals.maxhp),1000)
  DD_GUI.Mana:setValue(((gmcp.Char.Vitals.mana * 1000) / gmcp.Char.Vitals.maxmana),1000)
  DD_GUI.Moves:setValue(((gmcp.Char.Vitals.move * 1000) / gmcp.Char.Vitals.maxmove),1000)
  --DD_GUI.Xp:setValue(((gmcp.Char.Worth.xp * 1000) / gmcp.Char.Worth.maxxp), 1000)
  DD_GUI.Xp:setValue((((gmcp.Char.Worth.xplvl - gmcp.Char.Worth.xptnl) * 1000) / gmcp.Char.Worth.xplvl), 1000)

  CharsheetConsole:clear()
  CharsheetConsole:resetAutoWrap()

  local chsex_string = 'male'

  if (tonumber(gmcp.Char.Base.sex) == 0) then
    chsex_string = 'neuter'
  elseif (tonumber(gmcp.Char.Base.sex) == 2) then
    chsex_string = 'female'
  end

  local pfp_filename = gmcp.Char.Base.race:lower():gsub("-", "_") .. '_'
  ..chsex_string .. '_1.png'

  --[[
        Right now all pfp filenames end in _1; at some point make it so a random default number for them
        can be chosen based on how many exist, and that this will persist across sessions for the profile.
  ]]--

  -- display(gmcp.Char.Base.race:lower():gsub("-", "_"))
  -- display(pfp_filename)
  -- Replace the below with your avatar filename and uncomment the below line if you want a custom avatar. Should
  -- be a 160 x 200 px .png in the ms_path + /avatars/ directory
  -- pfp_filename = my_custom_avatar_filename.png'

  resetBackgroundImage("CharsheetPFPConsole")
  local char_image = ms_path .. '/avatars/' .. pfp_filename
  local def_image = ms_path .. '/avatars/' .. 'default_char.png'

  if file_exists(char_image) then
        CharsheetPFPConsole:setBackgroundImage(char_image,"border")
  else
        CharsheetPFPConsole:setBackgroundImage(def_image,"border")
  end

  --CharsheetPFPConsole:setBackgroundImage( [[
  --  background-image: url(]] .. ms_path .. '/avatars/' .. pfp_filename .. [[);
  --  background-position: top left;
  --  background-repeat: no-repeat;
  --]],
  --"style")

CharsheetConsole:cecho(
    "<white>"
    ..string.format("              Name:  <ansi_white>%s\n",
        gmcp.Char.Base.name)
    ..string.format("              <white>Race:  <ansi_white>%s",
        gmcp.Char.Base.race)
    .."<reset>\n"
 )

 if (gmcp.Char.Base.subclass == "none") then
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("              <white>Class: <ansi_white>%s",
            gmcp.Char.Base.class)
        .."<reset>\n"
    )
else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("              <white>Class: <ansi_white>%s",
            gmcp.Char.Base.subclass)
        .."<reset>\n"
    )
end

CharsheetConsole:cecho(
    "<white>"
    ..string.format("              <white>Level: <ansi_white>%d <white>Sex: <ansi_white>%s\n\n",
        gmcp.Char.Worth.level, firstToUpper(chsex_string))
    ..string.format("              <white>Str: <cyan>%s<reset>(<ansi_cyan>%s<reset>)",
        gmcp.Char.Stats.str_mod,
        gmcp.Char.Stats.str)
    ..string.format(" <white>Int: <cyan>%s<reset>(<ansi_cyan>%s<reset>)\n",
        gmcp.Char.Stats.int_mod,
        gmcp.Char.Stats.int)
    ..string.format("              <white>Wis: <cyan>%s<reset>(<ansi_cyan>%s<reset>)",
        gmcp.Char.Stats.wis_mod,
        gmcp.Char.Stats.wis)
    ..string.format(" <white>Dex: <cyan>%s<reset>(<ansi_cyan>%s<reset>)\n",
        gmcp.Char.Stats.dex_mod,
        gmcp.Char.Stats.dex)
    ..string.format("              <white>Con: <cyan>%s<reset>(<ansi_cyan>%s<reset>)",
        gmcp.Char.Stats.con_mod,
        gmcp.Char.Stats.con)
    ..string.format(" <white>Fame: <cyan>%s<reset>\n",
        gmcp.Char.Stats.fame)

    .."<reset>"
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

    .."<reset>\n"
  )

  if (gmcp.Char.Base.class) == "Smithy"
  or (gmcp.Char.Base.subclass) == "Runesmith"
  or (gmcp.Char.Base.subclass) == "Engineer" then
      CharsheetConsole:cecho(
        string.format("Mat: <white>S: <light_steel_blue>%-3d<white> T: <ansi_yellow>%-3d<white>A: <yellow>%-3d<white>E: <white>%-3d<white>S: <red>%-3d",
          gmcp.Char.Worth.steel,
          gmcp.Char.Worth.titanium,
          gmcp.Char.Worth.adamantite,
          gmcp.Char.Worth.electrum,
          gmcp.Char.Worth.starmetal)
        .."<reset>"
      )
  end
end