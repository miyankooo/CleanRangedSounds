# CleanBowGunSounds

## Target

- WoW Forever 1.60.x only, `## Interface: 16001`. No client branches, no `WOW_PROJECT_*`, no compat layer.
- Verify every API against Gethe `wow-ui-source` and Ketho `BlizzardInterfaceResources`, branch `forever`.
- Check sound kits, file IDs and spell data against the wago.tools DB2 exports of the current Forever build.

## Rules

- `ns.Refresh` calls `MuteSoundFile` or `UnmuteSoundFile` only when the wanted state differs from what this addon applied. An unticked sound stays untouched at load, so another addon's mute is never undone.
- The combat log is closed to addons. `COMBAT_LOG_EVENT_UNFILTERED` is `HasRestrictions` with no payload, its only reader `C_CombatLogSecure.GetCurrentEventInfo` is `SecureOnly`, and `CombatLogGetCurrentEventInfo` points at a `C_CombatLog` function Forever lacks.
- Shots come from `UNIT_SPELLCAST_SUCCEEDED`, registered for `player` with `RegisterUnitEvent`. It is `SecretWhenUnitSpellCastRestricted`: secret for units other than the player or pet and for spells flagged secret, in or out of combat (`SecretPredicatesDocumentation.lua`). Skip a secret spell ID through a `pcall`-wrapped `issecretvalue`.
- Shots match by spell name, read at `PLAYER_LOGIN` from rank-1 IDs, so every rank and locale counts. The list holds the player spells with `SpellMisc` Attributes_0 bit `0x2`, which use the ranged weapon.
- The swap mutes all three release files and plays its own pick by file ID: `UnmuteSoundFile`, `PlaySoundFile(file, "SFX")`, `MuteSoundFile`, in one call. Muting release 2 alone fails: the game still plays 1 or 3 on two shots in three, so a replacement would double up.
- The repo ships no audio. Blizzard's sound files can't go in a public repo.
- No chat output. A line added later starts with the shared yellow `[Clean Bow Gun Sounds]:` prefix from `YELLOW_FONT_COLOR`.
- Left out on purpose: the `spell_hu_bowpullback_*`, `spell_hu_bowrelease_*` and `spell_hu_crossbow*` files, whose kits no player shot uses, and the arrow flight and impact sounds, which only NPC shots play.

## Checks

- Run `luac -p` on every Lua file after a change. The repo has no test harness.
- Turn on `/console scriptErrors 1` and `/console taintLog 1` before testing in game.
