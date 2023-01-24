if not hasFocus() then
  array={"ql","lfq"}
  local randomIndex = math.random(1, #array) -- or short math.random(#array)
  local randomElement = array[randomIndex]
  send(randomElement)
end
