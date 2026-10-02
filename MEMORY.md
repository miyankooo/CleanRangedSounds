# MuteBowSounds — Memory

Created 2026-10-02 (1.0.0). WoW Forever 1.60.x only, like every addon in this set. Verified against Gethe `forever` @ `9a789c07` (1.60.1.70170), Ketho `forever` @ `4149af64` (1.60.1.70009), and wago.tools DB2 exports for builds 1.60.1.70124 and 1.60.1.70170. The installed client is 1.60.1.70009. Nothing has run in a client yet.

## Current state

Mutes the bow pullback sound by default. Bow release, gun load and gun fire are muted on their own checkboxes in the Blizzard Settings panel (`/mbs`).

| Item | State |
|---|---|
| Version | 1.0.0, `## Interface: 16001`, `## Category: Audio` |
| Icon | `Interface\Icons\INV_Weapon_Bow_05` (file 135493), the icon of the Bows skill (spell 264) in the 70170 `SpellMisc` |
| Author | `miyanko` |
| Git | `main` holds the 1.0.0 commit on `github.com/miyankooo/MuteBowSounds` (public). No `LICENSE`, until the owner picks one |
| Layout | `Core/Sounds.lua` (sound list, saved settings, muting), `UI/Options.lua` (Settings panel, slash command, addon-menu entry). No libraries |
| Saved variables | `MuteBowSoundsDB`, per account, one boolean per sound key |

How it works:

- `ns.SetMuted` calls `MuteSoundFile` or `UnmuteSoundFile` on every file of one sound. Both are in Ketho `forever` `Resources/GlobalAPI.lua`. They are not in the generated API documentation, so no signature or restriction annotation is published.
- `ADDON_LOADED` (through `EventUtil.ContinueOnAddOnLoaded`) fills missing or non-boolean values with the defaults and mutes the ticked sounds. Load never unmutes, so a mute set by another addon is left alone.
- The panel registers at `PLAYER_LOGIN`. Each sound is a `Settings.RegisterProxySetting` boolean with a `Settings.CreateCheckbox` control. `SettingMixin:ApplyValue` calls a proxy's setter only when the value changes (`Blizzard_Settings_Shared/Blizzard_Setting.lua`), so each tick, untick or Defaults click mutes or unmutes once.
- `/mutebowsounds`, `/mbs` and the Addon Compartment entry call `Settings.OpenToCategory(categoryID)`. `/mbs` is not a Blizzard slash command (`GlobalStrings/enUS.lua`), and no installed addon uses it.
- No chat output, so no `[Mute Bow Sounds]:` prefix is needed.

## Sound data

| Sound | Sound kit | Files |
|---|---|---|
| Bow pullback | 1144 | 567675 `bowpullback02`, 567676 `bowpullback03`, 567677 `bowpullback` |
| Bow release | 1146 | 567673 `bowrelease02`, 567674 `bowrelease`, 567682 `bowrelease03` |
| Gun load | 1147 | 567719 `gunload01`, 567720 `gunload02`, 567723 `gunload03` |
| Gun fire | 1148, 288789 | 567718 `gunfire02`, 567721 `gunfire01`, 567722 `gunfire03` |

File names are from the community listfile, under `sound/item/weapons/bow/` and `sound/item/weapons/gun/`. The kit contents are the same on 70124 and 70170.

Why these kits are the player's shot sounds:

- Auto Shot (75) has no `SpellXSpellVisual` row, so the client plays the weapon sounds itself.
- The cosmetic "Poultry Precision" Auto Shot variants copy those weapon kits. Bows (1236221) use visual kits 7 and 164, which play sound kits 1144 and 1146. Crossbows (1236521) use 803 and 804, which also play 1144 and 1146. Guns (1234972) use 161 and 232617, which play 1147 and 288789.
- So crossbows share the bow files. That last step is inferred from the cosmetic copies, not read from a player shot.

Left out on purpose:

- `spell_hu_bowpullback_01`–`08` (925291–925305, kit 268965): no spell visual kit references that kit. If a pullback is still audible in game, add these first.
- `spell_hu_bowrelease_*` (922086–922094) and the `spell_hu_crossbow*` load and shoot files (925307–925317, 925549–925559): only new NPC spells use them, such as Rain of Arrows, Ricochet, Charged Shot, Freezing Arrow and Shoot 1272941.
- Arrow in flight (567680) and arrow impact (567671, 567672, 567681): only NPC shoot spells use them, and the bow variants above don't.
- Shot abilities: their spell sounds are shared files. Counts are from the 70124 tables.
  - The Arcane Shot, Aimed Shot, Concussive Shot, Distracting Shot, Volley and Sniper Shot impact is `arcanemissileimpact1a`–`c`, used by 114 spells.
  - Multi-Shot and Tranquilizing Shot play `recklessnesstarget`, which 20 spells use, including Recklessness and Sunder Armor.
  - Serpent Sting plays `bestowdiseaseimpact`, used by 208 spells.
  - Per-ability toggles would silence all of those spells. They would also need union logic, because the files overlap between abilities.

## Blockers, issues, challenges

1. UNVERIFIED: whether a mute survives a `/reload` or a relog. The addon is correct either way, because ticked sounds are muted again at every load and an untick unmutes at once.
2. UNVERIFIED: whether the client counts mutes. If another addon mutes the same file, unticking here may unmute it for both.
3. UNVERIFIED: that regular shots use the same kits as the Poultry Precision copies (see Sound data).
4. A mute is global, so it applies to every player and creature. The README says so.

## Next steps

1. Run `/console scriptErrors 1` and `/console taintLog 1` first in game.

Offline check: `lua mbs_smoke.lua <addon dir>` in the 2026-10-02 session scratchpad stubs the Forever globals, loads the toc files and exercises load, toggles, Defaults, junk saved values, the slash command and the addon-menu entry. Any other global read raises. It passed 66/66 for 1.0.0. It is not part of the repo.

Forever checks:

- [ ] The AddOns list shows Mute Bow Sounds under Audio with the bow icon, and it is not "out of date".
- [ ] `/mbs`, `/mutebowsounds` and the addon-menu entry open Options → AddOns → Mute Bow Sounds with four checkboxes. Only Bow pullback is ticked on a first login.
- [ ] Auto Shot with a bow: no creak before the shot, and the release still plays.
- [ ] Tick Bow release: the shot is silent. Untick both: both come back at once, with no reload.
- [ ] Auto Shot with a crossbow: the pullback is silent too (issue 3).
- [ ] Auto Shot with a gun: Gun load and Gun fire each mute and unmute.
- [ ] Arcane Shot, Aimed Shot and Multi-Shot with a bow: is the pullback gone on these too?
- [ ] After `/reload` and after a relog, what you hear matches the boxes (issue 1).
- [ ] Defaults leaves only Bow pullback ticked, and its sound is muted again.
- [ ] `taintLog` names MuteBowSounds for nothing after opening the panel and toggling.
