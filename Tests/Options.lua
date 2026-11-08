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

local function Color()
  return { WrapTextInColorCode = function(_, text) return text end }
end

local onLoaded, onLogin, afterCombat = {}, {}, {}
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
  UIParent = Frame("Frame"),
  UISpecialFrames = {},
  SlashCmdList = {},
  GameFontNormalLarge = {}, GameFontNormal = {}, GameFontHighlight = {}, GameFontDisable = {},
  NORMAL_FONT_COLOR = Color(), HIGHLIGHT_FONT_COLOR = Color(), GRAY_FONT_COLOR = Color(), GREEN_FONT_COLOR = Color(),
  RED_FONT_COLOR = Color(), WARNING_FONT_COLOR = Color(), YELLOW_FONT_COLOR = Color(),
  PANEL_BACKGROUND_COLOR = { GetRGBA = function() return 0, 0, 0, 1 end },
  PANEL_INSET_LEFT_OFFSET = 4, PANEL_INSET_RIGHT_OFFSET = -6, PANEL_INSET_BOTTOM_BUTTON_OFFSET = 26,
  PANEL_INSET_TOP_OFFSET = -24, PANEL_INSET_ATTIC_OFFSET = -60,
  SETTINGS_DEFAULTS = "Defaults",
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
  issecretvalue = function() return false end,
  MuteSoundFile = function(file) engineMuted[file] = true end,
  UnmuteSoundFile = function(file) engineMuted[file] = nil end,
  PlaySoundFile = function(file) played[#played + 1] = file end,
  PlaySound = function() end,
  PanelTemplates_TabResize = function() end,
  PanelTemplates_SetNumTabs = function(frame, count) frame.numTabs = count end,
  PanelTemplates_SetTab = function(frame, index) frame.selectedTab = index end,
  InCombatLockdown = function() return inCombat end,
  FrameTemplate_SetAtticHeight = function() end,
  MagicButton_OnLoad = function() end,
  GameTooltip_SetTitle = function() end,
  GameTooltip_AddNormalLine = function() end,
  GameTooltip_AddInstructionLine = function() end,
  GameTooltip_Hide = function() end,
  tinsert = table.insert,
  strmatch = string.match,
  strupper = string.upper,
}
for key, value in pairs(env) do _G[key] = value end

-- Any other global the addon reads is a missing stub, except the ones that start out unset.
local unset = { LibStub = true, CleanRangedSoundsDB = true }
setmetatable(_G, { __index = function(_, key)
  if not unset[key] then error("unstubbed global " .. tostring(key), 2) end
end })

local ns = {}
for _, path in ipairs({ "Libs/LibStub/LibStub.lua", "Libs/LibNativeUI-1.0/LibNativeUI-1.0.lua", "Core/Sounds.lua",
  "Core/Release.lua", "UI/Options.lua" }) do
  assert(loadfile(path))("CleanRangedSounds", ns)
end
rawset(_G, "CleanRangedSoundsDB", nil)
for _, callback in ipairs(onLoaded) do callback() end
for _, callback in ipairs(onLogin) do callback() end

local failures = 0
local function Check(label, condition)
  print((condition and "  pass  " or "  FAIL  ") .. label)
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

inCombat = true
SlashCmdList.CLEANRANGEDSOUNDS("")
Check("/crs in combat waits for combat to end", opened == nil and #afterCombat == 1)
inCombat = false
afterCombat[1]()
Check("then opens Settings on the page", opened == 14)

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

print(failures == 0 and "Options: all checks passed" or ("Options: " .. failures .. " failed"))
os.exit(failures == 0 and 0 or 1)
