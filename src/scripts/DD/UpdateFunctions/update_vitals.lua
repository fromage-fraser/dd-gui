debug.setmetatable(nil, { __index=function () end })

function update_vitals()
  --GUI.Hitpoints:setValue((100/tonumber(gmcp.Char.Vitals.maxhp))*tonumber(gmcp.Char.Vitals.hp),100,tonumber(gmcp.Char.Vitals.hp))
  DD_GUI.Hitpoints:setValue(((gmcp.Char.Vitals.hp * 1000) / gmcp.Char.Vitals.maxhp),1000)
  DD_GUI.Mana:setValue(((gmcp.Char.Vitals.mana * 1000) / gmcp.Char.Vitals.maxmana),1000)
  DD_GUI.Moves:setValue(((gmcp.Char.Vitals.move * 1000) / gmcp.Char.Vitals.maxmove),1000)
  DD_GUI.Xp:setValue(((gmcp.Char.Worth.xp * 1000) / gmcp.Char.Worth.maxxp), 1000)

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
    ..string.format(" <white>Fame: <cyan>%s<reset>\n\n",
        gmcp.Char.Stats.fame)

    .."<reset>\n"
)

if (tonumber(gmcp.Char.Worth.alignment) ~= 50000) then
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("<white>Alignment: <cyan>%s   <white>",
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
        ..string.format("Save vs Magic: <cyan>%s\n",
            gmcp.Char.Stats.save_vs)
        .."<reset>\n"
    )
else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("Save vs Magic: <cyan>??\n")
        .."<reset>\n"
    )
end


if (tonumber(gmcp.Char.Stats.hitroll) ~= 50000) then
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("<white>Hit roll: <red>%s<reset>  <white>Dam roll: <red>%s<reset>",
            gmcp.Char.Stats.hitroll,
            gmcp.Char.Stats.damroll)
    )
else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("<white>Hit roll: <red>??<reset>  <white>Dam roll: <red>??<reset>")
    )
end

if (tonumber(gmcp.Char.Stats.ac) ~= 50000) then
    CharsheetConsole:cecho(
    "<white>"
    ..string.format("  A/C: <red>%s<reset>\n\n",
    gmcp.Char.Stats.ac)
    )
else
    CharsheetConsole:cecho(
        "<white>"
        ..string.format("  A/C: <red>??<reset>\n\n")
    )
end

CharsheetConsole:cecho(
    "<white>"
    ..string.format("<white>P: <light_steel_blue>%d<white>  G: <yellow>%d<reset>  <white>S: <DimGrey>%d<reset>  <white>C: <ansi_yellow>%d<reset>\n",
        gmcp.Char.Worth.platinum,
        gmcp.Char.Worth.gold,
        gmcp.Char.Worth.silver,
        gmcp.Char.Worth.copper)

    .."<reset>\n"
  )

  if (gmcp.Char.Base.class) == "Smithy"
  or (gmcp.Char.Base.class) == "Runesmith"
  or (gmcp.Char.Base.class) == "Engineer" then
      CharsheetConsole:cecho(
        string.format("<white>St: <light_steel_blue>%d<white>  Ti: <ansi_yellow>%d<reset>  <white>Ad: <yellow>%d<reset>  <white>El: <white>%d<reset>  <white>Sm: <red>%d<reset>\n",
          gmcp.Char.Worth.steel,
          gmcp.Char.Worth.titanium,
          gmcp.Char.Worth.adamantite,
          gmcp.Char.Worth.electrum,
          gmcp.Char.Worth.starmetal)

        .."<reset>\n"
      )
  end
end