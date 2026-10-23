# CleanRangedSounds

## Target

- WoW Forever 1.60.x only, `## Interface: 16001`. No client branches, no `WOW_PROJECT_*`, no compat layer.
- Verify every API against Gethe `wow-ui-source` and Ketho `BlizzardInterfaceResources`, branch `forever`.
- Check sound kits, file IDs and spell data against the wago.tools DB2 exports of the current Forever build.

## Rules

- Every sound file is muted on its own, saved in `CleanRangedSoundsDB.muted[fileID]`. `ns.Refresh` touches a file only when the wanted state differs from what this addon applied. An unticked file stays untouched at load, so another addon's mute is never undone.
- Every mute is idempotent: `UnmuteSoundFile` then `MuteSoundFile`, so one untick undoes it even if mutes are counted or outlive a reload.
- The combat log is closed to addons. `COMBAT_LOG_EVENT_UNFILTERED` is `HasRestrictions` with no payload, its only reader `C_CombatLogSecure.GetCurrentEventInfo` is `SecureOnly`, and `CombatLogGetCurrentEventInfo` points at a `C_CombatLog` function Forever lacks.
- Shots come from `UNIT_SPELLCAST_SUCCEEDED`, registered for `player` with `RegisterUnitEvent`. It is `SecretWhenUnitSpellCastRestricted`: secret for units other than the player or pet and for spells flagged secret, in or out of combat (`SecretPredicatesDocumentation.lua`). Skip a secret spell ID through a `pcall`-wrapped `issecretvalue`.
- Shots match by spell name, read at `PLAYER_LOGIN` from rank-1 IDs, so every rank and locale counts. The list holds the player spells with `SpellMisc` Attributes_0 bit `0x2`, which use the ranged weapon.
- Replacement checks the ranged slot only. Forever keeps bows, crossbows and guns there (`CharacterRangedSlot` in `Camelot/PaperDollFrame.xml`).
- Replace Muted Shot Sounds (`replace`, on by default) covers the three Shot groups, picked by the ranged weapon subclass. When some but not all files of a group are muted, `ns.KeptFiles` returns the rest, the whole group is muted for the game and each of your own shots plays a random kept file. Muting one file alone would leave those shots silent, and a replacement for unmuted files would double up.
- `ns.PlayFile` plays a file even while this addon mutes it: `UnmuteSoundFile`, `PlaySoundFile(file, "SFX")`, `MuteSoundFile`, in one call. The Play buttons and the replacement share it.
- The repo ships no audio. Blizzard's sound files can't go in a public repo.
- Labels are Title Case and say the action ("Mute Pull 1"). Tooltips are sentences.
- Groups are weapon and phase: Bow Pull and Shot, Crossbow Load and Shot, Gun Load and Shot. Each lists every file of a sound kit on build 70532 (wago.tools SoundKitEntry, 2026-10-22): the classic files first, then the `spell_hu_*` hunter spell variants, which Forever's newer spells such as Shoot (1272941) and Ricochet use. Files in no kit (bowpullback1 to 3, `sound/item/weapons/gunfire01.ogg`) never play and stay out. A bow has no load sound and a gun no pull sound.
- One row per file, Blizzard's checkbox with a button (`CreateSettingsCheckboxWithButtonInitializer`): the checkbox mutes, Play previews, also while muted. Rows sit under the headers Bow, Crossbow, Gun and Your Shots. No child rows: Blizzard sets child labels in the 10 px `GameFontNormalSmall` (`Blizzard_SettingControls.lua:337`). No native dropdowns: picking in one taints Blizzard's own settings until /reload on build 70532 (2026-10-21).
- Chat output only when the settings are opened in combat: "Opens after combat." with the shared yellow `[CleanRangedSounds]:` prefix from `YELLOW_FONT_COLOR`. The settings then open on `PLAYER_REGEN_ENABLED`.
- Left out on purpose: the arrow flight and impact sounds, which only NPC shots play.
- The toc version stays 1.0.0 until the first CurseForge release.
- Licence: MIT (LICENSE).

## Checks

- Run `luac -p` on every Lua file and `lua Tests/Sounds.lua` after a change. The check covers muting and replacement against stubs.
- Turn on `/console scriptErrors 1` and `/console taintLog 1` before testing in game.
