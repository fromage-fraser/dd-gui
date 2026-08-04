# DD_GUI

## Mudlet GUI for Dragons Domain MUD

This is the codebase for the [Mudlet](https://www.mudlet.org/)-based GUI used by the [Dragons Domain MUD](https://www.dragons-domain.org/). It is instantiated as a [muddler](https://github.com/demonnic/muddler) project, meaning devs can work on the Lua code (scripts, aliases, triggers etc) outside of the Mudlet client's editor, then compile it into an easily-portable package.


## Installation (players)

To install and use the GUI, connect to the MUD through Mudlet at **dragons-domain.org** on port **8888**. The GUI should automatically install when you connect, and the extra custom content should automatically download after you log in.

You should expect a short delay while content downloads the first time you connect, but subsequent connections for the same character will only download new assets. GUI settings, maps, comms history, and comms tab order are kept with the active Mudlet profile rather than inside the package.

If you have any issues with the automated installation and update system for the GUI, you can type the following at your Mudlet command prompt to install it manually:

`lua installPackage("https://www.dragons-domain.org/main/gui/DD_GUI.mpackage")`


## Uninstall (players)

To uninstall the GUI, you can simply type:

`lua uninstallPackage("DD_GUI")`, use the built-in `ugui` alias, or use Mudlet's graphical package manager.

## Layout controls

The interface starts with its movable surfaces locked so normal tabs, compass
buttons, and console scrollback receive mouse input. Use `layoutgui` to toggle
layout editing, or `layoutgui on` and `layoutgui off` to choose the state
explicitly.

When layout editing is enabled, the red-bordered regions can be dragged and
resized. This includes the room/enemy panel, map, character sheet, comms,
inventory/equipment, affects, main MUD text, navigation compass, and gauges.
The compass keeps a square shape and room/enemy images keep their 56:30 display
ratio. Leaving layout mode saves the current positions and sizes to the active
Mudlet profile. Use `resetgui` to restore every region to its default geometry.

With layout editing disabled, tabs, compass buttons, and main-window
scrollback remain available for normal play.


## Interface and data

The GUI is driven by GMCP rather than by scraping ordinary MUD text for panel
data. The main panels are:

- **Room / enemy:** room details and the current enemy, including custom images
  fitted to the 56:30 display frame.
- **Map:** the current room and surrounding map data.
- **Character sheet:** profile image, character details, statistics, and
  resistances.
- **Comms:** communications received from the GMCP `Comm` structure. The `All`
  tab is always first. Other tabs appear only when GMCP reports that the
  character can access and has enabled that channel. Messages include their
  speaker and channel, use the channel's default colour, and channel tabs can
  be dragged to change their order. The order is saved per profile, as is the
  comms history, which is restored after a package reinstall or GUI rebuild.
- **Inventory / Equipped:** inventory is read from `Char.Items`, including
  quantities; visual item effects are stripped to keep rows compact. `Equipped`
  is a paper-doll view of every wear slot from `Char.Worn`, showing `[empty]`
  or `[prohibited]` where appropriate for the character's profession, class,
  or current form.
- **Affects:** active affects from GMCP, with names left-aligned, modifiers
  centred, and durations aligned at the right edge.
- **Gauges and compass:** current hits, mana, experience, movement, and the
  clickable navigation compass. The compass includes `EQ` for equipment and
  `SCAN` for scanning. Movement buttons briefly highlight their borders while
  leaving the black cell background unchanged. For mapped rooms, movement
  parses the current MUD `[Exits: ...]` line before sending: plain exits are
  open, `(direction)` is closed, and `[direction]` is locked. A locked exit
  sends `unlock`, `open`, then the movement command; a closed exit sends
  `open`, then the movement command. The parsed state is kept per room, with
  Mudlet mapper door data as a fallback when no current Exits line is
  available. If neither source has a state, it sends the normal movement
  command.

The GUI refreshes these views from the latest GMCP snapshot after login and
reconnect. If a manual rebuild is needed, run `lua bootstrap()` in Mudlet.


## Aliases

These aliases are available from the Mudlet command line:

| Alias | Use |
| --- | --- |
| `layoutgui` | Toggle layout editing. |
| `layoutgui on` / `layoutgui off` | Explicitly enable or disable layout editing. |
| `resetgui` | Restore all GUI regions to their default positions and sizes. |
| `gcc` | Refresh and download the latest custom content. |
| `ddmap on` / `ddmap off` | Enable or disable the Dragons Domain custom mapper. |
| `ignores` | Add the Dragons Domain portal message to the mapper's ignore patterns. |
| `ugui` | Uninstall the `DD_GUI` package. |


## Keyboard controls

While the GUI is in its normal locked state:

- `Ctrl+Shift+Alt+C` clears the main MUD text window.
- Numeric keypad `7`, `8`, and `9` send equipment, north, and up.
- Numeric keypad `4`, `5`, and `6` send west, look, and east.
- Numeric keypad `1`, `2`, and `3` send scan, south, and down. Each action
  briefly highlights its corresponding compass button.
- Keypad `Up`, `Down`, `Left`, and `Right` move north, south, west, and east.
- Keypad `PgUp` and `PgDn` move up and down.
- Keypad `Clear` looks, and keypad `Insert` scans.


## Installation (devs)

To do development work on the GUI locally, you will need:

- The Java SDK version 8, 11, 17, or 18, available [here](https://www.oracle.com/java/technologies/downloads/).  I've been unable to get it working with version 19 as of 31/12/22, so I'd avoid that one.
- The `muddler` build tool available [here](https://github.com/demonnic/muddler).  If you're working in Windows, by far the easiest method to get it working is [here](https://github.com/demonnic/muddler/wiki/Installation#basic-installation).
- A text editor/IDE to work on it with (most of our devs use [Visual Studio Code](https://code.visualstudio.com/download), but it really doesn't matter).

After you have installed the JVM and muddler (in that order), you should be able to clone this repo into your muddler directory (e.g. `D:\muddle\` for me) and work from `$MUDDLE_DIR\dd-gui\` thereafter.


## Workflow (devs)

The basic GUI workflow is:

- Make some changes to the GUI codebase.
- Run `.\scripts\build-and-upload.ps1` from the repository root. This invokes muddler, builds `build\DD_GUI.mpackage` and `build\DD_GUI.xml`, and uploads both files to the production GUI directory.
- In the Dragons Domain Mudlet test account, uninstall the existing `DD_GUI`
  package before installing the new `DD_GUI.mpackage` package.
- After logging in you should see the latest version of the GUI with any changes you made.

The upload helper reads FTP credentials from the ignored `.dd-gui-ftp.netrc`
file. Keep that file local and never commit or print it.

Keep this README synchronized with significant GUI, alias, keybinding, package,
and workflow changes.

For smaller changes, you may wish to work in Mudlet's built-in text editor so you can quickly view the changes, then copy the code over to your local `dd-gui` repo after you're satisfied with it before building the package.


## Customising images etc (players)

Currently assets have this storage structure under your Mudlet Profile (which should have a path on Windows like `C:\Users\myusername\.config\mudlet\profiles\TestMudletGuy\`):

```
assets\
|-- avatars\
|-- compass\
|-- custom_rooms\
|-- environments\
|-- mobs\
`-- maps\
```

Profile pictures for avatars are 160x200 pngs that have the following naming structure (all lowercase):
`race_class_sex_number.png` e.g. the first image option for a female human mage would be named `human_mage_female_1.png`.

If you want a custom avatar (as a player), put it in the `avatars\` directory under your local profile and change the relevant code in `Scripts->DD->UpdateFunctions->update_vitals`.

Compass images you can figure out yourself if you want to change them.  The relevant Lua file is `dd-gui\src\scripts\compass.resize.lua`.

Custom room images use the 56:30 display ratio; 560x300 pngs are recommended and have the naming structure (all lowercase):
`vnum_name_of_room.png`, e.g. `3054_by_the_temple_altar.png`.

Default sector-type based images use the same 56:30 ratio, are stored in `assets\environments\`, and have the naming structure (all lowercase):
`sectornumber_sect_nameofsectortype.png`, e.g. `9_sect_air.png`.

Custom mobile/enemy images use the 56:30 display ratio; 560x300 pngs are recommended and have the naming structure (all lowercase):
`vnum_name_of_mobile.png`, e.g. `1_puff.png`. Replace any `'`s in the mob's name with an underscore in the image file name.

Maps should be in Mudlet `.dat` format and you will want to edit the `InitialiseMapper.lua` file to make sure they are loaded in for players.


## Customising images, new maps etc (devs)

Custom assets are automatically downloaded by Mudlet from the relevant subdirectories under `https://www.dragons-domain.org/main/gui/custom/`. To add new custom assets (which would be available to all players), you will need FTP access to the webserver; talk to [nerble](https://github.com/nerble) about this.

You can get a list of all current custom content by executing the php script [here](https://www.dragons-domain.org/main/gui/custom/files.php).

