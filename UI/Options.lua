local _, ns = ...

local categoryID

-- Each row is Blizzard's checkbox with a button: the checkbox mutes one file, the button plays it, also
-- while muted. No dropdowns: picking in a native settings dropdown taints Blizzard's own settings until
-- /reload on build 70532 (2026-10-21), while checkboxes stay clean.
local PLAY = "Play"

-- A proxy setting calls its setter only when the value really changes, so each tick, untick or Defaults
-- click is applied exactly once.
local function AddFileRow(category, layout, group, index, file)
  local variable = ("CLEAN_RANGED_SOUNDS_%s_%d"):format(strupper(group.key), index)
  local label = ("Mute %s %d"):format(group.label, index)
  local setting = Settings.RegisterProxySetting(category, variable, Settings.VarType.Boolean, label,
    group.mutedByDefault == true,
    function() return ns.db.muted[file] end,
    function(value)
      ns.db.muted[file] = value
      ns.Refresh(group)
    end)

  layout:AddInitializer(CreateSettingsCheckboxWithButtonInitializer(setting, PLAY,
    function() ns.PlayFile(file) end, nil, false, group.tooltip))
end

local function AddReplaceRow(category)
  local setting = Settings.RegisterProxySetting(category, "CLEAN_RANGED_SOUNDS_REPLACE",
    Settings.VarType.Boolean, "Replace Muted Shot Sounds", true,
    function() return ns.db.replace end,
    function(value)
      ns.db.replace = value
      for _, group in pairs(ns.shotGroups) do ns.Refresh(group) end
    end)

  Settings.CreateCheckbox(category, setting, "When some shot sounds of a weapon are muted but not all, your own"
    .. " shots play one of the sounds you kept, so no shot goes silent. Other bows, crossbows or guns then play"
    .. " no shot sound.")
end

local function Title(key)
  return (key:gsub("^%l", strupper))
end

-- One row per weapon and shot sound, so each weapon plays one weapon's shot sounds or a mix of several.
local function AddPlaysRow(category, weapon, sound)
  local variable = ("CLEAN_RANGED_SOUNDS_%s_PLAYS_%s"):format(strupper(weapon.shot), strupper(sound.shot))
  local label = ("%s Plays %s Shots"):format(Title(weapon.shot), Title(sound.shot))
  local setting = Settings.RegisterProxySetting(category, variable, Settings.VarType.Boolean, label,
    weapon == sound,
    function() return ns.db.plays[weapon.shot][sound.shot] end,
    function(value)
      ns.db.plays[weapon.shot][sound.shot] = value
      ns.Refresh(weapon)
    end)

  Settings.CreateCheckbox(category, setting, ("Your own %s shots play the %s shot sounds you kept. Tick several"
    .. " to mix them. Once your %s plays another weapon's sounds, other %ss play no shot sound."):format(
    weapon.shot, sound.shot, weapon.shot, weapon.shot))
end

local function RegisterPanel()
  local category, layout = Settings.RegisterVerticalLayoutCategory(ns.title)

  for _, group in ipairs(ns.groups) do
    if group.heading then layout:AddInitializer(CreateSettingsListSectionHeaderInitializer(group.heading)) end
    for index, file in ipairs(group.files) do AddFileRow(category, layout, group, index, file) end
  end

  layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Replace Muted Sounds"))
  AddReplaceRow(category)

  layout:AddInitializer(CreateSettingsListSectionHeaderInitializer("Your Shots"))
  for _, weapon in ipairs(ns.groups) do
    for _, sound in ipairs(ns.groups) do
      if weapon.shot and sound.shot then AddPlaysRow(category, weapon, sound) end
    end
  end

  Settings.RegisterAddOnCategory(category)
  categoryID = category:GetID()
end

EventUtil.ContinueOnPlayerLogin(RegisterPanel)

local CHAT_PREFIX = YELLOW_FONT_COLOR:WrapTextInColorCode("[" .. ns.title .. "]:") .. " "
local waitingForCombat = false

local function OpenSettings()
  if not categoryID then return end

  -- C_SettingsUtil.OpenSettingsPanel has restrictions the source does not spell out, so an open in
  -- combat waits for combat to end instead of failing silently.
  if InCombatLockdown() then
    print(CHAT_PREFIX .. "Opens after combat.")
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

SLASH_CLEANRANGEDSOUNDS1, SLASH_CLEANRANGEDSOUNDS2 = "/cleanrangedsounds", "/crs"
SlashCmdList.CLEANRANGEDSOUNDS = OpenSettings

-- Addon Compartment entry points named in the toc. Blizzard calls them with the addon name first, then the menu row.
function CleanRangedSounds_CompartmentClick()
  OpenSettings()
end

function CleanRangedSounds_CompartmentEnter(_, menuButton)
  GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
  GameTooltip_SetTitle(GameTooltip, ns.title)
  GameTooltip_AddInstructionLine(GameTooltip, "Click to open the settings.")
  GameTooltip:Show()
end

function CleanRangedSounds_CompartmentLeave()
  GameTooltip:Hide()
end
