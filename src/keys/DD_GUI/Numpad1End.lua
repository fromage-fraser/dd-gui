if DD_GUI and DD_GUI.compass_press then
  DD_GUI.compass_press("sw")
else
  send("scan")
end
