-- ZEVELIAN VIDEO GET
-- Standalone CC:Tweaked direct-MP4 downloader.
-- Downloads only direct .mp4 URLs that the server permits.

local function clear()
  term.clear()
  term.setCursorPos(1, 1)
end

local function say(msg)
  print(tostring(msg))
end

local function filenameFromURL(url)
  local clean = url:match("([^?]+)") or url
  local name = clean:match("([^/]+)$")
  if not name or name == "" then
    return "video.mp4"
  end
  name = name:gsub("[^%w%._%-]", "_")
  if not name:lower():match("%.mp4$") then
    name = name .. ".mp4"
  end
  return name
end

local function downloadMP4(url, path)
  local response, err = http.get(url, nil, true)
  if not response then
    return false, "Could not connect: " .. tostring(err or "unknown error")
  end

  local headers = response.getResponseHeaders and response.getResponseHeaders() or {}
  local contentType = ""
  for k, v in pairs(headers) do
    if tostring(k):lower() == "content-type" then
      contentType = tostring(v):lower()
      break
    end
  end

  local lowerURL = url:lower()
  local looksLikeMP4 = lowerURL:match("%.mp4([?#].*)?$") ~= nil
  local isMP4Type = contentType:match("video/mp4") ~= nil

  if not looksLikeMP4 and not isMP4Type then
    response.close()
    return false, "That URL does not appear to be a direct MP4 file."
  end

  local handle = fs.open(path, "wb")
  if not handle then
    response.close()
    return false, "Could not create " .. path
  end

  local total = tonumber(headers["Content-Length"] or headers["content-length"])
  local received = 0
  local chunkSize = 8192

  while true do
    local chunk = response.read(chunkSize)
    if not chunk then break end
    handle.write(chunk)
    received = received + #chunk

    term.clearLine()
    term.setCursorPos(1, select(2, term.getCursorPos()))
    if total and total > 0 then
      local pct = math.floor((received / total) * 100)
      local width = 30
      local filled = math.floor(width * received / total)
      print(("Downloading: [%s%s] %3d%%")
        :format(string.rep("#", filled), string.rep("-", width - filled), pct))
    else
      print(("Downloading: %d KB"):format(math.floor(received / 1024)))
    end
  end

  response.close()
  handle.close()

  if received <= 0 then
    fs.delete(path)
    return false, "The server returned an empty file."
  end

  return true, received
end

clear()
say("==============================================")
say("           ZEVELIAN VIDEO GET")
say("==============================================")
say("")
say("Direct MP4 downloader for CC:Tweaked")
say("Only use videos you have permission to download.")
say("")

if not http then
  say("HTTP is unavailable on this computer.")
  say("Enable HTTP in the CC:Tweaked computer settings.")
  return
end

say("Enter a direct .mp4 URL:")
write("> ")
local url = read()

if not url or url == "" then
  say("No URL entered.")
  return
end

if not url:match("^https?://") then
  say("Invalid URL. It must start with http:// or https://")
  return
end

say("")
say("Checking URL...")

local defaultName = filenameFromURL(url)
say("")
say("Filename [" .. defaultName .. "]:")
write("> ")
local entered = read()
local filename = (entered and entered ~= "") and entered or defaultName

if not filename:lower():match("%.mp4$") then
  filename = filename .. ".mp4"
end

filename = filename:gsub("[^%w%._%-]", "_")

if fs.exists(filename) then
  say("")
  say(filename .. " already exists.")
  say("Overwrite? (y/n)")
  write("> ")
  if read():lower() ~= "y" then
    say("Cancelled.")
    return
  end
  fs.delete(filename)
end

say("")
say("Starting download...")
say("")

local ok, result = downloadMP4(url, filename)

if not ok then
  say("")
  say("DOWNLOAD FAILED")
  say(result)
  return
end

say("")
say("==============================================")
say("DOWNLOAD COMPLETE")
say("==============================================")
say("Saved: " .. filename)
say("Size: " .. math.floor(result / 1024) .. " KB")
say("")
say("Press Enter to exit.")
read()
