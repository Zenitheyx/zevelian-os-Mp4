-- ZEVELIAN MUSIC
-- Standalone CC:Tweaked music-file library.
-- Designed to work with a Speaker peripheral when available.
-- Accepts direct audio-file URLs; it does not extract audio from streaming sites.

local DB = "zevelian_music.db"
local function clear() term.clear(); term.setCursorPos(1,1) end

local function loadLibrary()
  if not fs.exists(DB) then return {} end
  local h = fs.open(DB, "r")
  local data = textutils.unserialize(h.readAll())
  h.close()
  return type(data) == "table" and data or {}
end

local function saveLibrary(list)
  local h = fs.open(DB, "w")
  h.write(textutils.serialize(list))
  h.close()
end

local function findSpeaker()
  local name = peripheral.find("speaker")
  return name
end

local function addTrack(list)
  clear()
  print("ZEVELIAN MUSIC // ADD TRACK")
  print("")
  print("Paste a direct audio-file URL.")
  print("Examples: .dfpwm, .ogg, .wav, .mp3")
  print("")
  write("> ")
  local url = read()
  if not url or url == "" then return end

  if not url:match("^https?://") then
    print("Invalid URL.")
    sleep(1.5)
    return
  end

  print("")
  write("Name: ")
  local name = read()
  if not name or name == "" then
    name = url:match("([^/?#]+)") or "Untitled"
  end

  table.insert(list, {name=name, url=url})
  saveLibrary(list)

  print("")
  print("Added to library.")
  sleep(1.5)
end

local function listTracks(list)
  clear()
  print("ZEVELIAN MUSIC // LIBRARY")
  print("")

  if #list == 0 then
    print("Your library is empty.")
    print("")
    print("Press Enter.")
    read()
    return
  end

  for i, track in ipairs(list) do
    print(("%d. %s"):format(i, track.name))
    print("   " .. track.url)
  end

  print("")
  print("Press Enter.")
  read()
end

local function removeTrack(list)
  clear()
  print("ZEVELIAN MUSIC // REMOVE")
  print("")

  if #list == 0 then
    print("Library is empty.")
    sleep(1)
    return
  end

  for i, track in ipairs(list) do
    print(("%d. %s"):format(i, track.name))
  end

  print("")
  write("Track number (blank = cancel): ")
  local n = tonumber(read())
  if n and list[n] then
    table.remove(list, n)
    saveLibrary(list)
    print("Removed.")
    sleep(1)
  end
end

local function downloadTrack(track)
  clear()
  print("ZEVELIAN MUSIC // DOWNLOAD")
  print("")
  print(track.name)
  print("")

  if not http then
    print("HTTP is unavailable.")
    sleep(2)
    return
  end

  local response, err = http.get(track.url, nil, true)
  if not response then
    print("Could not download:")
    print(tostring(err))
    sleep(2)
    return
  end

  local safe = track.name:gsub("[^%w%._%-]", "_")
  if not safe:lower():match("%.[%w]+$") then safe = safe .. ".audio" end

  local h = fs.open(safe, "wb")
  if not h then
    response.close()
    print("Could not create file.")
    sleep(2)
    return
  end

  local total = 0
  while true do
    local chunk = response.read(8192)
    if not chunk then break end
    h.write(chunk)
    total = total + #chunk
  end
  h.close()
  response.close()

  print("Saved: " .. safe)
  print("Size: " .. math.floor(total / 1024) .. " KB")
  print("")
  print("Note: downloading a file does not guarantee")
  print("that CC:Tweaked can decode its audio format.")
  print("")
  print("Press Enter.")
  read()
end

local function playDFPWM(path, speaker)
  if not fs.exists(path) then
    print("File not found.")
    return
  end

  if not speaker then
    print("No Speaker peripheral detected.")
    return
  end

  -- CC:Tweaked Speaker playback requires DFPWM audio.
  local decoder = require("cc.audio.dfpwm").make_decoder()
  local h = fs.open(path, "rb")

  while true do
    local chunk = h.read(16 * 1024)
    if not chunk then break end
    local buffer = decoder(chunk)
    while not speaker.playAudio(buffer) do
      os.pullEvent("speaker_audio_empty")
    end
  end

  h.close()
end

local function playMenu(list)
  clear()
  print("ZEVELIAN MUSIC // PLAY")
  print("")

  if not findSpeaker() then
    print("No Speaker peripheral detected.")
    print("")
    print("A Speaker is required for audio output.")
    print("The current computer can still manage")
    print("your music library without one.")
    print("")
    print("Press Enter.")
    read()
    return
  end

  print("Available library tracks:")
  for i, track in ipairs(list) do
    print(("%d. %s"):format(i, track.name))
  end

  print("")
  write("Track number: ")
  local n = tonumber(read())
  if not n or not list[n] then return end

  clear()
  print("Playing: " .. list[n].name)
  print("")
  print("Playback currently supports CC:Tweaked")
  print("DFPWM audio files.")
  print("")

  local safe = list[n].name:gsub("[^%w%._%-]", "_")
  if fs.exists(safe) then
    playDFPWM(safe, findSpeaker())
  else
    print("Download the track first.")
  end

  print("")
  print("Press Enter.")
  read()
end

local list = loadLibrary()

while true do
  clear()
  print("================================")
  print("       ZEVELIAN MUSIC")
  print("================================")
  print("")
  print("1. Add music URL")
  print("2. Music library")
  print("3. Download a track")
  print("4. Play DFPWM track")
  print("5. Remove track")
  print("6. Hardware status")
  print("7. Exit")
  print("")
  write("> ")
  local choice = read()

  if choice == "1" then
    addTrack(list)
  elseif choice == "2" then
    listTracks(list)
  elseif choice == "3" then
    clear()
    print("DOWNLOAD TRACK")
    print("")
    for i, track in ipairs(list) do
      print(("%d. %s"):format(i, track.name))
    end
    print("")
    write("Track number: ")
    local n = tonumber(read())
    if n and list[n] then downloadTrack(list[n]) end
  elseif choice == "4" then
    playMenu(list)
  elseif choice == "5" then
    removeTrack(list)
  elseif choice == "6" then
    clear()
    print("HARDWARE STATUS")
    print("")
    local speaker = findSpeaker()
    if speaker then
      print("Speaker: ONLINE")
    else
      print("Speaker: NOT DETECTED")
    end
    print("")
    print("Press Enter.")
    read()
  elseif choice == "7" then
    clear()
    return
  end
end
