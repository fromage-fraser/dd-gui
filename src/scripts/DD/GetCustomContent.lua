DD_GUI = DD_GUI or {}

local function looks_like_file(relPath)
  -- has a basename with a dot extension and does not end with '/'
  return relPath:match("[^/]+%.[^/]+$") ~= nil
end

-- Globals / constants
local lfs = require "lfs"

downloadQueue = DD_GUI.content_download_queue or downloadQueue or {}
DD_GUI.content_download_queue = downloadQueue
isDownloadingFileList = DD_GUI.content_download_list_active == true
local active_download_path = DD_GUI.content_download_path

-- Large first-run content sets can contain thousands of files. Keep one
-- request active and yield between completion callbacks so the client can
-- continue painting and processing input. Persist the state on DD_GUI so a
-- package reload can replace handlers without losing the queue.
local CONTENT_DOWNLOAD_DELAY = 0.05

local function set_list_download_active(active)
  isDownloadingFileList = active == true
  DD_GUI.content_download_list_active = isDownloadingFileList
end

local function set_active_download(path)
  active_download_path = path
  DD_GUI.content_download_path = path
end

local function clear_content_download_queue()
  downloadQueue = {}
  DD_GUI.content_download_queue = downloadQueue
end

local function schedule_next_download(delay)
  if DD_GUI.content_download_timer then
    return
  end

  if type(tempTimer) ~= "function" then
    start_next_download()
    return
  end

  DD_GUI.content_download_timer = tempTimer(
    delay or CONTENT_DOWNLOAD_DELAY,
    function()
      DD_GUI.content_download_timer = nil
      start_next_download()
    end
  )
end

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

local environment_assets = {
  [0] = "0_sect_inside.png",
  [1] = "1_sect_city.png",
  [2] = "2_sect_field.png",
  [3] = "3_sect_forest.png",
  [4] = "4_sect_hills.png",
  [5] = "5_sect_mountain.png",
  [6] = "6_sect_water_swim.png",
  [7] = "7_sect_water_noswim.png",
  [8] = "8_sect_underwater.png",
  [9] = "9_sect_air.png",
  [10] = "10_sect_desert.png",
  [11] = "11_sect_swamp.png",
  [12] = "12_sect_underwater_ground.png",
}

local function room_asset_name(name)
  return tostring(name or ""):lower()
    :gsub("/", "_")
    :gsub(" ", "_")
    :gsub("'", "_")
    :gsub("<", "_")
    :gsub(">", "_")
    :gsub("{", "_")
end

local function enemy_asset_name(name)
  return tostring(name or ""):lower()
    :gsub(" ", "_")
    :gsub("'", "_")
end

local function character_asset_name(name)
  return tostring(name or ""):lower()
    :gsub("[^%w]+", "_")
    :gsub("^_+", "")
    :gsub("_+$", "")
end

local function add_exact_priority(exact, path, priority)
  if path == "" then
    return
  end

  if exact[path] == nil or priority < exact[path] then
    exact[path] = priority
  end
end

local function current_content_prefixes()
  local exact = {}
  local prefixes = {}
  local signature = {}
  local character = gmcp and gmcp.Char
  local room = gmcp and gmcp.Room and gmcp.Room.Info
  if type(room) == "table" then
    local room_vnum = tonumber(room.vnum)
    signature[#signature + 1] = "room:" .. tostring(room_vnum or "")
    signature[#signature + 1] = tostring(room.name or "")
    signature[#signature + 1] = tostring(room.sector or "")
    if room_vnum and room_vnum ~= 0 then
      prefixes[#prefixes + 1] = {
        value = "custom_rooms/" .. room_vnum .. "_",
        priority = 1,
      }
    end

    local sector = tonumber(room.sector)
    if environment_assets[sector] then
      add_exact_priority(exact, "environments/" .. environment_assets[sector], 2)
    end
  end

  local enemies = gmcp and gmcp.Char and gmcp.Char.Enemies
  local enemy = nil
  if type(enemies) == "table" and type(enemies[1]) == "table" then
    enemy = enemies[1]
    if enemy.name == nil and type(enemy[1]) == "table" then
      enemy = enemy[1]
    end
  end
  if type(enemy) == "table" then
    local enemy_vnum = tonumber(enemy.vnum) or tonumber(enemy.isnpc)
    signature[#signature + 1] = "enemy:" .. tostring(enemy_vnum or "")
    signature[#signature + 1] = tostring(enemy.name or "")
    if enemy_vnum and enemy_vnum ~= 0 then
      prefixes[#prefixes + 1] = {
        value = "mobs/" .. enemy_vnum .. "_",
        priority = 0,
      }
      add_exact_priority(exact,
        "mobs/" .. enemy_vnum .. "_" .. enemy_asset_name(enemy.name) .. ".png", 0)
    end
  end

  local room_name = type(room) == "table" and room.name
  local room_vnum = type(room) == "table" and tonumber(room.vnum)
  if room_vnum and room_vnum ~= 0 and room_name then
    add_exact_priority(exact,
      "custom_rooms/" .. room_vnum .. "_" .. room_asset_name(room_name) .. ".png", 0)
  end

  local base = type(character) == "table" and character.Base
  local vitals = type(character) == "table" and character.Vitals
  if type(base) == "table" then
    local character_name = character_asset_name(base.name)
    signature[#signature + 1] = "character:" .. character_name
    signature[#signature + 1] = tostring(base.race or "")
    signature[#signature + 1] = tostring(base.class or "")
    signature[#signature + 1] = tostring(base.subclass or "")
    signature[#signature + 1] = tostring(base.sex or "")
    if character_name ~= "" then
      add_exact_priority(exact, "avatars/" .. character_name .. ".png", 0)
    end

    local sex_name = "male"
    if tonumber(base.sex) == 0 then
      sex_name = "neuter"
    elseif tonumber(base.sex) == 2 then
      sex_name = "female"
    end

    local race_name = tostring(base.race or "unknown"):lower():gsub("-", "_")
    add_exact_priority(exact, "avatars/" .. race_name .. "_" .. sex_name .. "_1.png", 1)

    -- Form portraits override normal and character-named portraits in
    -- update_vitals(), so promote the active form to the front of the queue.
    local form = type(vitals) == "table" and tostring(vitals.form or ""):lower()
    signature[#signature + 1] = "form:" .. form
    if form ~= "" and form ~= "normal" then
      if tostring(base.class or "") == "Shape Shifter" or
         tostring(base.subclass or "") == "Werewolf" or
         tostring(base.subclass or "") == "Vampire" then
        add_exact_priority(exact, "avatars/" .. form .. "_form.png", -1)
      end
    end
  end

  return exact, prefixes, table.concat(signature, "|")
end

function DD_GUI.prioritize_content_queue(force)
  if type(downloadQueue) ~= "table" or #downloadQueue < 2 then
    return
  end

  local exact, prefixes, signature = current_content_prefixes()
  if not force and DD_GUI.content_download_priority_key == signature then
    return
  end
  DD_GUI.content_download_priority_key = signature

  for sequence, item in ipairs(downloadQueue) do
    local path = normalise_download_path(item.saveto or "")
    local relative = path
    local root = normalise_download_path(ms_path) .. "/"
    if relative:sub(1, #root) == root then
      relative = relative:sub(#root + 1)
    end
    relative = relative:lower()

    local priority = exact[relative] or 100
    for _, candidate in ipairs(prefixes) do
      if relative:sub(1, #candidate.value) == candidate.value then
        priority = math.min(priority, candidate.priority)
      end
    end
    item.priority = priority
    item.sequence = item.sequence or sequence
  end

  table.sort(downloadQueue, function(left, right)
    if left.priority ~= right.priority then
      return left.priority < right.priority
    end
    return left.sequence < right.sequence
  end)
  DD_GUI.content_download_queue = downloadQueue
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
    set_list_download_active(false)
    set_active_download(nil)
    process_file_list()
    return
  end

  if not is_same_download(filename, active_download_path) then
    return
  end

  set_active_download(nil)
  -- Yield to the client event loop before starting another request.
  schedule_next_download()
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
  if isDownloadingFileList and is_same_download(badFile, FILELIST_LOCAL) then
    set_list_download_active(false)
    clear_content_download_queue()
    set_active_download(nil)
    DD_GUI.content_download_active = false
    return
  end

  set_active_download(nil)
  schedule_next_download()
end

-- Kick-off
function get_custom_content()
  if DD_GUI.content_download_active or isDownloadingFileList or
     active_download_path or #downloadQueue > 0 then
    return
  end

  cecho("\n\n<white>Downloading any new custom media...\n")
  DD_GUI.content_download_active = true
  set_list_download_active(true)
  set_active_download(FILELIST_LOCAL)
  ensure_dir_for(FILELIST_LOCAL)
  downloadFile(FILELIST_LOCAL, FILELIST_URL)
end

-- Read, queue, and start
function process_file_list()
  if not file_exists(FILELIST_LOCAL) then
    cecho("\n<white>Custom media unable to be checked.\n")
    DD_GUI.content_download_active = false
    return
  end

  clear_content_download_queue()
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

  DD_GUI.prioritize_content_queue(true)
  schedule_next_download(0)
end

function start_next_download()
  if active_download_path then
    return
  end

  if #downloadQueue == 0 then
    set_active_download(nil)
    DD_GUI.content_download_active = false
    --cecho("\n<white>All downloads completed.\n")
    return
  end
  local nextDownload = table.remove(downloadQueue, 1)
  DD_GUI.content_download_queue = downloadQueue
  set_active_download(nextDownload.saveto)
  ensure_dir_for(nextDownload.saveto)
  local ok, result = pcall(downloadFile, nextDownload.saveto, nextDownload.url)
  if not ok or result == false then
    set_active_download(nil)
    schedule_next_download()
  end
end

-- Replace the previous callbacks when local source files are reloaded. Without
-- this, every reload can make one completed download advance the queue several
-- times and leave the downloader in a corrupt state.
DD_GUI.download_event_handlers = DD_GUI.download_event_handlers or {}
for _, handler_id in pairs(DD_GUI.download_event_handlers) do
  if handler_id and type(killAnonymousEventHandler) == "function" then
    pcall(killAnonymousEventHandler, handler_id)
  end
end

DD_GUI.download_event_handlers = {
  done = registerAnonymousEventHandler("sysDownloadDone", "onDownloadDone"),
  error = registerAnonymousEventHandler("sysDownloadError", "onDownloadError"),
}
