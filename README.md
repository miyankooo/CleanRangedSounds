# CleanRangedSounds

Mutes the creak of a bow being drawn before every shot, plus any other bow or gun sound you pick.

## Features

- The bow pullback is muted as soon as the addon loads, with nothing to set up.
- Every sound file on its own row: tick to mute it, click Play to hear it first. Applied at once with no reload.
- Bows, crossbows and guns, each with every phase that has a sound: pull and shot for bows, load and shot for crossbows and guns.
- Mute only the shot sounds you dislike, and your own shots play one you kept, so no shot goes silent.
- Give any weapon the shot sounds of another, or a mix. A gun on crossbow shots sounds silenced.

## Installation

1. Install it with the CurseForge app under WoW Forever, or copy the `CleanRangedSounds` folder into `World of Warcraft/_forever_/Interface/AddOns/`.
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

The game picks one of several files at random for each sound, 3 to 11 per group. Every file has its own row with a Play button.

| Section | Rows | What they mute | Default |
| --- | --- | --- | --- |
| Bow | Mute Pull 1 to 11 | The creak of a bow being drawn before each shot | On |
| Bow | Mute Shot 1 to 8 | The twang of a bow string as the shot leaves | Off |
| Crossbow | Mute Load 1 to 6 | The click of a crossbow being loaded before each shot | Off |
| Crossbow | Mute Shot 1 to 6 | The snap of a crossbow firing | Off |
| Gun | Mute Load 1 to 3 | The click of a gun being loaded before each shot | Off |
| Gun | Mute Shot 1 to 3 | The bang of a gun firing | Off |
| Replace Muted Sounds | Replace Muted Shot Sounds | Keeps your own shots audible when some shot files of your weapon are muted | On |
| Your Shots | Bow, Crossbow and Gun Plays Bow, Crossbow and Gun Shots | Which shot sounds your own shots with each weapon play | Own weapon only |

Each group lists every file a sound kit on Forever can play. In the bow groups the first three are the classic sounds and the rest are the hunter spell variants Forever's newer shots use. A bow has no load sound and a gun no pull sound. Crossbows may also play the bow pull and shot sounds.

The game's own pick can't be read, so muting one shot file alone would leave some of your shots silent. With Replace Muted Shot Sounds on, the addon mutes your weapon's whole shot group instead, and on each of your own shots it plays one of the files you kept. Muting bow Shot 2, the loosest twang, gives a cleaner release.

Each weapon has three Plays rows, one per weapon whose shot sounds it may play. For a silenced gun, tick Gun Plays Crossbow Shots and untick Gun Plays Gun Shots. Tick several rows to mix them, every kept file is equally likely. Muted files never play.

It follows Auto Shot, Shoot, Shoot Bow, Shoot Crossbow and Shoot Gun, and every rank of Arcane, Aimed, Multi, Concussive, Distracting, Scatter, Tranquilizing, Sniper and Chimera Shot, Serpent, Scorpid and Viper Sting, and Black Arrow.

## Requirements

WoW Forever 1.60.x (Interface `16001`). No other addons needed.

## Restrictions

A muted sound is muted for everyone, not only you. The game mutes a sound wherever it plays, so the bows and guns of other players and of creatures go quiet too.

Replace Muted Shot Sounds and the Plays rows only follow your own shots. While your bow, crossbow or gun plays a replaced or swapped sound, that weapon type plays no shot sound for other players and creatures, because the game hides other units' casts from addons.

Shot abilities keep their own sounds. Arcane Shot, Multi-Shot, Serpent Sting and the other shot abilities play spell sounds that many other spells share, such as the Arcane Missiles impact. Muting them would silence those spells as well.

Opening the settings in combat opens them once combat ends.

Typing in the search box of Blizzard's Settings can raise an error that CleanRangedSounds, or another addon with settings, tried to call `IsUserOAuthed()`. Blizzard's own Discord settings cause it, and Ignore is safe.

## License

MIT. See [LICENSE](LICENSE).
