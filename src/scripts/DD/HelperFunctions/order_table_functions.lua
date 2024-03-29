--[[
Ordered table iterator, allow to iterate on the natural order of the keys of a
table.

Example:
]]

function getKeysSortedByValue(tbl, sortFunction)
    local keys = {}
    for key in pairs(tbl) do
            table.insert(keys, key)
    end

    table.sort(keys, function(a, b)
            return sortFunction(tbl[a], tbl[b])
    end)

    return keys
end

function dump(o)
    if type(o) == 'table' then
            local s = '{ '
            for k,v in pairs(o) do
                    if type(k) ~= 'number' then k = '"'..k..'"' end
                    s = s .. '['..k..'] = ' .. dump(v) .. ','
            end
            return s .. '} '
    else
            return tostring(o)
    end
end

function __genOrderedIndex( t )
    local orderedIndex = {}
    for key in pairs(t) do
      table.insert( orderedIndex, key )
    end
    table.sort( orderedIndex )
    return orderedIndex
end

function orderedNext(t, state)
    -- Equivalent of the next function, but returns the keys in the alphabetic
    -- order. We use a temporary ordered key table that is stored in the
    -- table being iterated.

    local key = nil
    --print("orderedNext: state = "..tostring(state) )
    if state == nil then
            -- the first time, generate the index
            t.__orderedIndex = __genOrderedIndex( t )
            key = t.__orderedIndex[1]
    else
    -- fetch the next value
            for i = 1,table.getn(t.__orderedIndex) do
                    if t.__orderedIndex[i] == state then
                            key = t.__orderedIndex[i+1]
                    end
            end
    end

    if key then
            return key, t[key]
    end

    -- no more value to return, cleanup
    t.__orderedIndex = nil
    return
end

function orderedPairs(t)
    -- Equivalent of the pairs() function on tables. Allows to iterate
    -- in order
    return orderedNext, t, nil
end
