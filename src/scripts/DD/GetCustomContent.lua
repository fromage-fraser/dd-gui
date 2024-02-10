-- Global download queue
downloadQueue = {}
isDownloadingFileList = false

-- Event handler for download completion
function onDownloadDone(_, filename)
    if isDownloadingFileList == true and filename == filelist then
        -- This was the file list download completion, so do nothing here.
        -- The actual processing and starting of the queue downloads are handled elsewhere.
        isDownloadingFileList = false -- Reset the flag
    else
        --cecho("\n<white>Download completed for: " .. filename .. "\n")
        start_next_download() -- Start next download from the queue
    end
end

-- Event handler for download errors
function onDownloadError(_, reason)
    cecho("\n<white>Download failed: " .. reason .. "\n")
    start_next_download() -- Attempt to start next download even if one fails
end

-- Assuming these are defined at a higher level
function get_custom_content()
    local lfs = require "lfs"
    local filelist = getMudletHomeDir() .. "/DD_GUI/custom_filelist.txt"
    local filelist_url = 'https://www.dragons-domain.org/main/gui/custom/files.php'

    cecho("\n\n<white>Downloading any new custom media...\n")
    downloadFile(filelist, filelist_url)

    function onFileListDownloadDone(_, filename)
        if filename == filelist then -- Check if the downloaded file is the file list
            process_file_list() -- A new function to process the downloaded file list
        end
    end

    -- New function to process the downloaded file list and populate the download queue
    function process_file_list()
        if not file_exists(filelist) then
            cecho("\n<white>Custom media unable to be checked.\n")
            return
        end

        local lines = lines_from(filelist)
        -- Reset the download queue for fresh population
        downloadQueue = {}

        for _, v in ipairs(lines) do
            local result = split_str(v, '|')
            local saveto = getMudletHomeDir().."/DD_GUI/" .. result[2]
            local filesize_v = lfs.attributes(saveto, "size")
            local url = "https://www.dragons-domain.org/main/gui/custom/" .. result[2]

            if (file_exists(saveto) and tonumber(result[1]) ~= tonumber(filesize_v)) or (filesize_v == nil) then
                -- Add to download queue instead of downloading immediately
                table.insert(downloadQueue, {url = url, saveto = saveto})
            end
        end
        --display(downloadQueue)
        -- Start the first download
        start_next_download()
    end
end

function start_next_download()
    if #downloadQueue == 0 and isDownloadingFileList == false then
        --cecho("\n<white>All downloads completed.\n")
        -- Trigger any post-download actions here
        return
    end

    local nextDownload = table.remove(downloadQueue, 1) -- Get the next download
    downloadFile(nextDownload.saveto, nextDownload.url)
end

-- Register the event handlers
registerAnonymousEventHandler("sysDownloadDone", "onDownloadDone")
registerAnonymousEventHandler("sysDownloadDone", "onFileListDownloadDone")
registerAnonymousEventHandler("sysDownloadError", "onDownloadError")

