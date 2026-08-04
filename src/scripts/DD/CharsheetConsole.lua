function build_charsheet_console()

    CharsheetConsole = Geyser.MiniConsole:new({
      name="CharsheetConsole",
      x = "4%", y = "8%",
      width="92%",
      height="92%",
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
end
