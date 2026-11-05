local addonName, ns = ...

ns.title = C_AddOns.GetAddOnMetadata(addonName, "Title")

-- One group per weapon and phase, with every file a sound kit on Forever can pick from at random. The first files
-- of each bow and gun group are the classic ones, the rest are the hunter spell variants Forever's newer shots use.
-- Files in no sound kit, like bowpullback1 to 3, never play and are left out. A bow has no load sound and a gun no
-- pull sound. Shot abilities such as Arcane Shot are left out on purpose: they reuse spell sounds that dozens of
-- other spells share. shot names the weapon whose own shots can replace a muted file.
ns.groups = {
  {
    key = "bowPull",
    heading = "Bow",
    label = "Pull",
    tooltip = "The creak of a bow being drawn before each shot. Crossbows may play it too.",
    files = { 567677, 567675, 567676, 925291, 925293, 925295, 925297, 925299, 925301, 925303, 925305 },
    mutedByDefault = true,
  },
  {
    key = "bowShot",
    label = "Shot",
    tooltip = "The twang of a bow string as the shot leaves. Crossbows may play it too.",
    files = { 567674, 567673, 567682, 922086, 922088, 922090, 922092, 922094 },
    shot = "bow",
  },
  {
    key = "crossbowLoad",
    heading = "Crossbow",
    label = "Load",
    tooltip = "The click of a crossbow being loaded before each shot.",
    files = { 925307, 925309, 925311, 925313, 925315, 925317 },
  },
  {
    key = "crossbowShot",
    label = "Shot",
    tooltip = "The snap of a crossbow firing.",
    files = { 925549, 925551, 925553, 925555, 925557, 925559 },
    shot = "crossbow",
  },
  {
    key = "gunLoad",
    heading = "Gun",
    label = "Load",
    tooltip = "The click of a gun being loaded before each shot.",
    files = { 567719, 567720, 567723 },
  },
  {
    key = "gunShot",
    label = "Shot",
    tooltip = "The bang of a gun firing.",
    files = { 567721, 567718, 567722 },
    shot = "gun",
  },
}

ns.shotGroups = {}
for _, group in ipairs(ns.groups) do
  if group.shot then ns.shotGroups[group.shot] = group end
end

-- The settings panel reads this lazily, so it is safe that it stays empty until ADDON_LOADED.
ns.db = {}

-- What this addon has muted, per file. A file is only touched when its wanted state changes, and an
-- unticked file starts out untouched, so a mute set by another addon is never undone at load.
local mutedByUs = {}

-- The files your own shots with this group's weapon pick from: the kept files of every shot group that weapon
-- plays. The game's own pick cannot be read, so whenever that differs from the game's, the whole group is muted
-- for the game and your own shots play one of these instead (Core/Release.lua). A weapon on its own sounds only
-- replaces when replacement is on and some but not all of its files are muted. Nil when the group plays as the
-- game picks, empty when the weapon plays no kept sound.
function ns.KeptFiles(group)
  if not group.shot then return nil end

  local plays, ownOnly, kept = ns.db.plays[group.shot], true, {}
  for _, other in ipairs(ns.groups) do
    if other.shot then
      if plays[other.shot] ~= (other == group) then ownOnly = false end
      if plays[other.shot] then
        for _, file in ipairs(other.files) do
          if not ns.db.muted[file] then kept[#kept + 1] = file end
        end
      end
    end
  end
  if ownOnly and (not ns.db.replace or #kept == 0 or #kept == #group.files) then return nil end
  return kept
end

-- A muted file is silent wherever it plays, for every player and creature, not only your own shots.
function ns.Refresh(group)
  local replacing = ns.KeptFiles(group) ~= nil
  for _, file in ipairs(group.files) do
    local muted = ns.db.muted[file] or replacing
    if (mutedByUs[file] == true) ~= muted then
      -- Unmuting before each mute keeps it single even if mutes are counted and outlive a reload, so
      -- one untick always brings the sound back.
      UnmuteSoundFile(file)
      if muted then MuteSoundFile(file) end
      mutedByUs[file] = muted
    end
  end
end

-- Plays one file, even one this addon muted: unmute, play and mute again in one call. A file another
-- addon muted stays muted. Unverified: that the second mute does not cut the sound short.
function ns.PlayFile(file)
  local muted = mutedByUs[file]
  if muted then UnmuteSoundFile(file) end
  PlaySoundFile(file, "SFX")
  if muted then MuteSoundFile(file) end
end

-- A missing or non-boolean value falls back to the default, so a checkbox never shows a state that
-- does not match what is muted.
local function LoadSettings()
  if type(CleanRangedSoundsDB) ~= "table" then CleanRangedSoundsDB = {} end
  local db = CleanRangedSoundsDB

  if type(db.muted) ~= "table" then db.muted = {} end
  for _, group in ipairs(ns.groups) do
    for _, file in ipairs(group.files) do
      if type(db.muted[file]) ~= "boolean" then db.muted[file] = group.mutedByDefault == true end
    end
  end
  if type(db.replace) ~= "boolean" then db.replace = true end

  -- plays[weapon][sound]: whether your own shots with that weapon play that weapon's shot sounds.
  if type(db.plays) ~= "table" then db.plays = {} end
  for weapon in pairs(ns.shotGroups) do
    if type(db.plays[weapon]) ~= "table" then db.plays[weapon] = {} end
    for sound in pairs(ns.shotGroups) do
      if type(db.plays[weapon][sound]) ~= "boolean" then db.plays[weapon][sound] = weapon == sound end
    end
  end
  ns.db = db
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
  LoadSettings()
  for _, group in ipairs(ns.groups) do ns.Refresh(group) end
end)
