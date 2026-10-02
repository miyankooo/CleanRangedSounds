local addonName, ns = ...

ns.title = "Mute Bow Sounds"

-- One entry per sound a ranged shot makes, with every file the client picks from at random for it.
-- Crossbows play the bow sounds. Shot abilities such as Arcane Shot are left out on purpose: they reuse
-- spell sounds that dozens of other spells share, so muting one would silence those spells as well.
ns.sounds = {
  {
    key = "bowPullback",
    label = "Bow pullback",
    tooltip = "The creak of a bow or crossbow being drawn before each shot.",
    files = { 567675, 567676, 567677 },
    mutedByDefault = true,
  },
  {
    key = "bowRelease",
    label = "Bow release",
    tooltip = "The twang of a bow or crossbow string as the shot leaves.",
    files = { 567673, 567674, 567682 },
    mutedByDefault = false,
  },
  {
    key = "gunLoad",
    label = "Gun load",
    tooltip = "The click of a gun being loaded before each shot.",
    files = { 567719, 567720, 567723 },
    mutedByDefault = false,
  },
  {
    key = "gunFire",
    label = "Gun fire",
    tooltip = "The bang of a gun firing.",
    files = { 567718, 567721, 567722 },
    mutedByDefault = false,
  },
}

-- The settings panel reads this lazily, so it is safe that it stays empty until ADDON_LOADED.
ns.db = {}

-- A muted file is silent wherever it plays, for every player and creature, not only your own shots.
function ns.SetMuted(sound, muted)
  local apply = muted and MuteSoundFile or UnmuteSoundFile
  for _, file in ipairs(sound.files) do
    apply(file)
  end
end

-- A missing or non-boolean value falls back to the default, so a checkbox never shows a state that
-- does not match what is muted.
local function LoadSettings()
  if type(MuteBowSoundsDB) ~= "table" then MuteBowSoundsDB = {} end

  for _, sound in ipairs(ns.sounds) do
    if type(MuteBowSoundsDB[sound.key]) ~= "boolean" then
      MuteBowSoundsDB[sound.key] = sound.mutedByDefault
    end
  end
  ns.db = MuteBowSoundsDB
end

-- Only ticked sounds are touched at load, so a file another addon muted is never unmuted by this one.
local function MuteTicked()
  for _, sound in ipairs(ns.sounds) do
    if ns.db[sound.key] then ns.SetMuted(sound, true) end
  end
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
  LoadSettings()
  MuteTicked()
end)
