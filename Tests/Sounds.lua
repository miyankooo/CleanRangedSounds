-- Checks muting and replacement in Core/Sounds.lua against stubs of the client. Run from the repo root:
-- lua Tests/Sounds.lua
local engineMuted, played = {}, {}
function MuteSoundFile(file) engineMuted[file] = true end
function UnmuteSoundFile(file) engineMuted[file] = nil end
function PlaySoundFile(file) played[#played + 1] = { file = file, muted = engineMuted[file] == true } end

local onLoaded
EventUtil = { ContinueOnAddOnLoaded = function(_, callback) onLoaded = callback end }
C_AddOns = { GetAddOnMetadata = function() return "Clean Ranged Sounds" end }

local ns = {}
assert(loadfile("Core/Sounds.lua"))("CleanRangedSounds", ns)
CleanRangedSoundsDB = { plays = { gun = { crossbow = "yes" } }, replace = false }
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

local seen, total = {}, 0
for _, group in ipairs(ns.groups) do
  for _, file in ipairs(group.files) do
    total = total + 1
    Check("file " .. file .. " sits in one group only", not seen[file])
    seen[file] = true
  end
end
Check("47 files over seven groups", total == 47 and #ns.groups == 7)
Check("gun shots keep the classic three first, then the modern sets", Group("gunShot").files[3] == 567722
  and Group("gunShot").files[4] == 921248 and #Group("gunShot").files == 12)
Check("each weapon names its shot group", ns.shotGroups.bow == bowShot and ns.shotGroups.crossbow == crossbowShot
  and ns.shotGroups.gun == Group("gunShot"))

local weaponKeys, setsMatch = {}, true
for _, weapon in ipairs(ns.weapons) do weaponKeys[weapon.key] = true end
for _, group in ipairs(ns.groups) do
  local count = 0
  for _, set in ipairs(group.sets) do count = count + set[2] end
  if count ~= #group.files or not weaponKeys[group.weapon] then setsMatch = false end
end
Check("every group belongs to a weapon and its sets name each file once", setsMatch)
Check("rows read by set", ns.FileLabel(pull, 3) == "Classic 3" and ns.FileLabel(pull, 11) == "Modern 8"
  and ns.FileLabel(Group("gunShot"), 4) == "Modern 1" and ns.FileLabel(Group("gunShot"), 10) == "Heavy 1"
  and ns.FileLabel(crossbowShot, 1) == "Modern 1" and ns.FileLabel(pull, 12) == nil)

Check("defaults mute every pull file and nothing else", AllMuted(pull, true) and AllMuted(bowShot, false)
  and AllMuted(Group("crossbowLoad"), false))
Check("the old Replace switch is dropped from the saved settings", CleanRangedSoundsDB.replace == nil)
Check("a group with nothing muted replaces nothing", ns.KeptFiles(bowShot) == nil)

ns.db.muted[567673] = true
ns.Refresh(bowShot)
local kept = ns.KeptFiles(bowShot)
Check("muting one shot keeps the other seven", kept and #kept == 7 and kept[1] == 567674 and kept[2] == 567682)
Check("and mutes the whole group for the game", AllMuted(bowShot, true))
Check("other weapons stay untouched", AllMuted(crossbowShot, false))

ns.PlayFile(567674)
Check("a muted file plays and is muted again", played[1].file == 567674 and not played[1].muted and engineMuted[567674])

for _, file in ipairs(bowShot.files) do ns.db.muted[file] = true end
ns.Refresh(bowShot)
Check("all muted replaces nothing", ns.KeptFiles(bowShot) == nil and AllMuted(bowShot, true))

ns.db.muted[925549] = true
ns.Refresh(crossbowShot)
local crossbowKept = ns.KeptFiles(crossbowShot)
Check("a crossbow keeps its own five", crossbowKept and #crossbowKept == 5 and AllMuted(crossbowShot, true))

ns.db.muted[567677] = false
ns.Refresh(pull)
Check("pull never replaces, an untick unmutes", ns.KeptFiles(pull) == nil and not engineMuted[567677])

engineMuted[567719] = true
ns.PlayFile(567719)
Check("a file another addon muted stays muted", engineMuted[567719] and played[2].muted)

local gunShot, plays = Group("gunShot"), ns.db.plays
Check("each weapon plays only its own shots, also over a broken saved value", plays.gun.gun
  and plays.gun.crossbow == false and plays.bow.bow and not plays.bow.crossbow and not plays.crossbow.gun)

plays.gun.gun, plays.gun.crossbow = false, true
ns.Refresh(gunShot)
local silenced = ns.KeptFiles(gunShot)
Check("a gun on crossbow shots plays the five kept crossbow files", silenced and #silenced == 5
  and silenced[1] == 925551 and AllMuted(gunShot, true))

plays.gun.gun = true
local mixed = ns.KeptFiles(gunShot)
Check("gun and crossbow shots mix", mixed and #mixed == 17 and mixed[1] == 925551 and mixed[6] == 567721
  and mixed[17] == 1611342)

plays.gun.gun, plays.gun.crossbow = false, false
ns.Refresh(gunShot)
local none = ns.KeptFiles(gunShot)
Check("a gun with no shot sound ticked stays silent", none and #none == 0 and AllMuted(gunShot, true))

plays.gun.gun = true
ns.Refresh(gunShot)
Check("back on its own shots the gun plays as the game picks", ns.KeptFiles(gunShot) == nil
  and AllMuted(gunShot, false))

plays.bow.crossbow = true
local borrowed = ns.KeptFiles(bowShot)
Check("a bow with every own shot muted plays the five kept crossbow files", borrowed and #borrowed == 5
  and borrowed[1] == 925551)

ns.ResetWeapon("bow")
Check("Defaults resets only the weapon you see", AllMuted(pull, true) and AllMuted(bowShot, false)
  and not engineMuted[567670] and plays.bow.bow and not plays.bow.crossbow and ns.KeptFiles(bowShot) == nil
  and ns.db.muted[925549] and AllMuted(crossbowShot, true))

print(failures == 0 and "Sounds: all checks passed" or ("Sounds: " .. failures .. " failed"))
os.exit(failures == 0 and 0 or 1)
