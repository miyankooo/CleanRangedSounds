-- Checks the first-run welcome line and its settings link in UI/Welcome.lua against stubs of the client. Run from the
-- repo root: lua Tests/Welcome.lua
C_AddOns = { GetAddOnMetadata = function() return "Clean Ranged Sounds" end }
MuteSoundFile, UnmuteSoundFile = function() end, function() end
SETTINGS = "Settings"
NORMAL_FONT_COLOR = { WrapTextInColorCode = function(_, text) return "<gold>" .. text .. "</gold>" end }
LinkTypes = { AddOn = "addon" }
-- Blizzard's own formatter (LinkUtil.lua).
LinkUtil = {
  FormatLink = function(linkType, text, ...)
    return table.concat({ ("|H%s"):format(linkType), ... }, ":") .. ("|h%s|h"):format(text)
  end,
}
local SECRET = {}
issecretvalue = function(value) return value == SECRET end

local onLoaded, onLogin, onItemRef
EventUtil = {
  ContinueOnAddOnLoaded = function(_, callback) onLoaded = callback end,
  ContinueOnPlayerLogin = function(callback) onLogin = callback end,
}
EventRegistry = {
  RegisterCallback = function(_, event, callback, owner)
    if event == "SetItemRef" then onItemRef = function(...) callback(owner, ...) end end
  end,
}

local failures = 0
local function Check(label, condition)
  print((condition and "  pass  " or "  FAIL  ") .. label)
  if not condition then failures = failures + 1 end
end

-- Loads the addon on a fresh client, returning the chat lines of the load and of the login, and the addon table.
local function Login(savedVariables)
  CleanRangedSoundsDB = savedVariables
  local ns = {}
  assert(loadfile("Core/Sounds.lua"))("CleanRangedSounds", ns)
  assert(loadfile("UI/Welcome.lua"))("CleanRangedSounds", ns)

  local loadLines, loginLines, realPrint = {}, {}, print
  print = function(line) table.insert(loadLines, line) end
  onLoaded()
  print = function(line) table.insert(loginLines, line) end
  onLogin()
  print = realPrint
  return loadLines, loginLines, ns
end

local loadLines, lines, ns = Login(nil)
Check("the first load prints nothing", #loadLines == 0)
Check("the first login prints one line", #lines == 1)
Check("it says what the addon does, with the gold Settings link and /crs", lines[1] == "<gold>[Clean Ranged Sounds]"
  .. "</gold>: Mutes the bow creak before each shot and any other bow, crossbow or gun sound you pick. Open the "
  .. "<gold>|Haddon:CleanRangedSounds|h[Settings]|h</gold> or type /crs to choose which sounds play.")

local opened = 0
ns.OpenSettings = function() opened = opened + 1 end
onItemRef("addon:CleanRangedSounds", "[Settings]", "LeftButton")
Check("a click on the link opens the settings", opened == 1)
onItemRef("addon:OtherAddon", "[Other]", "LeftButton")
onItemRef(SECRET, "[Settings]", "LeftButton")
Check("another addon's link or a secret one opens nothing", opened == 1)

loadLines, lines = Login(CleanRangedSoundsDB)
Check("a later login prints nothing", #loadLines == 0 and #lines == 0)

print(failures == 0 and "Welcome: all checks passed" or ("Welcome: " .. failures .. " failed"))
os.exit(failures == 0 and 0 or 1)
