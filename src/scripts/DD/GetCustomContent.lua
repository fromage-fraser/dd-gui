function get_custom_content ()
        local lfs = require "lfs"
        -- This script generates a list of all custom content files: https://www.dragons-domain.org/main/gui/custom/files.php
        local filelist = getMudletHomeDir() .. "/DD_GUI/custom_filelist.txt"
        local filelist_url = 'https://www.dragons-domain.org/main/gui/custom/files.php'

        downloadFile(filelist, filelist_url)
        cecho("\n<white>Downloading any new custom content...\n")   
end

function get_filelist_files ()
        local filelist = getMudletHomeDir() .. "/DD_GUI/custom_filelist.txt"
        if (file_exists(filelist)) then
                local lines = {}
                lines = lines_from(filelist)
                --cecho("\n<white>Updating custom content...\n")
                for k,v in pairs(lines) do
                        local result = split_str(v, '|')
                        --result[1] now holds the file size, result[2] holds the file name
                        --display("Remote file size: " .. result[1] .. " for " .. result[2])
                        local saveto = getMudletHomeDir().."/DD_GUI/" .. result[2]
                        local filesize_v = lfs.attributes (saveto, "size")
                        
                        local url = "https://www.dragons-domain.org/main/gui/custom/" .. result[2]
                        
                        if (file_exists(saveto)) and (tonumber(result[1]) ~= tonumber(filesize_v)) then
                            --cecho("File exists locally BUT IS DIFFERENT SIZE for " .. result[2] .. "\n")
                                downloadFile(saveto, url)
                        end
                        
                        if (filesize_v == nil) then
                          --cecho("File does not exist locally for " .. result[2] .. "\n")
                                downloadFile(saveto, url)
                        end
                end
        else
          cecho("\n<white>Custom file filelist doesn't exist!<reset>\n")       
        end
end

registerAnonymousEventHandler("sysDownloadDone", "get_filelist_files")