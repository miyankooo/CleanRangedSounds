# MuteBowSounds

Mutes the creak of a bow being drawn before every shot. Each other shot sound can be muted and unmuted on its own in the game's options.

## Features

- The bow pullback is muted as soon as the addon loads, with nothing to set up
- Four shot sounds, each with its own checkbox:

| Sound | What you hear | Default |
| --- | --- | --- |
| Bow pullback | The creak of a bow or crossbow being drawn before each shot | Muted |
| Bow release | The twang of a bow or crossbow string as the shot leaves | Plays |
| Gun load | The click of a gun being loaded before each shot | Plays |
| Gun fire | The bang of a gun firing | Plays |

- Crossbows play the bow sounds, so the two bow rows cover them too
- Unticking a sound brings it back at once, with no reload

## Installation

Drop the `MuteBowSounds` folder into the AddOns folder of WoW Forever:

```
World of Warcraft/_classic_beta_/Interface/AddOns/
```

## Settings

Open **Options → AddOns → Mute Bow Sounds**, pick **Mute Bow Sounds** in the addon menu at the minimap, or type `/mutebowsounds` (short form `/mbs`).

Tick a sound to mute it, untick it to hear it again. **Defaults** mutes the bow pullback only. Settings are saved per account.

## Requirements

WoW Forever 1.60.x (`## Interface: 16001`). No libraries, no dependencies.

## Restrictions

**Muted for everyone, not only you.** The game mutes a sound wherever it plays, so the bows and guns of other players and of creatures go quiet too.

**Shot abilities keep their own sounds.** Arcane Shot, Multi-Shot, Serpent Sting and the other shot abilities play spell sounds that many other spells share, such as the Arcane Missiles impact. Muting them would silence those spells as well, so the addon leaves them alone.

**Not yet run in game.** The sound files were taken from the WoW Forever 1.60.1 client data, and every part of the game interface the addon touches was checked against Blizzard's published UI source for 1.60.1. It has not been tested on a live character.
