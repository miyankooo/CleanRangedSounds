local addonName, ns = ...

-- The Clean Ranged Sounds page under Options > AddOns. It is a canvas page (Settings.RegisterCanvasLayoutCategory),
-- because Blizzard's settings list cannot show tabs or columns: one tab per weapon, one column per sound and a row
-- per file, where a tick lets the sound play and the speaker plays it once. The header copies the one every
-- settings list draws. Settings search reads only list pages (SettingsPanel.lua FindInitializersMatchingSearchText),
-- so the search no longer reads this addon's rows, which got it named in Blizzard's IsUserOAuthed and raid preview
-- errors. The category itself is still the addon's.

local UI = LibStub("LibNativeUI-1.0")

-- The header of SettingsListTemplate (Blizzard_SettingsList.xml:6-32): the title, the divider 50 px down and Defaults
-- in the top-right corner. The title keeps that template's GameFontHighlightHuge, so this page reads like every other.
local TITLE_LEFT, TITLE_TOP = 7, -22
local DIVIDER_TOP = -50
local DEFAULTS_WIDTH, DEFAULTS_HEIGHT = 96, 22
local DEFAULTS_RIGHT, DEFAULTS_TOP = -36, -16

-- PanelTabButtonTemplate is 32 px tall (Mainline/SharedUIPanelTemplates.xml:933). The top variant draws its art in the
-- bottom three quarters, so the tabs' open edge sits on the inset and their text centres 12 px above it.
local TAB_HEIGHT = 32
local TAB_ART_MIDDLE = 12
local INSET_TOP = DIVIDER_TOP - UI.Space.padding - TAB_HEIGHT

-- A row is the checkbox, its label wide enough for "Classic 3", then the speaker.
local ROW = UI.Size.row
local LABEL_WIDTH = 72
local SPEAKER_LEFT = ROW + UI.Space.tight + LABEL_WIDTH + UI.Space.tight
local COLUMN_PITCH = SPEAKER_LEFT + UI.Size.icon + UI.Space.section

-- A column's heading line and the gap under it, above its first row.
local ROWS_TOP = UI.Size.heading + UI.Space.gap

-- The speaker of Blizzard's sound rows (17 px in the Forever AtlasInfo), lit on hover the way the Cooldown Manager's
-- play-sample button is (Blizzard_CooldownViewer/CooldownViewerAlert.lua CooldownViewerAlert_SetupTypeButton).
local SPEAKER = "common-dropdown-icon-sound-on"
local SPEAKER_HOVER_ALPHA = 0.4

local panel, pages, categoryID
local shownWeapon = ns.weapons[1].key

-- A ticked row plays, an unticked one reads grey like a disabled option.
local function showTick(checkbox, ticked)
  checkbox:SetChecked(ticked)
  checkbox.Text:SetFontObject(ticked and UI.Font.body or UI.Font.muted)
end

local function createSpeaker(parent, file)
  local speaker = CreateFrame("Button", nil, parent)
  speaker:SetSize(UI.Size.icon, UI.Size.icon)
  speaker:SetNormalAtlas(SPEAKER)
  speaker:SetHighlightAtlas(SPEAKER, "ADD")
  speaker:GetHighlightTexture():SetAlpha(SPEAKER_HOVER_ALPHA)
  speaker:SetScript("OnClick", function() ns.PlayFile(file) end)
  UI.AttachTooltip(speaker, function(tooltip)
    GameTooltip_SetTitle(tooltip, "Play")
    GameTooltip_AddNormalLine(tooltip, "Plays this sound once, also while it is unticked.")
  end)
  return speaker
end

-- One file of a group: tick it to let it play. The setter only touches this group, so a click applies at once.
local function createFileRow(page, group, index, file, x)
  local checkbox = UI.CreateCheckbox(page, ns.FileLabel(group, index))
  checkbox:SetPoint("TOPLEFT", x, -(ROWS_TOP + (index - 1) * ROW))
  checkbox:SetScript("OnClick", function(self)
    local ticked = self:GetChecked()
    ns.db.muted[file] = not ticked
    ns.Refresh(group)
    showTick(self, ticked)
  end)
  UI.AttachTooltip(checkbox, function(tooltip)
    GameTooltip_SetTitle(tooltip, group.label)
    GameTooltip_AddNormalLine(tooltip, group.tooltip)
  end)
  checkbox.update = function() showTick(checkbox, not ns.db.muted[file]) end

  createSpeaker(page, file):SetPoint("LEFT", checkbox, "LEFT", SPEAKER_LEFT, 0)
  return checkbox
end

-- Which shot sounds your own shots with this weapon pick from. Ticking several mixes them.
local function createPlaysRow(page, weapon, sound, x, y)
  local checkbox = UI.CreateCheckbox(page, sound.label .. " Shots")
  checkbox:SetPoint("TOPLEFT", x, y)
  checkbox:SetScript("OnClick", function(self)
    ns.db.plays[weapon.key][sound.key] = self:GetChecked()
    ns.Refresh(ns.shotGroups[weapon.key])
  end)
  UI.AttachTooltip(checkbox, function(tooltip)
    GameTooltip_SetTitle(tooltip, sound.label .. " Shots")
    GameTooltip_AddNormalLine(tooltip, ("Your own %s shots play the %s shots you ticked. Tick several to mix them.")
      :format(weapon.key, sound.key))
  end)
  checkbox.update = function() checkbox:SetChecked(ns.db.plays[weapon.key][sound.key]) end
  return checkbox
end

-- One weapon's tab: a column per sound, then which shots your own weapon plays and what that costs.
local function buildPage(parent, weapon)
  local page = CreateFrame("Frame", nil, parent)
  page:SetPoint("TOPLEFT", UI.Space.padding, -UI.Space.padding)
  page:SetPoint("BOTTOMRIGHT", -UI.Space.padding, UI.Space.padding)
  page:Hide()
  page.controls = {}

  local column, rowsHeight = 0, 0
  for _, group in ipairs(ns.groups) do
    if group.weapon == weapon.key then
      local x = column * COLUMN_PITCH
      local heading = UI.CreateText(page, "heading")
      heading:SetPoint("TOPLEFT", x, 0)
      heading:SetText(group.label)
      for index, file in ipairs(group.files) do
        page.controls[#page.controls + 1] = createFileRow(page, group, index, file, x)
      end
      rowsHeight = math.max(rowsHeight, #group.files * ROW)
      column = column + 1
    end
  end

  local playsTop = -(ROWS_TOP + rowsHeight + UI.Space.section)
  local heading = UI.CreateText(page, "heading")
  heading:SetPoint("TOPLEFT", 0, playsTop)
  heading:SetText(("Your %s Shots Play"):format(weapon.label))
  for index, sound in ipairs(ns.weapons) do
    page.controls[#page.controls + 1] = createPlaysRow(page, weapon, sound, (index - 1) * COLUMN_PITCH,
      playsTop - ROWS_TOP)
  end

  -- Replacing mutes the whole shot group for the game, since its own pick cannot be read (Core/Sounds.lua KeptFiles).
  local note = UI.CreateText(page, "muted")
  note:SetPoint("TOPLEFT", 0, playsTop - ROWS_TOP - ROW - UI.Space.tight)
  note:SetPoint("RIGHT")
  note:SetWordWrap(true)
  note:SetText(("Your own shots play one of the ticked shots. Untick some but not all of them, or pick another"
    .. " weapon's shots, and other players' %ss fire silently."):format(weapon.key))
  return page
end

local function showWeapon(key)
  shownWeapon = key
  for index, weapon in ipairs(ns.weapons) do
    local page = pages[weapon.key]
    page:SetShown(weapon.key == key)
    if weapon.key == key then
      PanelTemplates_SetTab(panel, index)
      for _, control in ipairs(page.controls) do control.update() end
    end
  end
end

local function buildPanel()
  panel = CreateFrame("Frame")
  panel:Hide()

  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
  title:SetPoint("TOPLEFT", TITLE_LEFT, TITLE_TOP)
  title:SetText(ns.title)

  local divider = panel:CreateTexture(nil, "ARTWORK")
  divider:SetAtlas("Options_HorizontalDivider", true)
  divider:SetPoint("TOP", 0, DIVIDER_TOP)

  -- Defaults resets the weapon you see, as Blizzard's Defaults resets the page you see.
  local defaults = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  defaults:SetSize(DEFAULTS_WIDTH, DEFAULTS_HEIGHT)
  defaults:SetPoint("TOPRIGHT", DEFAULTS_RIGHT, DEFAULTS_TOP)
  defaults:SetText(SETTINGS_DEFAULTS)
  defaults:SetScript("OnClick", function()
    ns.ResetWeapon(shownWeapon)
    showWeapon(shownWeapon)
  end)

  local inset = UI.CreateInset(panel)
  inset:SetPoint("TOPLEFT", TITLE_LEFT, INSET_TOP)
  inset:SetPoint("BOTTOMRIGHT", DEFAULTS_RIGHT, 0)

  pages = {}
  for index, weapon in ipairs(ns.weapons) do
    pages[weapon.key] = buildPage(inset, weapon)

    -- The top tabs of the Appearances collection, standing on the inset's top edge.
    local tab = CreateFrame("Button", nil, panel, "PanelTopTabButtonTemplate")
    tab:SetID(index)
    tab:SetText(weapon.label)
    PanelTemplates_TabResize(tab)
    tab:SetScript("OnClick", function()
      PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
      showWeapon(weapon.key)
    end)
    if index == 1 then tab:SetPoint("BOTTOMLEFT", inset, "TOPLEFT", UI.Space.padding, 0) end
  end
  PanelTemplates_SetNumTabs(panel, #ns.weapons)

  local help = UI.CreateText(panel, "body")
  help:SetPoint("RIGHT", inset, "TOPRIGHT", -UI.Space.padding, TAB_ART_MIDDLE)
  help:SetText("Ticked sounds play. Unticked ones are muted for everyone.")

  -- Blizzard calls this through securecallfunction each time the page is shown. It opens on the weapon you have
  -- equipped, else on the tab you saw last.
  function panel.OnRefresh()
    showWeapon(ns.EquippedWeapon() or shownWeapon)
  end
  return panel
end

-- Registered at ADDON_LOADED, the way Blizzard's implementation guide does it (Blizzard_ImplementationReadme.lua).
EventUtil.ContinueOnAddOnLoaded(addonName, function()
  local category = Settings.RegisterCanvasLayoutCategory(buildPanel(), ns.title)
  Settings.RegisterAddOnCategory(category)
  categoryID = category:GetID()
end)

local waitingForCombat = false

local function OpenSettings()
  if not categoryID then return end

  -- C_SettingsUtil.OpenSettingsPanel has restrictions the source does not spell out, so an open in
  -- combat waits for combat to end instead of failing silently.
  if InCombatLockdown() then
    UI.Print(ns.title, "Opens after combat.")
    if not waitingForCombat then
      waitingForCombat = true
      EventUtil.RegisterOnceFrameEventAndCallback("PLAYER_REGEN_ENABLED", function()
        waitingForCombat = false
        OpenSettings()
      end)
    end
    return
  end

  Settings.OpenToCategory(categoryID)
end

UI.RegisterSlash("CLEANRANGEDSOUNDS", { "/cleanrangedsounds", "/crs" }, OpenSettings)

-- Addon Compartment entry points named in the toc. Blizzard calls them with the addon name first, then the menu row.
function CleanRangedSounds_CompartmentClick()
  OpenSettings()
end

function CleanRangedSounds_CompartmentEnter(_, menuButton)
  UI.ShowTooltip(menuButton, function(tooltip)
    GameTooltip_SetTitle(tooltip, ns.title)
    GameTooltip_AddInstructionLine(tooltip, "Click to open the settings.")
  end, "ANCHOR_LEFT")
end

function CleanRangedSounds_CompartmentLeave()
  GameTooltip:Hide()
end
