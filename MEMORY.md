# CleanBowGunSounds — Memory

Updated 2026-10-02 (2.0.0). Renamed from MuteBowSounds (1.0.0, same day). The BowReleaseSwap proof of concept is merged in as the release swap. WoW Forever 1.60.x only, like every addon in this set. Verified against Gethe `forever` @ `9a789c07` (1.60.1.70170), Ketho `forever` @ `4149af64` (1.60.1.70009), WeakAuras2 `main` @ `e9e9e9b0`, and wago.tools DB2 exports for builds 1.60.1.70124 and 1.60.1.70170. The installed client is 1.60.1.70009. Nothing has run in a client yet.

## Current state

Mutes the bow pullback by default. Bow release, gun load and gun fire can each be muted, and "Play release 1 in place of release 2" swaps the release on your own bow shots. Everything is in the Blizzard Settings panel (`/cbgs`).

| Item | State |
|---|---|
| Version | 2.0.0, `## Interface: 16001`, `## Category: Audio` |
| Icon | `Interface\Icons\INV_Weapon_Bow_05` (file 135493), the icon of the Bows skill (spell 264) in the 70170 `SpellMisc` |
| Author | `miyanko` |
| Git | `main` on `github.com/miyankooo/CleanBowGunSounds` (public), renamed from `MuteBowSounds`. GitHub redirects the old URL. No `LICENSE`, until the owner picks one |
| Layout | `Core/Sounds.lua` (sound list, swap definition, saved settings, muting), `Core/Release.lua` (shot detection and the swapped play), `UI/Options.lua` (Settings panel, slash command, addon-menu entry). No libraries |
| Saved variables | `CleanBowGunSoundsDB`, per account, one boolean per sound key plus `releaseSwap`. `MuteBowSoundsDB` is not migrated: 1.0.0 never ran in a client |

History: 1.0.0 shipped as MuteBowSounds with the four mute checkboxes. The owner asked for the release swap to be part of it, and for the name CleanBowGunSounds (2.0.0, a new folder and new saved variables).

## How it works

Muting:

- `ns.Refresh(sound)` mutes a sound's files when its own box is ticked, or, for the bow release, when the swap is on. It unmutes when neither is true.
- It only calls `MuteSoundFile` or `UnmuteSoundFile` when that wanted state changes from what this addon applied. An unticked sound starts out untouched, so load never unmutes another addon's mute.
- `ADDON_LOADED` (through `EventUtil.ContinueOnAddOnLoaded`) fills missing or non-boolean values with the defaults, then refreshes every sound.

Settings panel:

- It registers at `PLAYER_LOGIN`. Every row is a `Settings.RegisterProxySetting` boolean with a `Settings.CreateCheckbox` control.
- `SettingMixin:ApplyValue` calls a proxy's setter only when the value changes (`Blizzard_Settings_Shared/Blizzard_Setting.lua`).
- The swap row uses `SetParentInitializer(releaseRow, predicate)`. That nests it under Bow release and greys it out while the release is muted outright (`SettingsElementHierarchyMixin`, `Blizzard_SettingControls.lua:120`).

Release swap (`Core/Release.lua`):

1. On `UNIT_SPELLCAST_SUCCEEDED`, registered for `player` with `RegisterUnitEvent`, it skips a secret spell ID through a `pcall`-wrapped `issecretvalue`.
2. It looks up the spell's name with `C_Spell.GetSpellName` and checks it against the names of 15 rank-1 shot spells. Those are the player spells with `SpellMisc` Attributes_0 bit 0x2 (uses the ranged weapon) on 70170. The names are read at `PLAYER_LOGIN`, so every rank and locale matches, including ranks missing from the DB2 export (Multi-Shot 2–5).
3. It checks for a bow or crossbow (`Enum.ItemWeaponSubclass` Bows 2, Crossbow 18) in `INVSLOT_RANGED` (18) or `INVSLOT_MAINHAND` (16).
4. It picks from `{567674, 567674, 567682}` and plays the pick by file ID: `UnmuteSoundFile`, then `PlaySoundFile(file, "SFX")`, then `MuteSoundFile`, in the same call.

Other:

- `/cleanbowgunsounds`, `/cbgs` and the Addon Compartment entry call `Settings.OpenToCategory(categoryID)`. `/cbgs` is not a Blizzard slash command (`GlobalStrings/enUS.lua`), and no installed addon uses it.
- No chat output, so no `[Clean Bow Gun Sounds]:` prefix is needed.

## Sound data

| Sound | Sound kit | Files (pick weight) |
|---|---|---|
| Bow pullback | 1144 | 567677 `bowpullback` (1), 567675 `bowpullback02` (1), 567676 `bowpullback03` (0, never picked on 70170; muted anyway) |
| Bow release | 1146 | 567674 `bowrelease` = release 1 (1), 567673 `bowrelease02` = release 2 (1), 567682 `bowrelease03` = release 3 (1). VolumeFloat 0.69, MinDistance 8 |
| Gun load | 1147 | 567719, 567720, 567723 |
| Gun fire | 1148, 288789 | 567718, 567721, 567722 |

The owner hears release 2 as "a bit loose" and wants release 1 in its place. The numbering is the kit's entry order. The owner still has to confirm by ear which file is the loose one; if it is release 3, the picks become `{567674, 567673, 567674}`.

Why these kits are the player's shot sounds:

- Auto Shot (75) has no `SpellXSpellVisual` row, so the client plays the weapon sounds itself.
- The cosmetic "Poultry Precision" Auto Shot variants copy those weapon kits. Bows (1236221) use visual kits 7 and 164, which play sound kits 1144 and 1146. Crossbows (1236521) use 803 and 804, which also play 1144 and 1146. Guns (1234972) use 161 and 232617, which play 1147 and 288789.
- The owner confirmed that the release plays on every Auto Shot.

Left out on purpose:

- `spell_hu_bowpullback_*` (925291–925305), `spell_hu_bowrelease_*` (922086–922094) and the `spell_hu_crossbow*` files: only kits that no player shot uses reference them.
- Arrow in flight (567680) and arrow impact (567671, 567672, 567681): only NPC shoot spells use them.
- Shot ability spell sounds: they are shared files. The Arcane Shot impact `arcanemissileimpact1a`–`c` is used by 114 spells, Multi-Shot's `recklessnesstarget` by 20 and Serpent Sting's `bestowdiseaseimpact` by 208 (counts from the 70124 tables).

## Release swap: options weighed (2026-10-02)

| Option | Verdict |
|---|---|
| Combat log trigger | Impossible for addons, in and out of combat. `COMBAT_LOG_EVENT_UNFILTERED` is `HasRestrictions` with no payload. The only reader is `C_CombatLogSecure.GetCurrentEventInfo` (`Environment = "SecureOnly"`), and Blizzard reads it from `Blizzard_CombatLogProcessor` (`UseSecureEnvironment: 1`). The deprecated `CombatLogGetCurrentEventInfo` alias points at a `C_CombatLog` function Forever doesn't have |
| Own cast event | Used. `UNIT_SPELLCAST_SUCCEEDED` is `SecretWhenUnitSpellCastRestricted`: secret only for units other than the player or pet, or for spells flagged secret, with no combat condition (`SecretPredicatesDocumentation.lua`) |
| Mute release 2 only | Doesn't work: the game still picks 1 or 3 on two shots in three, so the replacement would double up |
| Other players' shots | Impossible: their cast info is secret |
| A WeakAura | Impossible: WeakAuras2 `main` ships Vanilla, TBC, Wrath, Cata and Mists tocs only, `Init.lua` knows no Forever flavor, and the retail tocs were removed on 2026-01-28 |
| A game file identical to release 1 | None. Eight candidates (`spell_hu_bowrelease_01`–`05`, `spell_hu_crossbowshoot_01`–`03`) correlate 0.10–0.21 with it |
| Bundled copies of the three files | Would work whatever the mute rules are, but they are Blizzard's audio and can't go in a public repo. The PoC used them; copies at 0.69 volume can be rebuilt from wago.tools (`/api/casc/<fileID>?download&version=1.60.1.70170`) with `sox in.ogg -C 6 out.ogg vol 0.69` |
| Play the game's file ID with a same-frame unmute | Chosen: no assets, publishable. Unverified, see issue 1 |

## Blockers, issues, challenges

1. UNVERIFIED: whether `UnmuteSoundFile`, `PlaySoundFile`, `MuteSoundFile` in the same call is audible. If the mute is checked when a sound starts, it works. If addon plays ignore mutes, it also works. It fails, with your shots then having no release at all, if muting again cuts the sound short, or if the sound starts after the Lua call returns. The fallback is the local copies (see the table).
2. UNVERIFIED: whether Forever fires `UNIT_SPELLCAST_SUCCEEDED` on every Auto Shot. WeakAuras' classic swing timer relies on it (`GenericTrigger.lua`, `reset_ranged_swing_spells`).
3. The swap plays at full file volume, not the kit's 0.69, so it may be about 3 dB louder. It is also not positional, and its timing follows the cast event.
4. UNVERIFIED: whether a mute survives a `/reload` or a relog, and whether mutes are counted. The addon is correct either way for its own state.
5. UNVERIFIED: whether the bow sits in the ranged slot or the main hand on Forever. Both are accepted.
6. A mute is global, so with the swap on, other bows have no release. The README says so.
7. The season rune shots (Chimera, Kill, Explosive, Steady Shot) are not in the shot list. Whether Forever has them is unknown.

## Next steps

1. Run `/console scriptErrors 1` and `/console taintLog 1` first in game.

Offline check: `lua cbgs_smoke.lua <addon dir>` in the 2026-10-02 session scratchpad stubs the Forever globals and loads the toc files. It covers load, the mute boxes, the swap and its overlap with the Bow release mute, the nested row, Defaults, junk saved values, the slash command and the addon-menu entry. Any other global read raises. It passed 69/69 for 2.0.0, and caught a load-time unmute bug before the commit. It is not part of the repo.

Forever checks:

- [ ] The AddOns list shows Clean Bow Gun Sounds under Audio with the bow icon, and it is not "out of date". The MuteBowSounds folder is deleted.
- [ ] `/cbgs`, `/cleanbowgunsounds` and the addon-menu entry open the panel. It has five rows, with the swap nested under Bow release. Only Bow pullback is ticked.
- [ ] Auto Shot with a bow: no creak before the shot, and the game's release still plays.
- [ ] Tick the swap and Auto Shot ten times. Each shot has one release, never the loose one (issues 1 and 2). If shots go silent, issue 1 failed: switch to local copies.
- [ ] The same with Arcane Shot, Multi-Shot and Aimed Shot, and in combat in a dungeon.
- [ ] Timing and level of the swapped release against the game's own (issue 3).
- [ ] Tick Bow release: the swap row greys out and shots are silent. Untick it: the swap works again.
- [ ] A crossbow swaps too. With a gun, Gun load and Gun fire each mute and unmute, and nothing swaps.
- [ ] After `/reload` and after a relog, what you hear matches the boxes (issue 4).
- [ ] Defaults leaves only Bow pullback ticked.
- [ ] `taintLog` names CleanBowGunSounds for nothing after opening the panel, toggling and shooting.
