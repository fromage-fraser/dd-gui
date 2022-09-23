# DD_GUI

## Mudlet GUI for Dragons Domain MUD

This is the codebase for the [Mudlet](https://www.mudlet.org/)-based GUI used by the [Dragons Domain MUD](https://www.dragons-domain.org/). It is instantiated as a [muddler](https://github.com/demonnic/muddler) project, meaning devs can work on the Lua code (scripts, aliases, triggers etc) outside of the Mudlet client's editor, then compile it using muddler into an easily-portable package.


## Installation (players)

To install and use the GUI, connect to the MUD through Mudlet at **dragons-domain.org** on port **8888**. The GUI should automatically install when you connect, and the extra custom content should automatically download after you log in. 

You should expect a short delay for the downloading the first time you connect, but subsequent connections (for the same character) will only download new assets. Currently characters store a new set of code and assets for each profile, but we may try to figure out a way to share unchanging assets between character profiles in the future.

If you have any issues with the automated installation and update system for the GUI, you can type the following at your Mudlet command prompt to install it manually:

`lua installPackage("https://www.dragons-domain.org/main/gui/DD_GUI.mpackage")`


## Uninstall (players)

To uninstall the GUI, you can simply type:

`lua uninstallPackage("DD_GUI")`, use the built-in `ugui` alias, or use Mudlet's graphical package manager.


## Installation (devs)

To do development work on the GUI locally, you will need:
- The `muddler` build tool available [here](https://github.com/demonnic/muddler).
- The latest Java SDK available [here](https://www.oracle.com/java/technologies/downloads/).
- A text editor/IDE to work on it with (most of our devs use [Visual Studio Code](https://code.visualstudio.com/download), but it really doesn't matter).

After you have installed the JVM and muddler (in that order), you should be able to clone this repo into your muddler directory (e.g. `D:\muddle\` for me) and work from `$MUDDLE_DIR\dd-gui\` thereafter.  


## Workflow (devs)

The basic GUI workflow is:

- Make some changes to the GUI codebase.
- Run `muddle` from the terminal in your `dd-gui` directory to build and output the Mudlet package into `build\`.
- Open your Dragons Domain Mudlet test account and install the `DD_GUI.mpackage` package before logging in.
- After login in you should see the latest version of the GUI with any changes you made.

For smaller changes, you may wish to work in Mudlet's built-in text editor so you can quickly view the changes, then copy the code over to your local `dd-gui` repo after you're satisfied with it before building the package.


## Customising images etc (players)
Currently assets have this storage structure under your Mudlet Profile (which should have a path on Windows like `C:\Users\myusername\.config\mudlet\profiles\TestMudletGuy\`):

```
assets->avatars
      |->compass
      |->custom_rooms
      |->environments
      |->mobs
      |->maps
```

Profile pictures for avatars are 160x200 pngs that have the following naming structure (all lowercase):
`race_class_sex_number.png` e.g. the first image option for a female human mage would be named `human_mage_female_1.png`.

If you want a custom avatar (as a player), put it in the `avatars\` directory under your local profile and change the relevant code in `Scripts->DD->UpdateFunctions->update_vitals`.

Compass images you can figure out yourself if you want to change them.  The relevant Lua file is `dd-gui\src\scripts\compass.resize.lua`.

Custom room images are 560x300 pngs and have the naming structure (all lowercase):
`vnum_name_of_room.png`, e.g. `3054_by_the_temple_altar.png`.

Default sector-type based images are 560x300 pngs, are stored in `assets\environments\` and have the naming structure (all lowercase):
`sectornumber_sect_nameofsectortype.png`, e.g. `9_sect_air.png`.

Custom mobile images are 560x300 pngs and have the naming structure (all lowercase):
`vnum_name_of_mobile.png`, e.g. `1_puff.png`.

Maps should be in Mudlet `.dat` format and you will want to edit the `InitialiseMapper.lua` file to make sure they are loaded in for players.


## Customising images, new maps etc (devs)

Custom assets are automatically downloaded by Mudlet from the relevant subdirectories under `https://www.dragons-domain.org/main/gui/custom/`. To add new custom assets (which would be available to all players), you will need FTP access to the webserver; talk to [nerble](https://github.com/nerble) about this.  

You can get a list of all current custom content by executing the php script [here](https://www.dragons-domain.org/main/gui/custom/files.php).


## Usage

Usage of the GUI should be self-explanatory at this point, but we will add information here as and when we introduce features that require elaboration.

