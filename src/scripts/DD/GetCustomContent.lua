local function looks_like_file(relPath)
  -- has a basename with a dot extension and does not end with '/'
  return relPath:match("[^/]+%.[^/]+$") ~= nil
end

-- Globals / constants
local lfs = require "lfs"

downloadQueue = downloadQueue or {}
isDownloadingFileList = false
local active_download_path = nil

-- Make the file list path/URL visible to all handlers
FILELIST_LOCAL = ms_path .. "/custom_filelist.txt"
FILELIST_URL   = "https://www.dragons-domain.org/main/gui/custom/files.php"
CONTENT_BASE   = "https://www.dragons-domain.org/main/gui/custom/"

local function normalise_download_path(path)
  return tostring(path or ""):gsub("\\", "/")
end

local function is_dd_gui_download(path)
  local candidate = normalise_download_path(path)
  local root = normalise_download_path(ms_path)

  if candidate == "" or root == "" then
    return false
  end

  return candidate == root or candidate:sub(1, #root + 1) == root .. "/"
end

local function is_same_download(path_a, path_b)
  return normalise_download_path(path_a) == normalise_download_path(path_b)
end

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
  if not is_dd_gui_download(filename) then
    return
  end

  -- Was it the file list?
  if isDownloadingFileList and is_same_download(filename, FILELIST_LOCAL) then
    isDownloadingFileList = false
    active_download_path = nil
    process_file_list()
    return
  end

  if not is_same_download(filename, active_download_path) then
    return
  end

  active_download_path = nil
  -- Otherwise proceed with the queue
  start_next_download()
end

function onDownloadError(badFile, reason)
  if not is_dd_gui_download(badFile) then
    return
  end

  if isDownloadingFileList and not is_same_download(badFile, FILELIST_LOCAL) then
    return
  end

  if not isDownloadingFileList and not is_same_download(badFile, active_download_path) then
    return
  end

  cecho(string.format("\n<white>Download failed for %s: %s\n", badFile or "<unknown>", reason or ""))
  isDownloadingFileList = false
  active_download_path = nil
  start_next_download()
end

-- Kick-off
function get_custom_content()
  cecho("\n\n<white>Downloading any new custom media...\n")
  isDownloadingFileList = true
  active_download_path = FILELIST_LOCAL
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
      local saveto   = ms_path .. "/" .. relPath
      local url      = CONTENT_BASE .. relPath
      local existing_path = DD_GUI.asset_path and
        DD_GUI.asset_path(relPath) or saveto
      local existing = lfs.attributes(existing_path, "size")

      if existing == nil or tonumber(sizeStr) ~= tonumber(existing) then
        table.insert(downloadQueue, { url = url, saveto = saveto })
      end
    -- else: it's a directory or bad line — skip it
    end
  end

  start_next_download()
end

function start_next_download()
  if #downloadQueue == 0 then
    active_download_path = nil
    --cecho("\n<white>All downloads completed.\n")
    return
  end
  local nextDownload = table.remove(downloadQueue, 1)
  active_download_path = nextDownload.saveto
  ensure_dir_for(nextDownload.saveto)
  downloadFile(nextDownload.saveto, nextDownload.url)
end

-- Register (safe to call once at load time)
registerAnonymousEventHandler("sysDownloadDone",  "onDownloadDone")
registerAnonymousEventHandler("sysDownloadError", "onDownloadError")
