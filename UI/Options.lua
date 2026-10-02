local _, ns = ...

local categoryID

-- A proxy setting calls its setter only when the value really changes, so each tick, untick or Defaults
-- click mutes or unmutes a sound exactly once.
local function AddSoundCheckbox(category, sound)
  local variable = "MUTE_BOW_SOUNDS_" .. strupper(sound.key)
  local setting = Settings.RegisterProxySetting(category, variable, Settings.VarType.Boolean, sound.label,
    sound.mutedByDefault,
    function() return ns.db[sound.key] end,
    function(muted)
      ns.db[sound.key] = muted
      ns.SetMuted(sound, muted)
    end)

  Settings.CreateCheckbox(category, setting, sound.tooltip)
end

local function RegisterPanel()
  local category = Settings.RegisterVerticalLayoutCategory(ns.title)

  for _, sound in ipairs(ns.sounds) do
    AddSoundCheckbox(category, sound)
  end

  Settings.RegisterAddOnCategory(category)
  categoryID = category:GetID()
end

EventUtil.ContinueOnPlayerLogin(RegisterPanel)

local function OpenSettings()
  if categoryID then
    Settings.OpenToCategory(categoryID)
  end
end

SLASH_MUTEBOWSOUNDS1, SLASH_MUTEBOWSOUNDS2 = "/mutebowsounds", "/mbs"
SlashCmdList.MUTEBOWSOUNDS = OpenSettings

-- Addon Compartment entry points named in the toc. Blizzard calls them with the addon name first, then the menu row.
function MuteBowSounds_CompartmentClick()
  OpenSettings()
end

function MuteBowSounds_CompartmentEnter(_, menuButton)
  GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
  GameTooltip_SetTitle(GameTooltip, ns.title)
  GameTooltip_AddInstructionLine(GameTooltip, "Click to open the settings.")
  GameTooltip:Show()
end

function MuteBowSounds_CompartmentLeave()
  GameTooltip:Hide()
end
