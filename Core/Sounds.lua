local addonName, ns = ...

ns.title = "Clean Bow Gun Sounds"

-- One entry per sound a ranged shot makes, with every file the client picks from at random for it.
-- Crossbows play the bow sounds. Shot abilities such as Arcane Shot are left out on purpose: they reuse
-- spell sounds that dozens of other spells share, so muting one would silence those spells as well.
local bowRelease = {
  key = "bowRelease",
  label = "Bow release",
  tooltip = "The twang of a bow or crossbow string as the shot leaves.",
  files = { 567674, 567673, 567682 },
  mutedByDefault = false,
}

ns.sounds = {
  {
    key = "bowPullback",
    label = "Bow pullback",
    tooltip = "The creak of a bow or crossbow being drawn before each shot.",
    files = { 567675, 567676, 567677 },
    mutedByDefault = true,
  },
  bowRelease,
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

-- The game picks release 1 (bowrelease), 2 (bowrelease02) or 3 (bowrelease03) with equal odds. The swap
-- mutes all three and replays the game's odds with release 2's share given to release 1, because the
-- game's own pick cannot be read and muting release 2 alone would leave a third of shots silent.
ns.swap = {
  key = "releaseSwap",
  label = "Play release 1 in place of release 2",
  tooltip = "Your own bow and crossbow shots never play the looser second release sound; the first plays"
    .. " in its place. While this is on, the bows of other players and creatures play no release sound.",
  sound = bowRelease,
  picks = { 567674, 567674, 567682 },
  onByDefault = false,
}

-- The settings panel reads this lazily, so it is safe that it stays empty until ADDON_LOADED.
ns.db = {}

-- What this addon has muted, per sound. A file is only touched when its wanted state changes, and an
-- unticked sound starts out untouched, so a mute set by another addon is never undone at load.
local mutedByUs = {}

local function WantsMuted(sound)
  return ns.db[sound.key] or (sound == ns.swap.sound and ns.db[ns.swap.key])
end

-- A muted file is silent wherever it plays, for every player and creature, not only your own shots.
function ns.Refresh(sound)
  local muted = WantsMuted(sound) == true
  if (mutedByUs[sound] == true) == muted then return end

  local apply = muted and MuteSoundFile or UnmuteSoundFile
  for _, file in ipairs(sound.files) do
    apply(file)
  end
  mutedByUs[sound] = muted
end

local function LoadBoolean(key, default)
  if type(CleanBowGunSoundsDB[key]) ~= "boolean" then
    CleanBowGunSoundsDB[key] = default
  end
end

-- A missing or non-boolean value falls back to the default, so a checkbox never shows a state that
-- does not match what is muted.
local function LoadSettings()
  if type(CleanBowGunSoundsDB) ~= "table" then CleanBowGunSoundsDB = {} end

  for _, sound in ipairs(ns.sounds) do
    LoadBoolean(sound.key, sound.mutedByDefault)
  end
  LoadBoolean(ns.swap.key, ns.swap.onByDefault)
  ns.db = CleanBowGunSoundsDB
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
  LoadSettings()
  for _, sound in ipairs(ns.sounds) do
    ns.Refresh(sound)
  end
end)
