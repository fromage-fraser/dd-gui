local portal_string             = "You step into the shimmering portal..."
--[[local keylack_string            = "You lack the key."
local notclosed_string          = "It's not closed."
local alreadyopen_string        = "It's already open."
local okay_string               = "Ok."
local wall_string               = "You cannot proceed, as a wall blocks your way."
]]--

local portal_matched            = 0
--[[local keylack_matched           = 0
local notclosed_matched         = 0
local alreadyopen_matched       = 0
local okay_matched              = 0
local wall_matched              = 0
]]--

for i,v in ipairs(map.save.ignore_patterns) do 
  if (portal_string == v) then
        portal_matched = 1
  end 
--[[  if (keylack_string == v) then
        keylack_matched = 1
  end 
  if (notclosed_string == v) then
        notclosed_matched = 1
  end 
  if (alreadyopen_string == v) then
        alreadyopen_matched = 1
  end 
  if (okay_string == v) then
        okay_matched = 1
  end 
  if (wall_string == v) then
        wall_matched = 1
  end 
  ]]--
end

if (portal_matched == 0) then
        map.make_ignore_pattern(portal_string)
end
--[[
if (keylack_matched == 0) then
        map.make_ignore_pattern(keylack_string)
end

if (notclosed_matched == 0) then
        map.make_ignore_pattern(notclosed_string)
end

if (alreadyopen_matched == 0) then
        map.make_ignore_pattern(alreadyopen_string)
end

if (okay_matched == 0) then
        map.make_ignore_pattern(okay_string)
end

if (wall_matched == 0) then
        map.make_ignore_pattern(wall_string)
end
]]--
