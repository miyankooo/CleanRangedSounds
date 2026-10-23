# CleanRangedSounds

Mutes the creak of a bow being drawn before every shot, plus any other bow or gun sound you pick.

## Features

- The bow pullback is muted as soon as the addon loads, with nothing to set up.
- Every sound file on its own row: tick to mute it, click Play to hear it first. Applied at once with no reload.
- Bows, crossbows and guns, each with every phase that has a sound: pull and shot for bows, load and shot for crossbows and guns.
- Mute only the shot sounds you dislike, and your own shots play one you kept, so no shot goes silent.

## Installation

1. Install it with the CurseForge app under WoW Forever, or copy the `CleanRangedSounds` folder into `World of Warcraft/_classic_beta_/Interface/AddOns/`.
2. Restart the game or type `/reload`.
3. Enable CleanRangedSounds in the AddOns list.

## Usage

1. Log in. The bow pullback is already muted.
2. Type `/crs` or pick CleanRangedSounds in the addon menu at the minimap.
3. Click Play to hear a sound, and tick every one you want muted.

## Commands

| Command | Does |
| --- | --- |
| `/cleanrangedsounds` | Opens the settings |
| `/crs` | Short form of `/cleanrangedsounds` |

## Settings

Open Options, AddOns, CleanRangedSounds. Settings are saved per account, and Defaults mutes the bow pullback only.

The game picks one of three files at random for each sound. Every file has its own row with a Play button.

| Section | Rows | What they mute | Default |
| --- | --- | --- | --- |
| Bow | Mute Pull 1 to 11 | The creak of a bow being drawn before each shot | On |
| Bow | Mute Shot 1 to 8 | The twang of a bow string as the shot leaves | Off |
| Crossbow | Mute Load 1 to 6 | The click of a crossbow being loaded before each shot | Off |
| Crossbow | Mute Shot 1 to 6 | The snap of a crossbow firing | Off |
| Gun | Mute Load 1 to 3 | The click of a gun being loaded before each shot | Off |
| Gun | Mute Shot 1 to 3 | The bang of a gun firing | Off |
| Your Shots | Replace Muted Shot Sounds | Keeps your own shots audible when some shot files of your weapon are muted | On |

Each group lists every file a sound kit on Forever can play. In the bow groups the first three are the classic sounds and the rest are the hunter spell variants Forever's newer shots use. A bow has no load sound and a gun no pull sound. Crossbows may also play the bow pull and shot sounds.

The game's own pick can't be read, so muting one shot file alone would leave some of your shots silent. With Replace Muted Shot Sounds on, the addon mutes your weapon's whole shot group instead, and on each of your own shots it plays one of the files you kept. Muting bow Shot 2, the loosest twang, gives a cleaner release.

It follows Auto Shot, Shoot Bow, Shoot Crossbow and Shoot Gun, and every rank of Arcane, Aimed, Multi, Concussive, Distracting, Scatter, Tranquilizing, Sniper and Chimera Shot, Serpent, Scorpid and Viper Sting, and Black Arrow.

## Requirements

WoW Forever 1.60.x (Interface `16001`). No other addons needed.

## Restrictions

A muted sound is muted for everyone, not only you. The game mutes a sound wherever it plays, so the bows and guns of other players and of creatures go quiet too.

Replace Muted Shot Sounds only follows your own shots. While it replaces a group, the bows, crossbows or guns of other players and creatures play no shot sound, because the game hides other units' casts from addons.

Shot abilities keep their own sounds. Arcane Shot, Multi-Shot, Serpent Sting and the other shot abilities play spell sounds that many other spells share, such as the Arcane Missiles impact. Muting them would silence those spells as well.

Opening the settings in combat opens them once combat ends.

## License

MIT. See [LICENSE](LICENSE).
