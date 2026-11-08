-- Builds the settings page against stub frames and clicks through it. Frame methods are permissive, any unknown one is a
-- no-op, but every global the addon reads must be stubbed here, so a misspelt Blizzard function fails. It proves
-- load order and control flow only, nothing about layout or how the client draws it. Run from the repo root:
-- lua Tests/Options.lua
local engineMuted, played = {}, {}

local Frame

-- A template's Text child appears on first use, the way CheckboxWithLabelTemplate and button templates carry one.
local function NewFrame(kind, parent)
  local frame = { kind = kind, parent = parent, scripts = {}, shown = true, checked = false }
  return setmetatable(frame, { __index = function(self, key)
    if key == "Text" then
      self.Text = Frame("FontString", nil, self)
      return self.Text
    end
    -- Methods are capitalised, data fields are not, so a missing field stays nil.
    if key:match("^%u") and key ~= "Tabs" then return function() end end
  end })
end

local stubs = {}
function Frame(kind, name, parent, template)
  local frame = NewFrame(kind, parent)
  frame.template = template
  function frame:SetScript(event, handler) self.scripts[event] = handler end
  function frame:GetScript(event) return self.scripts[event] end
  function frame:Show() self.shown = true end
  function frame:Hide() self.shown = false end
  function frame:SetShown(shown) self.shown = shown and true or false end
  function frame:IsShown() return self.shown end
  function frame:SetChecked(checked) self.checked = checked and true or false end
  function frame:GetChecked() return self.checked end
  function frame:SetText(text) self.text = text end
  function frame:GetText() return self.text end
  function frame:SetID(id) self.id = id end
  function frame:GetID() return self.id end
  function frame:GetStringHeight() return 26 end
  function frame:GetStringWidth() return 48 end
  function frame:GetTextWidth() return 48 end
  function frame:GetPoint() return "CENTER", nil, "CENTER", 0, 0 end
  function frame:SetHeight(height) self.height = height end
  function frame:GetHighlightTexture() return NewFrame("Texture", self) end
  function frame:CreateFontString() return Frame("FontString", nil, self) end
  function frame:CreateTexture() return Frame("Texture", nil, self) end
  function frame:Click()
    if self.kind == "CheckButton" then self.checked = not self.checked end
    self.scripts.OnClick(self, "LeftButton")
  end
  if template == "InsetFrameTemplate" then frame.Bg = Frame("Texture", nil, frame) end
  if template == "PanelTopTabButtonTemplate" then
    parent.Tabs = rawget(parent, "Tabs") or {}
    parent.Tabs[#parent.Tabs + 1] = frame
  end
  stubs[#stubs + 1] = frame
  if name then _G[name] = frame end
  return frame
end

local SECRET = {}
local onLoaded, onLogin, afterCombat, onItemRef = {}, {}, {}, nil
local inCombat, registered, opened = false, nil, nil
local Settings = {
  RegisterCanvasLayoutCategory = function(frame, name)
    registered = { frame = frame, name = name, GetID = function() return 14 end }
    return registered
  end,
  RegisterAddOnCategory = function(category) category.added = true end,
  OpenToCategory = function(id) opened = id end,
}
local env = {
  CreateFrame = Frame,
  Settings = Settings,
  SlashCmdList = {},
  GameFontNormal = {}, GameFontHighlight = {}, GameFontDisable = {},
  NORMAL_FONT_COLOR = { WrapTextInColorCode = function(_, text) return "<gold>" .. text .. "</gold>" end },
  SETTINGS = "Settings", SETTINGS_DEFAULTS = "Defaults",
  LinkTypes = { AddOn = "addon" },
  LinkUtil = {
    FormatLink = function(linkType, text, ...)
      return table.concat({ ("|H%s"):format(linkType), ... }, ":") .. ("|h%s|h"):format(text)
    end,
  },
  EventRegistry = {
    RegisterCallback = function(_, event, callback, owner)
      if event == "SetItemRef" then onItemRef = function(...) callback(owner, ...) end end
    end,
  },
  SOUNDKIT = { IG_CHARACTER_INFO_TAB = 841 },
  INVSLOT_RANGED = 18,
  Enum = { ItemClass = { Weapon = 2 }, ItemWeaponSubclass = { Bows = 2, Guns = 3, Crossbow = 18 } },
  GameTooltip = Frame("GameTooltip"),
  EventUtil = {
    ContinueOnAddOnLoaded = function(_, callback) onLoaded[#onLoaded + 1] = callback end,
    ContinueOnPlayerLogin = function(callback) onLogin[#onLogin + 1] = callback end,
    RegisterOnceFrameEventAndCallback = function(_, callback) afterCombat[#afterCombat + 1] = callback end,
  },
  C_AddOns = { GetAddOnMetadata = function() return "Clean Ranged Sounds" end },
  C_Spell = { GetSpellName = function(id) return "Spell " .. id end },
  C_Item = { GetItemInfoInstant = function() return nil, nil, nil, nil, nil, 2, 3 end },
  GetInventoryItemID = function() return 2099 end,
  issecretvalue = function(value) return value == SECRET end,
  MuteSoundFile = function(file) engineMuted[file] = true end,
  UnmuteSoundFile = function(file) engineMuted[file] = nil end,
  PlaySoundFile = function(file) played[#played + 1] = file end,
  PlaySound = function() end,
  PanelTemplates_TabResize = function() end,
  PanelTemplates_SetNumTabs = function(frame, count) frame.numTabs = count end,
  PanelTemplates_SetTab = function(frame, index) frame.selectedTab = index end,
  InCombatLockdown = function() return inCombat end,
  GameTooltip_SetTitle = function() end,
  GameTooltip_AddNormalLine = function() end,
  GameTooltip_AddInstructionLine = function() end,
  GameTooltip_Hide = function() end,
}
for key, value in pairs(env) do _G[key] = value end

-- Any other global the addon reads is a missing stub, except the ones that start out unset.
local unset = { CleanRangedSoundsDB = true }
setmetatable(_G, { __index = function(_, key)
  if not unset[key] then error("unstubbed global " .. tostring(key), 2) end
end })

-- The addon's chat lines go to chat, the checks' own lines to the terminal.
local write, chat = print, {}
print = function(line) chat[#chat + 1] = line end

-- Loads the addon's files in the toc's order, so a stale or missing toc line fails here.
local ns = {}
for line in io.lines("CleanRangedSounds.toc") do
  local path = line:match("^([^#%s].-%.lua)%s*$")
  if path then assert(loadfile((path:gsub("\\", "/"))))("CleanRangedSounds", ns) end
end
rawset(_G, "CleanRangedSoundsDB", nil)
for _, callback in ipairs(onLoaded) do callback() end
for _, callback in ipairs(onLogin) do callback() end

local failures = 0
local function Check(label, condition)
  write((condition and "  pass  " or "  FAIL  ") .. label)
  if not condition then failures = failures + 1 end
end

local function Find(kind, text, parent)
  for _, frame in ipairs(stubs) do
    if frame.kind == kind and frame.Text and rawget(frame, "Text") and frame.Text.text == text
      and (not parent or frame.parent == parent) then
      return frame
    end
  end
end

local panel = registered and registered.frame
Check("the page is registered under AddOns at load", panel and registered.added
  and registered.name == "Clean Ranged Sounds")

Check("the page opens with an intro under the divider", panel.intro and panel.intro.text:find("^Mutes the bow creak"))

Check("the first login prints the welcome line with the Settings link", #chat == 1
  and chat[1]:find("<gold>|Haddon:CleanRangedSounds|h[Settings]|h</gold>", 1, true))

inCombat = true
SlashCmdList.CLEANRANGEDSOUNDS("")
Check("/crs in combat waits for combat to end", opened == nil and #afterCombat == 1)
Check("and says so in one line with the gold title", #chat == 2
  and chat[2] == "<gold>[Clean Ranged Sounds]</gold>: Opens after combat.")
inCombat = false
afterCombat[1]()
Check("then opens Settings on the page", opened == 14)

opened = nil
onItemRef("addon:CleanRangedSounds", "[Settings]", "LeftButton")
Check("the welcome link opens Settings on the page", opened == 14)

-- What Blizzard does when it shows the page.
panel:Show()
panel.OnRefresh()
Check("the page opens on the equipped gun", panel.selectedTab == 3)
Check("three weapon tabs", #panel.Tabs == 3 and panel.Tabs[1].text == "Bow")

local gunPage = Find("CheckButton", "Heavy 1").parent
local bowPage = Find("CheckButton", "Modern 8").parent
Check("only the gun page shows", gunPage:IsShown() and not bowPage:IsShown())

local classic = Find("CheckButton", "Classic 1", gunPage)
local loadOrShot = {}
for _, frame in ipairs(stubs) do
  if frame.kind == "CheckButton" and frame.parent == gunPage and rawget(frame, "Text")
    and frame.Text.text == "Classic 1" then
    loadOrShot[#loadOrShot + 1] = frame
  end
end
Check("rows start ticked where the sound plays", #loadOrShot == 2 and loadOrShot[1]:GetChecked()
  and loadOrShot[2]:GetChecked())

-- The second Classic 1 on the gun page is the shot column.
local shot = loadOrShot[2]
shot:Click()
Check("unticking a gun shot mutes it and replaces the group", ns.db.muted[567721] == true
  and engineMuted[567721] and engineMuted[567718] and ns.KeptFiles(ns.shotGroups.gun)
  and #ns.KeptFiles(ns.shotGroups.gun) == 11)

local crossbowShots = Find("CheckButton", "Crossbow Shots", gunPage)
crossbowShots:Click()
Check("Gun Shots Play Crossbow Shots mixes them in", ns.db.plays.gun.crossbow == true
  and #ns.KeptFiles(ns.shotGroups.gun) == 17)

panel.Tabs[1]:Click()
Check("the Bow tab shows the bow page with the pull unticked", panel.selectedTab == 1 and bowPage:IsShown()
  and not gunPage:IsShown() and not Find("CheckButton", "Modern 8", bowPage):GetChecked())

panel.Tabs[3]:Click()
for _, frame in ipairs(stubs) do
  if frame.kind == "Button" and frame.text == "Defaults" then frame:Click() end
end
Check("Defaults resets the gun and its rows", not ns.db.muted[567721] and not ns.db.plays.gun.crossbow
  and shot:GetChecked() and not crossbowShots:GetChecked() and not engineMuted[567721]
  and ns.db.muted[567677])

local speakers = 0
for _, frame in ipairs(stubs) do
  if frame.kind == "Button" and frame.parent == gunPage and frame.scripts.OnClick then speakers = speakers + 1 end
end
Check("one speaker per gun sound", speakers == 15)

panel.Tabs[1]:Click()
panel.OnRefresh()
Check("each showing opens on the equipped weapon again", panel.selectedTab == 3)

-- Your own shots, through Core/Release.lua's listener: one kept file per shot, and nothing for a secret spell ID.
local listener
for _, frame in ipairs(stubs) do
  if frame.scripts.OnEvent then listener = frame end
end
shot:Click()
local before = #played
listener.scripts.OnEvent(listener, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast", 75)
Check("an Auto Shot with a muted gun shot plays one kept file", #played == before + 1 and played[#played] ~= 567721)
listener.scripts.OnEvent(listener, "UNIT_SPELLCAST_SUCCEEDED", "player", "cast", SECRET)
Check("a secret spell ID plays nothing", #played == before + 1)

write(failures == 0 and "Options: all checks passed" or ("Options: " .. failures .. " failed"))
os.exit(failures == 0 and 0 or 1)
