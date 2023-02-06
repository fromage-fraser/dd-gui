function build_charsheet_console()

    CharsheetConsole = Geyser.MiniConsole:new({
      name="CharsheetConsole",
      x = "4%", y = "13%",
      width="92%",
      height="87%",
      autoWrap = true,
      color = "black",
      scrollBar = false,
      fontSize = 10,
    }, DD_GUI.CharsheetBox)

    CharsheetPFPConsole = Geyser.MiniConsole:new({
      name="CharsheetPFPConsole",
      x = "0%", y = "0%",
      width="35%",
      height="45%",
      autoWrap = true,
      color = "black",
      scrollBar = false,
      fontSize = 10,
    }, CharsheetConsole)

    local chsex_string = 'male'

    if (gmcp.Char.Base.sex == 0) then
      chsex_string = 'neutral'
    elseif (gmcp.Char.Base.sex == 2) then
      chsex_string = 'female'
    end

    local pfp_filename = firstToLower(gmcp.Char.Base.race) .. '_'
                       ..firstToLower(gmcp.Char.Base.class) .. '_'
                       ..chsex_string .. '_1.png'
    --display(pfp_filename)

    -- Replace the below with your avatar filename and uncomment the below line if you want a custom avatar. Should
    -- be a 160 x 200 px .png in the ms_path + /avatars/ directory
    -- pfp_filename = mycustomavatar.png'

    resetBackgroundImage("CharsheetPFPConsole")
    CharsheetPFPConsole:setBackgroundImage( [[
      background-image: url(]] .. ms_path .. '/avatars/' .. pfp_filename .. [[);
      background-position: top left;
      background-repeat: no-repeat;
    ]],
    "style")
end