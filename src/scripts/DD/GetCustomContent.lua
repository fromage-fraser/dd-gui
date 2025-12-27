local function looks_like_file(relPath)
  -- has a basename with a dot extension and does not end with '/'
  return relPath:match("[^/]+%.[^/]+$") ~= nil
end

-- Globals / constants
local lfs = require "lfs"

downloadQueue = downloadQueue or {}
isDownloadingFileList = false

-- Make the file list path/URL visible to all handlers
FILELIST_LOCAL = getMudletHomeDir() .. "/DD_GUI/custom_filelist.txt"
FILELIST_URL   = "https://www.dragons-domain.org/main/gui/custom/files.php"
CONTENT_BASE   = "https://www.dragons-domain.org/main/gui/custom/"

-- Ensure all parent directories for a path exist (cross-platform)
local function ensure_dir_for(path)
  local norm = path:gsub("\\", "/")
  local dir = norm:match("^(.*)/[^/]+$") or ""
  local build = dir:sub(1,1) == "/" and "/" or ""

  for part in dir:gmatch("([^/]+)") do
    if part ~= "" and part ~= "." then
      build = (build == "" or build == "/") and (build .. part) or (build .. "/" .. part)
      -- ignore mkdir errors (already exists)
      pcall(lfs.mkdir, build)
    end
  end
end

-- Event handlers
function onDownloadDone(_, filename)
  -- Was it the file list?
  if isDownloadingFileList and filename == FILELIST_LOCAL then
    isDownloadingFileList = false
    process_file_list()
    return
  end
  -- Otherwise proceed with the queue
  start_next_download()
end

function onDownloadError(badFile, reason)
  cecho(string.format("\n<white>Download failed for %s: %s\n", badFile or "<unknown>", reason or ""))
  start_next_download()
end

-- Kick-off
function get_custom_content()
  cecho("\n\n<white>Downloading any new custom media...\n")
  isDownloadingFileList = true
  ensure_dir_for(FILELIST_LOCAL)
  downloadFile(FILELIST_LOCAL, FILELIST_URL)
end

-- Read, queue, and start
function process_file_list()
  if not file_exists(FILELIST_LOCAL) then
    cecho("\n<white>Custom media unable to be checked.\n")
    return
  end

  downloadQueue = {}
  local lines = lines_from(FILELIST_LOCAL)

  for _, v in ipairs(lines) do
    local result  = split_str(v, '|')
    local sizeStr = (result[1] or ""):gsub("%s+$", "")
    local relPath = (result[2] or ""):gsub("\r", ""):gsub("^%s+", ""):gsub("%s+$", "")

    -- NEW: ignore blank lines and *directory* entries
    if relPath ~= "" and looks_like_file(relPath) then
      local saveto   = getMudletHomeDir() .. "/DD_GUI/" .. relPath
      local url      = CONTENT_BASE .. relPath
      local existing = lfs.attributes(saveto, "size")

      if (file_exists(saveto) and tonumber(sizeStr) ~= tonumber(existing)) or (existing == nil) then
        table.insert(downloadQueue, { url = url, saveto = saveto })
      end
    -- else: it's a directory or bad line — skip it
    end
  end

  start_next_download()
end

function start_next_download()
  if #downloadQueue == 0 then
    --cecho("\n<white>All downloads completed.\n")
    return
  end
  local nextDownload = table.remove(downloadQueue, 1)
  ensure_dir_for(nextDownload.saveto)           -- <-- create DD_GUI/audio/ etc.
  downloadFile(nextDownload.saveto, nextDownload.url)
end

-- Register (safe to call once at load time)
registerAnonymousEventHandler("sysDownloadDone",  "onDownloadDone")
registerAnonymousEventHandler("sysDownloadError", "onDownloadError")
