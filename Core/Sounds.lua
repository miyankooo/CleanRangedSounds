local addonName, ns = ...

ns.title = C_AddOns.GetAddOnMetadata(addonName, "Title")

-- Every chat line: the bracketed title in the gold of Blizzard's own chat links (NORMAL_FONT_COLOR), the message in the
-- chat frame's own colour.
function ns.Print(message)
  print(NORMAL_FONT_COLOR:WrapTextInColorCode("[" .. ns.title .. "]") .. ": " .. message)
end

-- Whether a value is safe to read and compare. issecretvalue may raise for addon code handed a secret, and a raise can
-- only mean secret. nil never reaches it.
function ns.CanAccess(value)
  if value == nil then return true end

  local ok, secret = pcall(issecretvalue, value)
  return ok and not secret
end

-- One group per weapon and sound, with every file a sound kit on Forever can pick from at random (SoundKitEntry on
-- 70790). sets names the runs of files in order, so a row reads "Modern 4": the classic files first, then the modern
-- sets from retail WoW, the hunter bow and crossbow variants, the blunderbuss gun shots (kit 232311) and the large gun
-- shots (kit 273183), which the settings page calls Heavy. New files go at the end of their set. Files in no sound kit
-- never play and are left out, such as bowpullback1 to 3, the retail gun reloads (spell_hu_blunderbuss_reload) and
-- bow_cast_oneshot. A bow has no load sound and a gun no pull sound. Shot abilities such as Arcane Shot are left out on
-- purpose: they reuse spell sounds that dozens of other spells share. A shot group's kept files can stand in for a
-- muted file, also for another weapon's shots.
ns.weapons = {
  { key = "bow", label = "Bow" },
  { key = "crossbow", label = "Crossbow" },
  { key = "gun", label = "Gun" },
}

ns.groups = {
  {
    key = "bowPull",
    weapon = "bow",
    label = "Pull",
    tooltip = "The creak of a bow being drawn before each shot. Crossbows may play it too.",
    files = { 567677, 567675, 567676, 925291, 925293, 925295, 925297, 925299, 925301, 925303, 925305 },
    sets = { { "Classic", 3 }, { "Modern", 8 } },
    mutedByDefault = true,
  },
  {
    key = "bowAim",
    weapon = "bow",
    label = "Aim",
    tooltip = "The creak of a drawn bow held while a shot is cast.",
    files = { 567670 },
    sets = { { "Classic", 1 } },
  },
  {
    key = "bowShot",
    weapon = "bow",
    label = "Shot",
    tooltip = "The twang of a bow string as the shot leaves. Crossbows may play it too.",
    files = { 567674, 567673, 567682, 922086, 922088, 922090, 922092, 922094 },
    sets = { { "Classic", 3 }, { "Modern", 5 } },
    shot = true,
  },
  {
    key = "crossbowLoad",
    weapon = "crossbow",
    label = "Load",
    tooltip = "The click of a crossbow being loaded before each shot.",
    files = { 925307, 925309, 925311, 925313, 925315, 925317 },
    sets = { { "Modern", 6 } },
  },
  {
    key = "crossbowShot",
    weapon = "crossbow",
    label = "Shot",
    tooltip = "The snap of a crossbow firing.",
    files = { 925549, 925551, 925553, 925555, 925557, 925559 },
    sets = { { "Modern", 6 } },
    shot = true,
  },
  {
    key = "gunLoad",
    weapon = "gun",
    label = "Load",
    tooltip = "The click of a gun being loaded before each shot.",
    files = { 567719, 567720, 567723 },
    sets = { { "Classic", 3 } },
  },
  {
    key = "gunShot",
    weapon = "gun",
    label = "Shot",
    tooltip = "The bang of a gun firing.",
    files = { 567721, 567718, 567722, 921248, 921250, 921252, 921254, 921256, 921258, 1611340, 1611341, 1611342 },
    sets = { { "Classic", 3 }, { "Modern", 6 }, { "Heavy", 3 } },
    shot = true,
  },
}

ns.shotGroups = {}
for _, group in ipairs(ns.groups) do
  if group.shot then ns.shotGroups[group.weapon] = group end
end

-- The name of a group's file at index, its set and its place in that set, such as "Modern 4".
function ns.FileLabel(group, index)
  for _, set in ipairs(group.sets) do
    if index <= set[2] then return set[1] .. " " .. index end
    index = index - set[2]
  end
end

-- The settings page reads this lazily, so it is safe that it stays empty until ADDON_LOADED.
ns.db = {}

-- What this addon has muted, per file. A file is only touched when its wanted state changes, and an
-- unticked file starts out untouched, so a mute set by another addon is never undone at load.
local mutedByUs = {}

-- The files your own shots with this group's weapon pick from: the kept files of every shot group that weapon
-- plays. The game's own pick cannot be read, so whenever that differs from the game's, the whole group is muted
-- for the game and your own shots play one of these instead (Core/Release.lua). Muting one file alone would leave
-- some of your shots silent. A weapon on its own sounds replaces only when some but not all of its files are
-- muted. Nil when the group plays as the game picks, empty when the weapon plays no kept sound.
function ns.KeptFiles(group)
  if not group.shot then return nil end

  local plays, ownOnly, kept = ns.db.plays[group.weapon], true, {}
  for _, other in ipairs(ns.groups) do
    if other.shot then
      if plays[other.weapon] ~= (other == group) then ownOnly = false end
      if plays[other.weapon] then
        for _, file in ipairs(other.files) do
          if not ns.db.muted[file] then kept[#kept + 1] = file end
        end
      end
    end
  end
  if ownOnly and (#kept == 0 or #kept == #group.files) then return nil end
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
  -- No saved table means the addon's first load on this account. UI/Welcome.lua greets at login.
  ns.firstRun = type(CleanRangedSoundsDB) ~= "table"
  if ns.firstRun then CleanRangedSoundsDB = {} end
  local db = CleanRangedSoundsDB

  if type(db.muted) ~= "table" then db.muted = {} end
  for _, group in ipairs(ns.groups) do
    for _, file in ipairs(group.files) do
      if type(db.muted[file]) ~= "boolean" then db.muted[file] = group.mutedByDefault == true end
    end
  end
  -- Replacement is always on since the canvas page replaced the settings list, so the old switch goes.
  db.replace = nil

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

-- Puts one weapon's sounds back the way a fresh install has them: only the bow pull muted, and the weapon's
-- shots playing its own sounds.
function ns.ResetWeapon(weapon)
  for _, group in ipairs(ns.groups) do
    if group.weapon == weapon then
      for _, file in ipairs(group.files) do ns.db.muted[file] = group.mutedByDefault == true end
    end
  end
  for sound in pairs(ns.shotGroups) do ns.db.plays[weapon][sound] = weapon == sound end
  for _, group in ipairs(ns.groups) do
    if group.weapon == weapon then ns.Refresh(group) end
  end
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
  LoadSettings()
  for _, group in ipairs(ns.groups) do ns.Refresh(group) end
end)
