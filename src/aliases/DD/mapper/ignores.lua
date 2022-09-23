local portal_string = "You step into the shimmering portal..."
local matched = 0
for i,v in ipairs(map.save.ignore_patterns) do 
  if (portal_string == v) then
    matched = 1
  end 
end

if (matched == 0) then
  map.make_ignore_pattern(portal_string)
end
