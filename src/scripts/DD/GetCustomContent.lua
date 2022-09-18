function get_custom_content ()
        -- just test to download a file and save it in our profile folder
        -- C:\Users\goths\.config\mudlet\profiles\MuddleTest\DD_GUI\custom_rooms

        -- This is a list of all custom content files: https://smihilist.com/dd4/web/main/gui/custom/files.php
        local filelist = getMudletHomeDir() .. "/DD_GUI/custom_filelist.txt"
        local filelist_url = 'https://smihilist.com/dd4/web/main/gui/custom/files.php'

        downloadFile(filelist, filelist_url)
        cecho("\n<white>Downloading custom content...\n")
        --cecho("<white>Downloading <green>"..filelist_url.."<white> to <green>"..filelist.."\n\n")
     
end

function get_filelist_files ()
        local filelist = getMudletHomeDir() .. "/DD_GUI/custom_filelist.txt"
        if (file_exists(filelist)) then
                local lines = {}
                lines = lines_from(filelist)
                --cecho("\n<white>Updating custom content...\n")
                for k,v in pairs(lines) do
                        local saveto = getMudletHomeDir().."/DD_GUI/" .. v
                        local url = "https://smihilist.com/dd4/web/main/gui/custom/" .. v

                        if (file_exists(saveto)) then
                                cecho("") 
                        else
                                downloadFile(saveto, url)
                                --cecho("<white>Downloading <green>"..url.."\n\n")
                        end
                end      
        end
end

registerAnonymousEventHandler("sysDownloadDone", "get_filelist_files")