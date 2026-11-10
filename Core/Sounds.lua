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

-- What Forever plays for a ranged weapon, from its ItemRangedDisplayInfo on 70862: every bow and crossbow draws with
-- sound kit 1144 and fires with kit 1146, every gun loads with 1147 and fires with 1148. So a crossbow creaks and twangs
-- like a bow, and gameShots names the shot group the game plays for each weapon.
ns.weapons = {
  { key = "bow", label = "Bow", gameShots = "bow" },
  { key = "crossbow", label = "Crossbow", gameShots = "bow" },
  { key = "gun", label = "Gun", gameShots = "gun" },
}

ns.weaponByKey = {}
for _, weapon in ipairs(ns.weapons) do ns.weaponByKey[weapon.key] = weapon end

-- One group per weapon tab and sound, with every file of the kit the game picks from at random (SoundKitEntry on
-- 70862). sets names the runs of files in order, so a row reads "Modern 4": the classic files first, then the modern
-- sets from retail WoW. The game plays the modern bow shots only for Shoot (1272941, kit 353467); the crossbow shots
-- (kit 268966), the modern gun shots (kit 232311) and the large gun shots (kit 273183, which the settings page calls
-- Heavy) only sound through this addon's replacement. New files go at the end of their set. Files nothing on Forever
-- plays have no row, since a tick could not bring them back: the retail bow pulls (kit 268965), the bow aim (1145),
-- the crossbow loads (268967 and 374026, whose visual kit 284708 no event starts), bowpullback1 to 3, the retail gun
-- reloads and bow_cast_oneshot. A gun has no pull sound. Shot abilities such as Arcane Shot are left out on purpose:
-- they reuse spell sounds that dozens of other spells share.
ns.groups = {
  {
    key = "bowPull",
    weapon = "bow",
    label = "Pull",
    tooltip = "The creak of a bow or crossbow being drawn before each shot.",
    files = { 567677, 567675, 567676 },
    sets = { { "Classic", 3 } },
    mutedByDefault = true,
  },
  {
    key = "bowShot",
    weapon = "bow",
    label = "Shot",
    tooltip = "The twang of a bow or crossbow string as the shot leaves.",
    files = { 567674, 567673, 567682, 922086, 922088, 922090, 922092, 922094 },
    sets = { { "Classic", 3 }, { "Modern", 5 } },
    shot = true,
  },
  {
    key = "crossbowShot",
    weapon = "crossbow",
    label = "Shot",
    tooltip = "The snap of a crossbow firing. The game never plays it, so it sounds only on your own shots, when a"
      .. " weapon plays Crossbow Shots.",
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

-- The files your own shots with a weapon pick from: the kept files of every shot group it plays. Empty when the
-- weapon plays no kept sound.
local function KeptFiles(weaponKey)
  local plays, kept = ns.db.plays[weaponKey], {}
  for _, group in ipairs(ns.groups) do
    if group.shot and plays[group.weapon] then
      for _, file in ipairs(group.files) do
        if not ns.db.muted[file] then kept[#kept + 1] = file end
      end
    end
  end
  return kept
end

-- Whether the game's own pick is what a weapon should play: only the shot group the game plays for it, with all of
-- that group's files kept or all muted.
local function PlaysAsGame(weapon)
  local plays = ns.db.plays[weapon.key]
  for sound in pairs(ns.shotGroups) do
    if plays[sound] ~= (sound == weapon.gameShots) then return false end
  end
  local kept = #KeptFiles(weapon.key)
  return kept == 0 or kept == #ns.shotGroups[weapon.gameShots].files
end

-- Whether a shot group is muted for the game, so your own shots play through the addon (Core/Release.lua): when any
-- weapon the game plays it for should sound different. The game's pick cannot be read, and muting one file alone
-- would leave some of your shots silent.
local function Replacing(group)
  for _, weapon in ipairs(ns.weapons) do
    if weapon.gameShots == group.weapon and not PlaysAsGame(weapon) then return true end
  end
  return false
end

-- The files your own shots with a weapon play through the addon, or nil when the game plays them itself.
function ns.ShotFiles(weaponKey)
  local weapon = ns.weaponByKey[weaponKey]
  if weapon and Replacing(ns.shotGroups[weapon.gameShots]) then return KeptFiles(weaponKey) end
end

-- A muted file is silent wherever it plays, for every player and creature, not only your own shots.
function ns.Refresh(group)
  local replacing = group.shot == true and Replacing(group)
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

  -- Only listed files keep a saved state, so a file the list dropped is forgotten.
  local saved = type(db.muted) == "table" and db.muted or {}
  db.muted = {}
  for _, group in ipairs(ns.groups) do
    for _, file in ipairs(group.files) do
      if type(saved[file]) == "boolean" then
        db.muted[file] = saved[file]
      else
        db.muted[file] = group.mutedByDefault == true
      end
    end
  end
  -- Replacement is always on since the canvas page replaced the settings list, so the old switch goes.
  db.replace = nil

  -- plays[weapon][sound]: whether your own shots with that weapon play that weapon's shot sounds, by default the ones
  -- the game plays for it. Before version 2 a crossbow's default was the crossbow shots, which the game never plays
  -- for it, so its saved pick starts over.
  if type(db.plays) ~= "table" then db.plays = {} end
  if db.version ~= 2 then db.plays.crossbow = nil end
  db.version = 2
  for _, weapon in ipairs(ns.weapons) do
    if type(db.plays[weapon.key]) ~= "table" then db.plays[weapon.key] = {} end
    local plays = db.plays[weapon.key]
    for sound in pairs(ns.shotGroups) do
      if type(plays[sound]) ~= "boolean" then plays[sound] = sound == weapon.gameShots end
    end
  end
  ns.db = db
end

-- Puts one weapon's sounds back the way a fresh install has them: only the bow pull muted, and the weapon's
-- shots playing the game's own. A crossbow's change reaches the bow's shot group, so every group refreshes.
function ns.ResetWeapon(weaponKey)
  for _, group in ipairs(ns.groups) do
    if group.weapon == weaponKey then
      for _, file in ipairs(group.files) do ns.db.muted[file] = group.mutedByDefault == true end
    end
  end
  for sound in pairs(ns.shotGroups) do
    ns.db.plays[weaponKey][sound] = sound == ns.weaponByKey[weaponKey].gameShots
  end
  for _, group in ipairs(ns.groups) do ns.Refresh(group) end
end

EventUtil.ContinueOnAddOnLoaded(addonName, function()
  LoadSettings()
  for _, group in ipairs(ns.groups) do ns.Refresh(group) end
end)
