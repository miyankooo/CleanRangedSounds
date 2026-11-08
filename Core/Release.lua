local _, ns = ...

-- Rank 1 of every player spell that fires the ranged weapon (SpellMisc Attributes_0 bit 0x2 on 70374), plus
-- Auto Shot and Forever's Shoot (1272941), which lack the bit on 70707. A wand's Shoot shares the name but
-- fails the weapon check. Matching by the client's own spell name covers every rank and locale, including
-- ranks the DB2 export does not list, such as Multi-Shot 2 to 5. An unlearned spell never fires.
local SHOT_SPELLS = {
  75, 2480, 7918, 7919, 3044, 19434, 2643, 5116, 20736, 19503, 19801, 1978, 3043, 3034, 3674, 1310687, 409433,
  1272941,
}

local WEAPON_BY_SUBCLASS = {
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

-- The key of the bow, crossbow or gun in your ranged slot, or nil. Forever keeps them there
-- (CharacterRangedSlot in Camelot/PaperDollFrame.xml). The settings page also opens on this weapon's tab.
function ns.EquippedWeapon()
  local itemID = GetInventoryItemID("player", INVSLOT_RANGED)
  if not itemID then return nil end

  local _, _, _, _, _, classID, subclassID = C_Item.GetItemInfoInstant(itemID)
  if classID ~= Enum.ItemClass.Weapon then return nil end
  return WEAPON_BY_SUBCLASS[subclassID]
end

-- Cast info for the player is only secret when Blizzard flags the spell itself, so a secret spell ID is
-- skipped instead of read. The weapon's own shot group stays muted for the game, so only this pick plays.
local function OnSpellcastSucceeded(_, _, _, _, spellID)
  if IsSecret(spellID) or not shotNames[C_Spell.GetSpellName(spellID) or ""] then return end

  local group = ns.shotGroups[ns.EquippedWeapon()]
  local kept = group and ns.KeptFiles(group)
  if kept and #kept > 0 then ns.PlayFile(kept[math.random(#kept)]) end
end

local listener = CreateFrame("Frame")
listener:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
listener:SetScript("OnEvent", OnSpellcastSucceeded)

-- Spell names are client data, so they are ready once the player is in the world.
EventUtil.ContinueOnPlayerLogin(LoadShotNames)
