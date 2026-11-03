# CleanRangedSounds

Features, settings and restrictions are in `README.md`.

## Target

- Check sound kits, file IDs and spell data against the wago.tools DB2 exports of the current Forever build. wago.tools lists Forever as product `wowf`. Pin queries with `build=1.60.1.<build>` and pass `curl -g` so `filter[Column]` brackets survive.

## Rules

- Every sound file is muted on its own, saved in `CleanRangedSoundsDB.muted[fileID]`. `ns.Refresh` touches a file only when the wanted state differs from what this addon applied. An unticked file stays untouched at load, so another addon's mute is never undone.
- Every mute is idempotent: `UnmuteSoundFile` then `MuteSoundFile`, so one untick undoes it even if mutes are counted or outlive a reload.
- The combat log is closed to addons. `COMBAT_LOG_EVENT_UNFILTERED` is `HasRestrictions` with no payload. Its only reader `C_CombatLogSecure.GetCurrentEventInfo` is `SecureOnly`. `CombatLogGetCurrentEventInfo` points at a `C_CombatLog` function Forever lacks.
- Shots come from `UNIT_SPELLCAST_SUCCEEDED`, registered for `player` with `RegisterUnitEvent`. It is `SecretWhenUnitSpellCastRestricted`: secret for units other than the player or pet and for spells flagged secret, in or out of combat (`SecretPredicatesDocumentation.lua`). Skip a secret spell ID through a `pcall`-wrapped `issecretvalue`.
- Shots match by spell name, read at `PLAYER_LOGIN` from rank-1 IDs, so every rank and locale counts. The list holds the player spells with `SpellMisc` Attributes_0 bit `0x2`, which use the ranged weapon, plus Auto Shot (75) and Shoot (1272941), which lack the bit on 70707.
- Replacement checks the ranged slot only. Forever keeps bows, crossbows and guns there (`CharacterRangedSlot` in `Camelot/PaperDollFrame.xml`).
- Replace Muted Shot Sounds (`replace`, on by default) covers the three Shot groups, picked by the ranged weapon subclass. When some but not all files of a group are muted, `ns.KeptFiles` returns the rest, the whole group is muted for the game and each of your own shots plays a random kept file. Muting one file alone would leave those shots silent. A replacement for unmuted files would double up. Crossbows replace within their own Shot group.
- `ns.PlayFile` plays a file even while this addon mutes it: `UnmuteSoundFile`, `PlaySoundFile(file, "SFX")`, `MuteSoundFile`, in one call. The Play buttons and the replacement share it.
- The repo ships no audio. Blizzard's sound files can't go in a public repo.
- Labels say the action, such as "Mute Pull 1".
- Groups are weapon and phase: Bow Pull and Shot, Crossbow Load and Shot, Gun Load and Shot. Each lists every file of a sound kit on builds 70532 and 70707 (wago.tools SoundKitEntry): the classic files first, then the `spell_hu_*` hunter spell variants, which Forever's newer spells such as Shoot (1272941) and Ricochet use. Files in no kit (bowpullback1 to 3, `sound/item/weapons/gunfire01.ogg`) never play and stay out. A bow has no load sound and a gun no pull sound.
- One row per file, Blizzard's checkbox with a button (`CreateSettingsCheckboxWithButtonInitializer`): the checkbox mutes, Play previews, also while muted. Rows sit under the headers Bow, Crossbow, Gun and Your Shots. No child rows: Blizzard sets child labels in the 10 px `GameFontNormalSmall` (`Blizzard_SettingControls.lua:337`).
- The only chat output is the combat notice when the settings are opened in combat.
- Left out on purpose: the arrow flight and impact sounds, which only NPC shots play.

## Checks

- Run `lua Tests/Sounds.lua` after a change. It covers muting and replacement against stubs.
- Turn on `/console taintLog 1` as well before testing in game.

## Learnings

- Nothing observes a sound. The only sound events are `SOUND_DEVICE_UPDATE` and `SOUNDKIT_FINISHED`, which fires only for handles started with `runFinishCallback`. A replacement needs its own trigger, here the player's own `UNIT_SPELLCAST_SUCCEEDED`.
- `MuteSoundFile`, `UnmuteSoundFile` and `PlaySoundFile` are live globals although Blizzard's UI source never calls them. Absence from the source proves nothing, so settle a global with `strings -a` on the client binary next to a control symbol.

## Release

- `.pkgmeta` also keeps `CLAUDE.md` out of the package.
