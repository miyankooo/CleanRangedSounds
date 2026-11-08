local addonName, ns = ...

-- The Clean Ranged Sounds page under Options > AddOns. It is a canvas page (Settings.RegisterCanvasLayoutCategory),
-- because Blizzard's settings list cannot show tabs or columns: one tab per weapon, one column per sound and a row
-- per file, where a tick lets the sound play and the speaker plays it once. The header copies the one every
-- settings list draws. Settings search reads only list pages (SettingsPanel.lua FindInitializersMatchingSearchText),
-- so the search no longer reads this addon's rows, which got it named in Blizzard's IsUserOAuthed and raid preview
-- errors. The category itself is still the addon's.

-- Spacing and sizes on the 4 px grid.
local TIGHT, GAP, PADDING, SECTION = 4, 8, 16, 24
local ROW, HEADING, ICON = 24, 16, 16

-- The inset spans from the header's title on the left to its Defaults button on the right (BuildPanel).
local TITLE_LEFT, DEFAULTS_RIGHT = 7, -36

-- PanelTabButtonTemplate is 32 px tall (Mainline/SharedUIPanelTemplates.xml:933). The top variant draws its art in the
-- bottom three quarters, so the tabs' open edge sits on the inset and their text centres 12 px above it. The tabs hang
-- below the intro as a settings page's rows do.
local TAB_HEIGHT = 32
local TAB_ART_MIDDLE = 12

-- What the addon does, where it works and what stays the game's own. Two lines at most, so the tallest tab still fits.
local INTRO = "Mutes the bow creak before each shot and any other bow, crossbow or gun sound you untick, for every"
  .. " player and creature. Wand and spell sounds stay the game's own."

-- A row is the checkbox, its label wide enough for "Classic 3", then the speaker.
local LABEL_WIDTH = 72
local SPEAKER_LEFT = ROW + TIGHT + LABEL_WIDTH + TIGHT
local COLUMN_PITCH = SPEAKER_LEFT + ICON + SECTION

-- A column's heading line and the gap under it, above its first row.
local ROWS_TOP = HEADING + GAP

-- The help tip points up at each tab's first row from below, its arrow at the left end, so it stays on the page.
local TIP = "Untick a sound here to mute it, or click its speaker to hear it first."

-- Text in a font role: GameFontNormal (heading, gold), GameFontHighlight (body, white), GameFontDisable (muted,
-- grey), GameFontNormalLarge (title, 16 px, a dialog's subject line only).
local function CreateText(parent, fontObject, layer)
  local text = parent:CreateFontString(nil, layer or "ARTWORK")
  text:SetFontObject(fontObject or GameFontHighlight)
  text:SetJustifyH("LEFT")
  return text
end

-- A GameTooltip owned by the hovered frame, filled with Blizzard's GameTooltip_* line helpers. A frame whose
-- template already sets OnEnter gets HookScript instead.
local function AttachTooltip(frame, fill, anchor)
  frame:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, anchor or "ANCHOR_RIGHT")
    fill(GameTooltip, self)
    GameTooltip:Show()
  end)
  frame:SetScript("OnLeave", GameTooltip_Hide)
end

-- CheckboxWithLabelTemplate: the minimal art Blizzard's Settings use, at the 24 px AddonList gives it
-- (Blizzard_AddOnList/AddonList.xml:73-74). The label joins the hit rect, so a click on it toggles the box.
local function CreateCheckbox(parent, label)
  local checkbox = CreateFrame("CheckButton", nil, parent, "CheckboxWithLabelTemplate")
  checkbox:SetSize(24, 24)
  checkbox.Text:SetFontObject(GameFontHighlight)
  checkbox.Text:ClearAllPoints()
  checkbox.Text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
  checkbox.Text:SetText(label)
  checkbox:SetHitRectInsets(0, -(4 + checkbox.Text:GetStringWidth()), 0, 0)
  return checkbox
end

-- A play button for a sound: the dropdown speaker atlas, 16 px, with a soft ADD highlight.
local function CreateSoundButton(parent, play)
  local button = CreateFrame("Button", nil, parent)
  button:SetSize(16, 16)
  button:SetNormalAtlas("common-dropdown-icon-sound-on")
  button:SetHighlightAtlas("common-dropdown-icon-sound-on", "ADD")
  button:GetHighlightTexture():SetAlpha(0.4)
  button:SetScript("OnClick", play)
  return button
end

-- An inset's border on the stone without its marble tile, as the Auction House category list
-- (Blizzard_AuctionHouseCategoriesList.xml:60). For a status box in the button bar or a block on a settings page,
-- never on the brown panel.
local function CreateInset(parent)
  local inset = CreateFrame("Frame", nil, parent, "InsetFrameTemplate")
  inset.Bg:Hide()
  return inset
end

-- Blizzard's top tabs, the ones the wardrobe uses, standing on the top edge of the content they switch, the first
-- 16 in from its left. PanelTemplates anchors each later tab after the first and swaps the selected art.
local function CreateTabs(owner, content, labels, onSelect)
  for index, label in ipairs(labels) do
    local tab = CreateFrame("Button", nil, owner, "PanelTopTabButtonTemplate")
    tab:SetID(index)
    tab:SetText(label)
    PanelTemplates_TabResize(tab)
    tab:SetScript("OnClick", function()
      PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
      PanelTemplates_SetTab(owner, index)
      onSelect(index)
    end)
    if index == 1 then tab:SetPoint("BOTTOMLEFT", content, "TOPLEFT", 16, 0) end
  end
  PanelTemplates_SetNumTabs(owner, #labels)
end

-- Blizzard's yellow callout, as an own HelpTipTemplate frame of the target. Never HelpTip:Show: it takes a frame from
-- Blizzard's shared pool, and writing to the pool from addon code taints the help tips Blizzard shows later. The tip
-- shows each time its target shows until it is closed or the feature is used, then never again on the account. It
-- hides with its target without being marked. The returned function marks the feature used.
local function AttachTip(target, text, targetPoint, alignment)
  local tip
  local info = {
    text = text,
    buttonStyle = HelpTip.ButtonStyle.Close,
    targetPoint = targetPoint,
    alignment = alignment,
    -- A closed tip keeps its acknowledged mark (HelpTipTemplateMixin:HandleAcknowledge), which would mark the next
    -- showing seen as soon as it hides, so after /crs intro a fresh frame takes its place.
    onAcknowledgeCallback = function()
      ns.db.tipSeen = true
      tip = nil
    end,
  }
  target:HookScript("OnShow", function()
    if ns.db.tipSeen then return end
    if not tip then
      tip = CreateFrame("Frame", nil, target, "HelpTipTemplate")
      tip.width = HelpTip.width
      tip:SetWidth(tip.width)
    end
    tip:Init(target, info, target)
    tip:Show()
  end)
  return function()
    if tip and tip.info then tip:Acknowledge() else ns.db.tipSeen = true end
  end
end

-- The addon's page in Blizzard's Settings window, as its own canvas, copying the settings list's look
-- (Blizzard_SettingsList.xml:14-30, Blizzard_SettingControls.xml, Blizzard_SettingControls.lua). Never a settings
-- list: a pick in a list dropdown runs addon code in Blizzard's pooled controls and taints its settings until /reload.
local LABEL_X, INTRO_Y, INTRO_GAP = 37, -64, 16
local categoryID

local function BuildPanel(introText, restoreDefaults)
  local panel = CreateFrame("Frame")
  local title = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightHuge")
  title:SetJustifyH("LEFT")
  title:SetPoint("TOPLEFT", 7, -22)
  title:SetText(ns.title)
  local divider = panel:CreateTexture(nil, "ARTWORK")
  divider:SetAtlas("Options_HorizontalDivider", true)
  divider:SetPoint("TOP", 0, -50)
  local defaults = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
  defaults:SetSize(96, 22)
  defaults:SetPoint("TOPRIGHT", -36, -16)
  defaults:SetText(SETTINGS_DEFAULTS)
  defaults:SetScript("OnClick", restoreDefaults)
  panel.defaults = defaults
  panel.intro = CreateText(panel, GameFontHighlight)
  panel.intro:SetPoint("TOPLEFT", LABEL_X, INTRO_Y)
  panel.intro:SetPoint("TOPRIGHT", -LABEL_X, INTRO_Y)
  panel.intro:SetText(introText)
  return panel
end

local function RegisterPanel(panel)
  local category = Settings.RegisterCanvasLayoutCategory(panel, ns.title)
  Settings.RegisterAddOnCategory(category)
  categoryID = category:GetID()
end

-- Opening in combat waits for combat to end, since the settings panel's open path has restrictions.
local waitingForCombat = false
function ns.OpenSettings()
  if not categoryID then return end
  if InCombatLockdown() then
    ns.Print("Opens after combat.")
    if not waitingForCombat then
      waitingForCombat = true
      EventUtil.RegisterOnceFrameEventAndCallback("PLAYER_REGEN_ENABLED", function()
        waitingForCombat = false
        ns.OpenSettings()
      end)
    end
    return
  end
  Settings.OpenToCategory(categoryID)
end

local panel, pages
local shownWeapon = ns.weapons[1].key

-- A ticked row plays, an unticked one reads grey like a disabled option.
local function showTick(checkbox, ticked)
  checkbox:SetChecked(ticked)
  checkbox.Text:SetFontObject(ticked and GameFontHighlight or GameFontDisable)
end

-- One file of a group: tick it to let it play. The setter only touches this group, so a click applies at once.
local function createFileRow(page, group, index, file, x)
  local checkbox = CreateCheckbox(page, ns.FileLabel(group, index))
  checkbox:SetPoint("TOPLEFT", x, -(ROWS_TOP + (index - 1) * ROW))
  checkbox:SetScript("OnClick", function(self)
    local ticked = self:GetChecked()
    ns.db.muted[file] = not ticked
    ns.Refresh(group)
    showTick(self, ticked)
    page.tipUsed()
  end)
  AttachTooltip(checkbox, function(tooltip)
    GameTooltip_SetTitle(tooltip, group.label)
    GameTooltip_AddNormalLine(tooltip, group.tooltip)
  end)
  checkbox.update = function() showTick(checkbox, not ns.db.muted[file]) end

  local speaker = CreateSoundButton(page, function() ns.PlayFile(file) end)
  speaker:SetPoint("LEFT", checkbox, "LEFT", SPEAKER_LEFT, 0)
  AttachTooltip(speaker, function(tooltip)
    GameTooltip_SetTitle(tooltip, "Play")
    GameTooltip_AddNormalLine(tooltip, "Plays this sound once, also while it is unticked.")
  end)
  return checkbox
end

-- Which shot sounds your own shots with this weapon pick from. Ticking several mixes them.
local function createPlaysRow(page, weapon, sound, x, y)
  local checkbox = CreateCheckbox(page, sound.label .. " Shots")
  checkbox:SetPoint("TOPLEFT", x, y)
  checkbox:SetScript("OnClick", function(self)
    ns.db.plays[weapon.key][sound.key] = self:GetChecked()
    ns.Refresh(ns.shotGroups[weapon.key])
  end)
  AttachTooltip(checkbox, function(tooltip)
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
  page:SetPoint("TOPLEFT", PADDING, -PADDING)
  page:SetPoint("BOTTOMRIGHT", -PADDING, PADDING)
  page:Hide()
  page.controls = {}

  local column, rowsHeight = 0, 0
  for _, group in ipairs(ns.groups) do
    if group.weapon == weapon.key then
      local x = column * COLUMN_PITCH
      local heading = CreateText(page, GameFontNormal)
      heading:SetPoint("TOPLEFT", x, 0)
      heading:SetText(group.label)
      for index, file in ipairs(group.files) do
        page.controls[#page.controls + 1] = createFileRow(page, group, index, file, x)
      end
      rowsHeight = math.max(rowsHeight, #group.files * ROW)
      column = column + 1
    end
  end
  page.tipUsed = AttachTip(page.controls[1], TIP, HelpTip.Point.BottomEdgeCenter, HelpTip.Alignment.Left)

  local playsTop = -(ROWS_TOP + rowsHeight + SECTION)
  local heading = CreateText(page, GameFontNormal)
  heading:SetPoint("TOPLEFT", 0, playsTop)
  heading:SetText(("Your %s Shots Play"):format(weapon.label))
  for index, sound in ipairs(ns.weapons) do
    page.controls[#page.controls + 1] = createPlaysRow(page, weapon, sound, (index - 1) * COLUMN_PITCH,
      playsTop - ROWS_TOP)
  end

  -- Replacing mutes the whole shot group for the game, since its own pick cannot be read (Core/Sounds.lua KeptFiles).
  local note = CreateText(page, GameFontDisable)
  note:SetPoint("TOPLEFT", 0, playsTop - ROWS_TOP - ROW - TIGHT)
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

-- Defaults resets the weapon you see, as Blizzard's Defaults resets the page you see.
local function restoreDefaults()
  ns.ResetWeapon(shownWeapon)
  showWeapon(shownWeapon)
end

local function buildSettings()
  panel = BuildPanel(INTRO, restoreDefaults)
  panel:Hide()

  -- UIPanelButtonTemplate sets its own OnEnter and OnLeave (UIPanelButtonMixin), so the tooltip hooks in after it.
  panel.defaults:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip_SetTitle(GameTooltip, SETTINGS_DEFAULTS)
    GameTooltip_AddNormalLine(GameTooltip, "Resets the sounds on this tab and which shots this weapon plays. The other"
      .. " tabs keep your choices.")
    GameTooltip:Show()
  end)

  -- A padding above the page's bottom edge, so the inset's border doesn't sit on it.
  local inset = CreateInset(panel)
  inset:SetPoint("TOPLEFT", panel.intro, "BOTTOMLEFT", TITLE_LEFT - LABEL_X, -(INTRO_GAP + TAB_HEIGHT))
  inset:SetPoint("BOTTOMRIGHT", DEFAULTS_RIGHT, PADDING)

  pages = {}
  local labels = {}
  for index, weapon in ipairs(ns.weapons) do
    pages[weapon.key] = buildPage(inset, weapon)
    labels[index] = weapon.label
  end
  CreateTabs(panel, inset, labels, function(index) showWeapon(ns.weapons[index].key) end)

  local help = CreateText(panel, GameFontHighlight)
  help:SetPoint("RIGHT", inset, "TOPRIGHT", -PADDING, TAB_ART_MIDDLE)
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
  RegisterPanel(buildSettings())
end)

-- One long command and one short alias. The bare command opens the settings; help and intro are the shared words,
-- and any other word prints the hint.
SLASH_CLEANRANGEDSOUNDS1, SLASH_CLEANRANGEDSOUNDS2 = "/cleanrangedsounds", "/crs"
SlashCmdList.CLEANRANGEDSOUNDS = function(message)
  local command = strtrim(message or ""):lower()
  if command == "" then
    ns.OpenSettings()
  elseif command == "help" or command == "?" then
    ns.Print("Type /crs for the settings, /crs intro to see the welcome line and the tip again, or /crs help for "
      .. "this list.")
  elseif command == "intro" then
    ns.ReplayIntro()
  else
    ns.Print("Unknown command. Type /crs help for the list.")
  end
end

-- Addon Compartment entry points named in the toc. Blizzard calls them with the addon name first, then the menu row.
function CleanRangedSounds_CompartmentClick()
  ns.OpenSettings()
end

-- The tooltip lists how many sounds each weapon has muted, then what a click does.
function CleanRangedSounds_CompartmentEnter(_, menuButton)
  GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
  GameTooltip_SetTitle(GameTooltip, ns.title)
  for _, weapon in ipairs(ns.weapons) do
    local muted, total = 0, 0
    for _, group in ipairs(ns.groups) do
      if group.weapon == weapon.key then
        for _, file in ipairs(group.files) do
          total = total + 1
          if ns.db.muted[file] then muted = muted + 1 end
        end
      end
    end
    GameTooltip_AddColoredDoubleLine(GameTooltip, weapon.label, ("%d of %d muted"):format(muted, total),
      HIGHLIGHT_FONT_COLOR, HIGHLIGHT_FONT_COLOR)
  end
  GameTooltip_AddInstructionLine(GameTooltip, "Click to open the settings.")
  GameTooltip:Show()
end

function CleanRangedSounds_CompartmentLeave()
  GameTooltip:Hide()
end
