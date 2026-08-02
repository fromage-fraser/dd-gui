function build_enemy_box()
  if DD_GUI.EnemyTopRow and DD_GUI.EnemyTopRow.hide then
    DD_GUI.EnemyTopRow:hide()
  end

  if EnemyLabel and EnemyLabel.hide then
    EnemyLabel:hide()
  end

  DD_GUI.EnemyTopRow = nil
  EnemyLabel = nil
end
