timerid = 1
timerid2 = 1

function get_custom_content()
    killTimer(timerid)
    killTimer(timerid2)
    local timerid = nil
    local timerid2 = nil
    local lfs = require "lfs"
    local filelist = getMudletHomeDir() .. "/DD_GUI/custom_filelist.txt"
    local filelist_url = 'https://www.dragons-domain.org/main/gui/custom/files.php'
    local lines = {}

    cecho("\n\n<white>Checking for new custom content...\n")
    downloadFile(filelist, filelist_url)
    timerid = tempTimer(3,
      function()
        if (file_exists(filelist)) then
          lines = lines_from(filelist)
        else
          cecho("\n<white>Custom content unable to be checked.\n")
          return
        end

        -- A table to store the results of each download
        local results = {}
        local dl_count = 0

        for k,v in pairs(lines) do
          --display("k: " .. k .. " v: " .. v)
          local result = split_str(v, '|')
          --result[1] now holds the file size, result[2] holds the file name
          --display("Remote file size: " .. result[1] .. " for " .. result[2] .. "\n")
          local saveto = getMudletHomeDir().."/DD_GUI/" .. result[2]
          local filesize_v = lfs.attributes (saveto, "size")
          local url = "https://www.dragons-domain.org/main/gui/custom/" .. result[2]

          if (file_exists(saveto)) and (tonumber(result[1]) ~= tonumber(filesize_v)) then
              --cecho("File exists locally BUT IS DIFFERENT SIZE for " .. result[2] .. "\n")
              --cecho("Downloading: " .. saveto .. "\n")
              local success = downloadFile(saveto, url)
              dl_count = dl_count + 1
              results[k] = { url = url, path = saveto, success = success }
          end

          if (filesize_v == nil) then
              --cecho("File does not exist locally for " .. result[2] .. "\n")
              --cecho("Downloading: " .. saveto .. "\n")
              local success = downloadFile(saveto, url)
              dl_count = dl_count + 1
              results[k] = { url = url, path = saveto, success = success }
          end
        end

        -- Print the results of each download
        if (dl_count == nil) then
          dl_count = 0
        end

        if (tonumber(dl_count) > 0) then
          cecho("\n<white>Found new custom content to download.\n")
          for i, result in pairs(results) do
            if (result.success == true) then
              local message = string.format("<white>Downloaded:<red> %s\n", result.url)
              cecho("" .. message)
            end
          end
        else
          cecho("\n<white>No new custom content to download.\n")
        end
      end
      )
      timerid2 = tempTimer( 5,
      function()
        update_travel()
        installPackage("https://github.com/demonnic/EMCO/releases/latest/download/EMCOChat.mpackage")
      end
      )
  end

--registerAnonymousEventHandler("sysDownloadDone", "get_filelist_files")