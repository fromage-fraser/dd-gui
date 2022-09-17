function file_exists(name)

        local f = io.open(name,"r")
        
        if f ~= nil then 
                io.close(f) 
                return true 
        else 
                return false 
        end
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
        if not file_exists(file) then return {} end
        local lines = {}
        for line in io.lines(file) do 
                lines[#lines + 1] = line
        end
        return lines
end