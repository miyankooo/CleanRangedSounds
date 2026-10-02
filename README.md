# CleanBowGunSounds

Mutes the creak of a bow being drawn before every shot, and can play the cleaner bow release sound in place of the looser one. Every other shot sound can be muted on its own in the game's options.

## Features

- The bow pullback is muted as soon as the addon loads, with nothing to set up
- One checkbox per shot sound:

| Setting | What it does | Default |
| --- | --- | --- |
| Bow pullback | Mutes the creak of a bow or crossbow being drawn before each shot | On |
| Bow release | Mutes the twang of a bow or crossbow string as the shot leaves | Off |
| Play release 1 in place of release 2 | Your own shots never play the looser of the game's release sounds; the cleaner first one plays in its place | Off |
| Gun load | Mutes the click of a gun being loaded before each shot | Off |
| Gun fire | Mutes the bang of a gun firing | Off |

- Crossbows play the bow sounds, so the bow rows cover them too
- Every change applies at once, with no reload

## Installation

Drop the `CleanBowGunSounds` folder into the AddOns folder of WoW Forever:

```
World of Warcraft/_classic_beta_/Interface/AddOns/
```

If you used MuteBowSounds, delete its folder. This addon replaces it, and its settings start fresh.

## Settings

Open **Options → AddOns → Clean Bow Gun Sounds**, pick **Clean Bow Gun Sounds** in the addon menu at the minimap, or type `/cleanbowgunsounds` (short form `/cbgs`).

**Play release 1 in place of release 2** sits under **Bow release** and greys out while the release is muted outright, since there is nothing left to swap. **Defaults** mutes the bow pullback only. Settings are saved per account.

## How the release swap works

The game plays one of three release sounds at random on each bow shot. With the swap on, the addon mutes all three. On each of your own bow or crossbow shots it then plays one itself, with the game's odds, except that release 1 plays wherever the game would have picked release 2.

It covers Auto Shot, Shoot Bow and Shoot Crossbow, and every rank of Arcane, Aimed, Multi, Concussive, Distracting, Scatter, Tranquilizing and Sniper Shot, Serpent, Scorpid and Viper Sting, and Black Arrow.

## Requirements

WoW Forever 1.60.x (`## Interface: 16001`). No libraries, no dependencies.

## Restrictions

**Muted for everyone, not only you.** The game mutes a sound wherever it plays, so the bows and guns of other players and of creatures go quiet too.

**The swap only follows your own shots.** While it is on, the bows of other players and creatures play no release sound. The game hides other units' casts from addons, so their shots can't be followed.

**Shot abilities keep their own sounds.** Arcane Shot, Multi-Shot, Serpent Sting and the other shot abilities play spell sounds that many other spells share, such as the Arcane Missiles impact. Muting them would silence those spells as well, so the addon leaves them alone.

**Not yet run in game.** The sound files were taken from the WoW Forever 1.60.1 client data, and every part of the game interface the addon touches was checked against Blizzard's published UI source for 1.60.1. It has not been tested on a live character, and the release swap depends on game behaviour that can only be confirmed there.
