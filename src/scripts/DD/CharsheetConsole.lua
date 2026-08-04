function build_charsheet_console()

    CharsheetConsole = Geyser.MiniConsole:new({
      name="CharsheetConsole",
      x = "2%", y = "0%",
      width="96%",
      height="100%",
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
      DD_GUI.Theme:image_frame_css() or [[border: 1px solid grey;]])
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

    local pfp_path = ms_path .. '/avatars/' .. pfp_filename
    local default_path = ms_path .. '/avatars/default_char.png'
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
end
