function build_charsheet_box()
        if DD_GUI.CharsheetTopRow and DD_GUI.CharsheetTopRow.hide then
          DD_GUI.CharsheetTopRow:hide()
        end

        if CharsheetLabel and CharsheetLabel.hide then
          CharsheetLabel:hide()
        end

        DD_GUI.CharsheetTopRow = nil
        CharsheetLabel = nil
end
