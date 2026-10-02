local _, ns = ...

-- Rank 1 of every player spell that fires the ranged weapon (SpellMisc Attributes_0 bit 0x2 on 70170).
-- Matching by the client's own spell name covers every rank and locale, including ranks the DB2 export
-- does not list, such as Multi-Shot 2 to 5.
local SHOT_SPELLS = {
  75, 2480, 7919, 3044, 19434, 2643, 5116, 14274, 19503, 19801, 1978, 3043, 3034, 3674, 1310687,
}

local BOW_TYPES = {
  [Enum.ItemWeaponSubclass.Bows] = true,
  [Enum.ItemWeaponSubclass.Crossbow] = true,
}

local shotNames = {}

local function LoadShotNames()
  for _, spellID in ipairs(SHOT_SPELLS) do
    local name = C_Spell.GetSpellName(spellID)
    if name then shotNames[name] = true end
  end
end

-- issecretvalue may raise for addon code handed a secret, and a raise can only mean secret.
local function IsSecret(value)
  local ok, secret = pcall(issecretvalue, value)
  return not ok or secret
end

-- Where Forever puts a bow is unverified, so both the ranged slot and the main hand count.
local function HoldsBow()
  for _, slot in ipairs({ INVSLOT_RANGED, INVSLOT_MAINHAND }) do
    local itemID = GetInventoryItemID("player", slot)
    if itemID then
      local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
      if classID == Enum.ItemClass.Weapon and BOW_TYPES[subclassID] then return true end
    end
  end
  return false
end

local function IsSwapping()
  return ns.db[ns.swap.key] and not ns.db[ns.swap.sound.key]
end

-- The pick stays muted for the game and is unmuted only for the one call that plays it. Unverified: that
-- an addon can play a file this way, and that muting it again does not cut the sound short.
local function PlaySwappedRelease()
  local picks = ns.swap.picks
  local file = picks[math.random(#picks)]
  UnmuteSoundFile(file)
  PlaySoundFile(file, "SFX")
  MuteSoundFile(file)
end

-- Cast info for the player is only secret when Blizzard flags the spell itself, so a secret spell ID is
-- skipped instead of read.
local function OnSpellcastSucceeded(_, _, _, _, spellID)
  if not IsSwapping() or IsSecret(spellID) then return end
  if not shotNames[C_Spell.GetSpellName(spellID) or ""] then return end
  if not HoldsBow() then return end

  PlaySwappedRelease()
end

local listener = CreateFrame("Frame")
listener:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
listener:SetScript("OnEvent", OnSpellcastSucceeded)

-- Spell names are client data, so they are ready once the player is in the world.
EventUtil.ContinueOnPlayerLogin(LoadShotNames)
