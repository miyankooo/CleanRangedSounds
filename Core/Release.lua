local _, ns = ...

-- Rank 1 of every player spell that fires the ranged weapon (SpellMisc Attributes_0 bit 0x2 on 70374).
-- Matching by the client's own spell name covers every rank and locale, including ranks the DB2 export
-- does not list, such as Multi-Shot 2 to 5. Chimera Shot is a rune spell; an unlearned one never fires.
local SHOT_SPELLS = {
  75, 2480, 7918, 7919, 3044, 19434, 2643, 5116, 20736, 19503, 19801, 1978, 3043, 3034, 3674, 1310687, 409433,
}

local SHOT_BY_WEAPON = {
  [Enum.ItemWeaponSubclass.Bows] = "bow",
  [Enum.ItemWeaponSubclass.Crossbow] = "crossbow",
  [Enum.ItemWeaponSubclass.Guns] = "gun",
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

-- Forever keeps bows and guns in the ranged slot (CharacterRangedSlot in Camelot/PaperDollFrame.xml).
local function RangedShotGroup()
  local itemID = GetInventoryItemID("player", INVSLOT_RANGED)
  if not itemID then return nil end

  local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
  if classID ~= Enum.ItemClass.Weapon then return nil end
  return ns.shotGroups[SHOT_BY_WEAPON[subclassID]]
end

-- Cast info for the player is only secret when Blizzard flags the spell itself, so a secret spell ID is
-- skipped instead of read. The kept files stay muted for the game, so only this pick plays.
local function OnSpellcastSucceeded(_, _, _, _, spellID)
  if IsSecret(spellID) or not shotNames[C_Spell.GetSpellName(spellID) or ""] then return end

  local group = RangedShotGroup()
  local kept = group and ns.KeptFiles(group)
  if kept then ns.PlayFile(kept[math.random(#kept)]) end
end

local listener = CreateFrame("Frame")
listener:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
listener:SetScript("OnEvent", OnSpellcastSucceeded)

-- Spell names are client data, so they are ready once the player is in the world.
EventUtil.ContinueOnPlayerLogin(LoadShotNames)
