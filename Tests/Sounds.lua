-- Checks muting and replacement in Core/Sounds.lua against stubs of the client. Run from the repo root:
-- lua Tests/Sounds.lua
local engineMuted, played = {}, {}
function MuteSoundFile(file) engineMuted[file] = true end
function UnmuteSoundFile(file) engineMuted[file] = nil end
function PlaySoundFile(file) played[#played + 1] = { file = file, muted = engineMuted[file] == true } end

local onLoaded
EventUtil = { ContinueOnAddOnLoaded = function(_, callback) onLoaded = callback end }
C_AddOns = { GetAddOnMetadata = function() return "CleanRangedSounds" end }

local ns = {}
assert(loadfile("Core/Sounds.lua"))("CleanRangedSounds", ns)
CleanRangedSoundsDB = nil
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
Check("37 files over six groups", total == 37 and #ns.groups == 6)
Check("each weapon names its shot group", ns.shotGroups.bow == bowShot and ns.shotGroups.crossbow == crossbowShot
  and ns.shotGroups.gun == Group("gunShot"))

Check("defaults mute every pull file and nothing else", AllMuted(pull, true) and AllMuted(bowShot, false)
  and AllMuted(Group("crossbowLoad"), false) and ns.db.replace == true)
Check("a group with nothing muted replaces nothing", ns.KeptFiles(bowShot) == nil)

ns.db.muted[567673] = true
ns.Refresh(bowShot)
local kept = ns.KeptFiles(bowShot)
Check("muting one shot keeps the other seven", kept and #kept == 7 and kept[1] == 567674 and kept[2] == 567682)
Check("and mutes the whole group for the game", AllMuted(bowShot, true))
Check("other weapons stay untouched", AllMuted(crossbowShot, false))

ns.PlayFile(567674)
Check("a muted file plays and is muted again", played[1].file == 567674 and not played[1].muted and engineMuted[567674])

ns.db.replace = false
ns.Refresh(bowShot)
Check("without replacement only the ticked file stays muted", engineMuted[567673] and not engineMuted[567674]
  and ns.KeptFiles(bowShot) == nil)

ns.db.replace = true
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

print(failures == 0 and "Sounds: all checks passed" or ("Sounds: " .. failures .. " failed"))
os.exit(failures == 0 and 0 or 1)
