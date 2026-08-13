function replace_char(pos, str, r)
        str = tostring(str or "")
        r = tostring(r or "")
        return table.concat{str:sub(1,pos-1), r, str:sub(pos+1)}
end
    
function split_str (inputstr, sep)
        inputstr = tostring(inputstr or "")
        if sep == nil then
                sep = "%s"
        end
        local t={}
        for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
                table.insert(t, str)
        end
        return t
end
    
function firstToUpper(str)
        return (tostring(str or ""):gsub("^%l", string.upper))
end

function firstToLower(str)
        return (tostring(str or ""):gsub("^%u", string.lower))
end
