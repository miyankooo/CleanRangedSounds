local _, ns = ...

local categoryID

-- A proxy setting calls its setter only when the value really changes, so each tick, untick or Defaults
-- click is applied exactly once.
local function AddCheckbox(category, key, label, tooltip, default, sound)
  local variable = "CLEAN_BOW_GUN_SOUNDS_" .. strupper(key)
  local setting = Settings.RegisterProxySetting(category, variable, Settings.VarType.Boolean, label, default,
    function() return ns.db[key] end,
    function(value)
      ns.db[key] = value
      ns.Refresh(sound)
    end)

  return Settings.CreateCheckbox(category, setting, tooltip)
end

-- The swap sits under the sound it changes and greys out while that sound is muted outright, since
-- there is then nothing left to swap.
local function AddSwapCheckbox(category, parent)
  local swap = ns.swap
  local row = AddCheckbox(category, swap.key, swap.label, swap.tooltip, swap.onByDefault, swap.sound)
  row:SetParentInitializer(parent, function() return not ns.db[swap.sound.key] end)
end

local function RegisterPanel()
  local category = Settings.RegisterVerticalLayoutCategory(ns.title)

  for _, sound in ipairs(ns.sounds) do
    local row = AddCheckbox(category, sound.key, sound.label, sound.tooltip, sound.mutedByDefault, sound)
    if sound == ns.swap.sound then AddSwapCheckbox(category, row) end
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

SLASH_CLEANBOWGUNSOUNDS1, SLASH_CLEANBOWGUNSOUNDS2 = "/cleanbowgunsounds", "/cbgs"
SlashCmdList.CLEANBOWGUNSOUNDS = OpenSettings

-- Addon Compartment entry points named in the toc. Blizzard calls them with the addon name first, then the menu row.
function CleanBowGunSounds_CompartmentClick()
  OpenSettings()
end

function CleanBowGunSounds_CompartmentEnter(_, menuButton)
  GameTooltip:SetOwner(menuButton, "ANCHOR_LEFT")
  GameTooltip_SetTitle(GameTooltip, ns.title)
  GameTooltip_AddInstructionLine(GameTooltip, "Click to open the settings.")
  GameTooltip:Show()
end

function CleanBowGunSounds_CompartmentLeave()
  GameTooltip:Hide()
end
