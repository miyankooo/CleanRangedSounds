-- Checks muting and replacement in Core/Sounds.lua against stubs of the client. Run from the repo root:
-- lua Tests/Sounds.lua
local engineMuted, played, unmutes = {}, {}, 0
function MuteSoundFile(file) engineMuted[file] = true end
function UnmuteSoundFile(file) engineMuted[file] = nil; unmutes = unmutes + 1 end
function PlaySoundFile(file) played[#played + 1] = { file = file, muted = engineMuted[file] == true } end

local onLoaded
EventUtil = { ContinueOnAddOnLoaded = function(_, callback) onLoaded = callback end }
C_AddOns = { GetAddOnMetadata = function() return "Clean Ranged Sounds" end }

local ns = {}
assert(loadfile("Core/Sounds.lua"))("CleanRangedSounds", ns)
-- Saved by 1.1: a broken value, a dropped Modern pull file and the old crossbow default of its own shots.
CleanRangedSoundsDB = {
  plays = { gun = { crossbow = "yes" }, crossbow = { bow = false, crossbow = true, gun = false } },
  muted = { [925291] = true, [567674] = "x" },
  replace = false,
}
onLoaded()

local failures = 0
local function Check(label, condition)
  print((condition and "  pass  " or "  FAIL  ") .. label)
  if not condition then failures = failures + 1 end
end

local function Group(key)
  for _, group in ipairs(ns.groups) do
    if group.key == key then return group end
  end
end

local function AllMuted(group, wanted)
  for _, file in ipairs(group.files) do
    if (engineMuted[file] == true) ~= wanted then return false end
  end
  return true
end

local pull, bowShot, crossbowShot = Group("bowPull"), Group("bowShot"), Group("crossbowShot")
local gunShot, plays = Group("gunShot"), ns.db.plays

local seen, total = {}, 0
for _, group in ipairs(ns.groups) do
  for _, file in ipairs(group.files) do
    total = total + 1
    Check("file " .. file .. " sits in one group only", not seen[file])
    seen[file] = true
  end
end
Check("32 files over five groups, none the game never plays", total == 32 and #ns.groups == 5
  and not Group("bowAim") and not Group("crossbowLoad") and #pull.files == 3)
Check("gun shots keep the classic three first, then the modern sets", gunShot.files[3] == 567722
  and gunShot.files[4] == 921248 and #gunShot.files == 12)
Check("each weapon names its shot group", ns.shotGroups.bow == bowShot and ns.shotGroups.crossbow == crossbowShot
  and ns.shotGroups.gun == gunShot)
Check("the game plays the bow's shots for a crossbow", ns.weaponByKey.crossbow.gameShots == "bow"
  and ns.weaponByKey.bow.gameShots == "bow" and ns.weaponByKey.gun.gameShots == "gun")

local weaponKeys, setsMatch = {}, true
for _, weapon in ipairs(ns.weapons) do weaponKeys[weapon.key] = true end
for _, group in ipairs(ns.groups) do
  local count = 0
  for _, set in ipairs(group.sets) do count = count + set[2] end
  if count ~= #group.files or not weaponKeys[group.weapon] then setsMatch = false end
end
Check("every group belongs to a weapon and its sets name each file once", setsMatch)
Check("rows read by set", ns.FileLabel(pull, 3) == "Classic 3" and ns.FileLabel(pull, 4) == nil
  and ns.FileLabel(gunShot, 4) == "Modern 1" and ns.FileLabel(gunShot, 10) == "Heavy 1"
  and ns.FileLabel(crossbowShot, 1) == "Modern 1")

Check("defaults mute every pull file and nothing else", AllMuted(pull, true) and AllMuted(bowShot, false)
  and AllMuted(crossbowShot, false) and AllMuted(Group("gunLoad"), false))
Check("loading touches only the files it mutes", unmutes == 3)
Check("a dropped file is forgotten and a broken value falls back", ns.db.muted[925291] == nil
  and ns.db.muted[567674] == false)
Check("the old Replace switch is dropped from the saved settings", CleanRangedSoundsDB.replace == nil)
Check("each weapon plays the game's shots, also over a broken saved value", plays.gun.gun
  and plays.gun.crossbow == false and plays.bow.bow and not plays.bow.crossbow and not plays.crossbow.gun)
Check("a crossbow saved by 1.1 starts over on the bow's shots", plays.crossbow.bow and not plays.crossbow.crossbow
  and CleanRangedSoundsDB.version == 2)
Check("as the game picks, the addon plays nothing", ns.ShotFiles("bow") == nil and ns.ShotFiles("crossbow") == nil
  and ns.ShotFiles("gun") == nil and ns.ShotFiles(nil) == nil)

ns.db.muted[567673] = true
ns.Refresh(bowShot)
local kept = ns.ShotFiles("bow")
Check("muting one bow shot keeps the other seven", kept and #kept == 7 and kept[1] == 567674 and kept[2] == 567682)
Check("and mutes the whole group for the game", AllMuted(bowShot, true))
Check("a crossbow, which twangs like a bow, plays the same seven", #ns.ShotFiles("crossbow") == 7)
Check("the crossbow shots stay untouched", AllMuted(crossbowShot, false))

ns.PlayFile(567674)
Check("a muted file plays and is muted again", played[1].file == 567674 and not played[1].muted and engineMuted[567674])

for _, file in ipairs(bowShot.files) do ns.db.muted[file] = true end
ns.Refresh(bowShot)
Check("all muted replaces nothing", ns.ShotFiles("bow") == nil and AllMuted(bowShot, true))

for _, file in ipairs(bowShot.files) do ns.db.muted[file] = false end
plays.crossbow.bow, plays.crossbow.crossbow = false, true
ns.Refresh(bowShot)
local snaps = ns.ShotFiles("crossbow")
Check("a crossbow on crossbow shots plays the six snaps", snaps and #snaps == 6 and snaps[1] == 925549)
Check("and mutes the bow twang instead of doubling it", AllMuted(bowShot, true) and AllMuted(crossbowShot, false))
Check("so a bow plays its own eight through the addon", #ns.ShotFiles("bow") == 8)

ns.db.muted[925549] = true
ns.Refresh(crossbowShot)
Check("an unticked snap is muted and left out", #ns.ShotFiles("crossbow") == 5 and engineMuted[925549]
  and not engineMuted[925551])

ns.db.muted[567677] = false
ns.Refresh(pull)
Check("pull never replaces, a tick unmutes", not engineMuted[567677] and engineMuted[567675])

engineMuted[567719] = true
ns.PlayFile(567719)
Check("a file another addon muted stays muted", engineMuted[567719] and played[2].muted)

plays.gun.gun, plays.gun.crossbow = false, true
ns.Refresh(gunShot)
local silenced = ns.ShotFiles("gun")
Check("a gun on crossbow shots plays the five kept crossbow files", silenced and #silenced == 5
  and silenced[1] == 925551 and AllMuted(gunShot, true))

plays.gun.gun = true
local mixed = ns.ShotFiles("gun")
Check("gun and crossbow shots mix", mixed and #mixed == 17 and mixed[1] == 925551 and mixed[6] == 567721
  and mixed[17] == 1611342)

plays.gun.gun, plays.gun.crossbow = false, false
ns.Refresh(gunShot)
local none = ns.ShotFiles("gun")
Check("a gun with no shot sound ticked stays silent", none and #none == 0 and AllMuted(gunShot, true))

plays.gun.gun = true
ns.Refresh(gunShot)
Check("back on its own shots the gun plays as the game picks", ns.ShotFiles("gun") == nil
  and AllMuted(gunShot, false))

plays.bow.crossbow = true
ns.Refresh(bowShot)
Check("a bow mixing in crossbow shots plays its eight and the five kept snaps", #ns.ShotFiles("bow") == 13)

ns.ResetWeapon("bow")
Check("Defaults resets only the weapon you see", AllMuted(pull, true) and not ns.db.muted[567674]
  and plays.bow.bow and not plays.bow.crossbow and ns.db.muted[925549] and plays.crossbow.crossbow)
Check("while the crossbow plays snaps, the twang stays muted and a bow plays through the addon",
  AllMuted(bowShot, true) and #ns.ShotFiles("bow") == 8)

ns.ResetWeapon("crossbow")
Check("Defaults on the crossbow puts it back on the bow's shots", plays.crossbow.bow and not plays.crossbow.crossbow
  and not ns.db.muted[925549] and AllMuted(crossbowShot, false))
Check("and the game plays every bow and crossbow shot again", AllMuted(bowShot, false)
  and ns.ShotFiles("bow") == nil and ns.ShotFiles("crossbow") == nil)

print(failures == 0 and "Sounds: all checks passed" or ("Sounds: " .. failures .. " failed"))
os.exit(failures == 0 and 0 or 1)
