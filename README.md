# DD_GUI

## Mudlet GUI for Dragons Domain MUD

This is the codebase for the [Mudlet](https://www.mudlet.org/)-based GUI used by the [Dragons Domain MUD](https://www.dragons-domain.org/). It is instantiated as a [muddler](https://github.com/demonnic/muddler) project, meaning devs can work on the Lua code (scripts, aliases, triggers etc) outside of the Mudlet client's editor, then compile it into an easily-portable package.


## Installation (players)

To install and use the GUI, connect to the MUD through Mudlet at **dragons-domain.org** on port **8888**. The GUI should automatically install when you connect, and the extra custom content should automatically download after you log in.

You should expect a short delay while content downloads the first time you connect. Downloaded sounds, images, layouts, and other custom content are stored in the profile-owned `DD_GUI_Content` directory, separate from the installable package, so uninstalling and reinstalling the GUI does not remove them. Later connections and package updates reuse the existing content and only download new or changed assets. GUI settings, maps, comms history, and comms tab order are kept with the active Mudlet profile rather than inside the package.

If you have any issues with the automated installation and update system for the GUI, you can type the following at your Mudlet command prompt to install it manually:

`lua installPackage("https://www.dragons-domain.org/main/gui/DD_GUI.mpackage")`


## Uninstall (players)

To uninstall the GUI, you can simply type:

`lua uninstallPackage("DD_GUI")`, use the built-in `ugui` alias, or use Mudlet's graphical package manager. The GUI copies any legacy downloaded content into the profile-owned `DD_GUI_Content` directory before removal when needed. To safely uninstall and reinstall the latest remote package, use `reinstallgui`; it lets the alias return, waits three seconds between the two operations so Mudlet can finish removing the old package, then installs from the canonical `.mpackage` URL and reports the installed package version. The handoff uses profile-level named timers and install/uninstall events so the reinstall callback survives removal of the old package.

## Layout controls

The interface starts with its movable surfaces locked so normal tabs, compass
buttons, and console scrollback receive mouse input. Use `layoutgui` to toggle
layout editing, or `layoutgui on` and `layoutgui off` to choose the state
explicitly.

When layout editing is enabled, the shared red frame edges act as splitters:
dragging a separator resizes the regions on both sides together. This keeps
touching panels on one clean line instead of creating double borders, and
corner/junction markers stay attached as the layout changes. The frame is
drawn independently from the content surfaces, so the room/enemy panel, map,
character sheet, comms, inventory/equipment, affects, main MUD text, and gauge
band can all be resized without tinting or masking their contents. The
navigation compass remains an independently movable square overlay.

The frame uses slim shaded dark-red braid tiles with square junction markers
over a pure-black backing;
the horizontal and vertical repeats are seamless. Gauge-column gaps carry
matching vertical braid dividers with square terminators. It keeps the room/enemy
combat pulse and movement flash states: an active enemy
recolours its owning edges through the combat pulse, while a newly entered
room briefly brightens the travel edge before fading back to the regular
frame colour.
The compass keeps a square shape and room/enemy images keep their 56:30 display
ratio. Leaving layout mode saves the current positions and sizes to the active
Mudlet profile. Use `resetgui` to restore every region to its default geometry.

With layout editing disabled, tabs, compass buttons, and main-window
scrollback remain available for normal play. The main MUD text has a small
additional top inset so its first line does not crowd the frame.


## Interface and data

The GUI is driven by GMCP rather than by scraping ordinary MUD text for panel
data. The main panels are:

- **Room / enemy:** room details and the current enemy, including custom images
  fitted to the 56:30 display frame. Enemy GMCP payloads support both the
  legacy nested-array shape with an `isnpc` identifier and the newer flat-array
  shape with a `vnum` identifier; the enemy hitpoint gauge uses either shape.
  Travel mode keeps the room summary visible as `Area` and `Type` on the first
  line, `Room` on the second, and `Room flags` on the third; empty visible flags
  are shown as `None`. The panel border uses a smoothly graduated multi-step
  red swell and ebb while fighting, and the same soft envelope for the one-shot
  room-entry flash before returning to its regular colour. The combat pulse
  completes in two seconds; the room-entry flash uses a 2.42-second cadence.
  The coloured underlay feathers toward black across each braid edge, keeping
  the glow softer than a solid rectangular strip. It is inset by one pixel on
  each exposed side behind the braid. When combat ends, the enemy image
  slowly fades to black, the next enemy or room image is rendered underneath,
  and the replacement fades back in. Shared edges with the map follow the
  combat colour as well, so the pulse remains continuous around the panel.
  If a new enemy arrives during that transition, combat data takes priority
  and the new image and hitpoint bar appear immediately.
  The braid and square joiners remain visible over that colour instead of
  turning into flat red strips during the pulse; the state colour is painted
  on a separate underlay so the texture cannot suppress it. During normal
  play, the area behind the links remains pure black. The enemy hitpoint gauge is
  combat-only and is explicitly hidden whenever the panel returns to travel
  mode, including after a package rebuild.
- **Map:** the current room and surrounding map data. The embedded mapper has
  even internal padding, and its title is kept to one compact room/vnum line
  with no extra rule beneath it, so northern rooms remain visible even when a
  room name is long. Newly visited areas receive a one-time density-based zoom
  so a sparse map does not collapse into a tiny cluster; manual zoom remains
  persistent. Use `ddmap fit` to refit the current area at any time.
  Mapped quest destinations receive a restrained gold highlight, and selected
  rooms can be routed to, avoided, or centred from the native mapper context
  menu. The mapper consumes DD4's structured `Room.Info` fields: stable
  `area_id` identity, sector and sector text, room flags, room descriptions,
  semantic `tags`, rich exit destinations, door state/name, movement cost,
  arrival direction/kind, and compatible special exits. Tags can add coloured
  semantic markers (`!`, `Q`, `B`, `T`, `H`, `$`, `A`, `V`, `C`, or `S`);
  markers owned by DD_GUI are removed when the server no longer reports the
  corresponding condition, while existing user symbols are preserved.
- **Mapper ownership:** DD_GUI uses its own GMCP/native mapper. During bootstrap
  it removes Mudlet's conflicting `generic_mapper` package, whose obsolete
  updater can otherwise request a dead `versions.lua` URL. The cleanup now runs
  as soon as the DD_GUI folder loads, before the GUI starts its own mapper, so
  the generic package's profile-level `map\autosave.dat` is not loaded beside
  DD_GUI during development reloads. `ddmap cleanup` repeats that removal if a
  local profile still has the old package installed; restart Mudlet afterward if
  it was freezing while reading the generic map.
  The custom mapper accepts both the original direction-to-vnum exit shape and
  the current richer DD4 payload. Native mapper doors are updated with `0`
  (removed), `1` (open), `2` (closed), or `3` (locked); up/down states remain
  available to compass routing through the GUI's per-room cache because older
  Mudlet native door drawing only supports compass-plane directions. Exit
  movement costs bias native pathfinding through per-exit weights, and arrival
  metadata repairs the previous room's outbound link when a newly discovered
  room was previously only an exit stub. DD4 wall exits remain visible as
  non-routable stubs. Existing rooms and hand-corrected
  coordinates are preserved; only rooms created by DD_GUI are eligible for
  stale-link cleanup. The native mapper context menu includes `Show DD4 room
  data`, and `ddmap info` prints the current room's persisted record.
- **Character sheet:** profile image, character details, statistics, and
  resistances.
- **Comms:** communications received from the GMCP `Comm` structure. The `All`
  tab is always first. Other tabs appear only when GMCP reports that the
  character can access and has enabled that channel. Messages include their
  speaker and channel, use the channel's default colour, and channel tabs can
  be dragged to change their order. The order is saved per profile, as is the
  comms history, which is restored after a package reinstall or GUI rebuild.
  Communications are discrete GMCP events and are consumed once; rebuilding
  the GUI restores the saved history without replaying the last event.
- **Inventory / Equipped:** inventory is read from `Char.Items`, including
  quantities; visual item effects are stripped to keep rows compact. The
  inventory view also shows current/max item count and current/max carried
  weight in its lower-right footer. `Equipped`
  is a paper-doll view of every wear slot from `Char.Worn`, showing `[empty]`
  or `[prohibited]` where appropriate for the character's profession, class,
  or current form.
- **Affects / Quest Status:** a two-tab panel beneath Inventory / Equipped.
  `Affects` shows active effects from GMCP, with names left-aligned, modifiers
  centred, and durations aligned at the right edge. `Quest Status` reads
  `Char.Quest` and adapts to available, cooldown, active, and ready-to-return
  states. It shows the objective, target, questgiver, area and room names with
  their vnums, completion and time remaining, current and lifetime quest
  points, and level-gate requirements. The Inventory / Equipped and Affects /
  Quest Status panels share the remaining right-column height equally by
  default.
- **Gauges and compass:** current hits, mana, experience, movement, and the
  clickable navigation compass. The compass includes `EQ` for equipment and
  `SCAN` for scanning. Movement buttons briefly highlight their borders while
  leaving the black cell background unchanged. For mapped rooms, movement
  parses the current MUD `[Exits: ...]` line before sending: plain exits are
  open, `(direction)` is closed, and `[direction]` is locked. A locked exit
  sends `unlock`, `open`, then the movement command in sequence; a closed exit
  sends `open`, then the movement command in sequence. The parsed state is kept per room, with
  Mudlet mapper door data as a fallback when no current Exits line is
  available. If neither source has a state, it sends the normal movement
  command. Status gauges clamp GMCP current values to their reported maximums
  and keep their fills inside their parent panels. Enemy hitpoints are rendered
  in a dedicated overlay below the enemy text, so the red gauge remains visible
  when the enemy console refreshes and disappears outside combat. The compass has the same shared braided
  frame as the main panels, and keyboard/button movement uses the same brief
  border-only pressed highlight.

  Mapper speedwalks now wait for each expected GMCP room transition, stop when
  movement fails or diverges from the known route, include current
  closed/locked door commands, and use the richer exit costs when available.
  `ddmap fast` restores immediate route sending; `ddmap safe` restores
  confirmation-based routing. The existing `[Exits: ...]` parser remains a
  compatibility fallback for sessions or rooms that do not yet provide rich
  exit state through GMCP.
  The `DD_GUI` mapper context menu also provides `Reset selected area's rooms`.
  It asks for an explicit in-console confirmation, then removes the selected
  area's mapped rooms and exits so the area can be remapped from scratch. A
  multi-area selection is rejected, and resetting a different area does not
  disturb the character's current map position. The confirmation expires
  automatically. On current Mudlet versions it opens a visible confirmation
  dialog; if that is unavailable, use the displayed console link or type
  `ddmap reset` (and `ddmap cancel` to cancel).

  The four status gauges use an even inset on all four sides inside the shared
  braided frame, so their black breathing room remains balanced when the gauge
  band is resized.

The main MUD console and panel consoles use the profile's shared scrollbar
style: narrow black tracks have restrained dark-red edges, while the moving
thumb is rendered as a small red square joiner against the black track. The
mapper's native room title uses a transparent background with white text and no
additional accent line, so rooms at the top edge remain visible beneath it.
The mapper's native control strip uses the same visual language: black surfaces,
ivory labels, dark-red edges, and restrained bright-red hover and focus states
for its zoom controls, area selector, and menu button.
Native popup menus use the same profile-wide treatment, including black
surfaces, ivory text, dark-red separators and borders, red hover states, and
matching checked-item and submenu indicators. This covers mapper menus,
dropdown menus, and right-click context menus consistently.

The GUI refreshes these views from the latest GMCP snapshot after login and
reconnect. `bootstrap()` is idempotent for the installed package version, so
running `lua bootstrap()` after reconnect refreshes the existing widgets
without stacking another copy of the interface. When a package update really
does require new widgets, the previous GUI roots are hidden safely before the
new tree is built and then explicitly shown again after Mudlet reuses any named
containers. The enemy hitpoint bar is a direct label overlay rather than a
nested native gauge, which keeps it visible above the enemy console surface.


## Aliases

These aliases are available from the Mudlet command line:

| Alias | Use |
| --- | --- |
| `layoutgui` | Toggle layout editing. |
| `layoutgui on` / `layoutgui off` | Explicitly enable or disable layout editing. |
| `ddguiversion` | Display the installed DD_GUI package version, including on Mudlet builds without `getPackageInfo()`. |
| `resetgui` | Restore all GUI regions to their default positions and sizes. |
| `gcc` | Refresh and download the latest custom content. |
| `ddmap on` / `ddmap off` | Enable or disable the Dragons Domain custom mapper. |
| `ddmap audit` | Report map areas, rooms, overlaps, unnamed rooms, and dangling exits without changing map data. |
| `ddmap fit` | Fit and centre the current mapped area. |
| `ddmap info` / `ddmap room` | Print the current mapped room's persisted DD4 metadata, exits, tags, and door state. |
| `ddmap safe` / `ddmap fast` | Toggle confirmation-based or immediate mapper speedwalks. |
| `ddmap cleanup` | Remove the legacy `generic_mapper` package from the profile before restarting Mudlet. |
| `ddmap reset` / `ddmap cancel` | Confirm or cancel a pending mapper area reset when the dialog/link fallback is used. |
| `ignores` | Preserve the legacy mapper command; the GMCP mapper reports that text ignore patterns are unnecessary when generic_mapper is absent. |
| `ugui` | Uninstall the `DD_GUI` package. |
| `reinstallgui` | Defer the uninstall, wait three seconds, reinstall the latest remote package with a profile-level handoff, and report its installed version without removing downloaded custom content. |


## Keyboard controls

While the GUI is in its normal locked state:

- `Ctrl+Shift+Alt+C` clears the main MUD text window.
- Numeric keypad `7`, `8`, and `9` send equipment, north, and up. The `7`
  and `1` actions also work with Num Lock off, where the keys are reported as
  keypad `Home` and `End`.
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
  package before installing the new `DD_GUI.mpackage` package. The downloaded
  content cache is profile-owned and is retained across this replacement.
- After logging in you should see the latest version of the GUI with any changes you made.

The upload helper reads FTP credentials from the ignored `.dd-gui-ftp.netrc`
file. Keep that file local and never commit or print it.

Keep this README synchronized with significant GUI, alias, keybinding, package,
and workflow changes.

### Development reload recovery

If a local package reload drives Mudlet CPU usage high or leaves it frozen on
`Reading map ... map\autosave.dat`, the profile is still loading the legacy
`generic_mapper` package. Run `ddmap cleanup` once the profile responds, close
and restart Mudlet, and then load DD_GUI again. DD_GUI also guards its own
persistent `dragons_domain_mapper.dat` load so repeated `bootstrap()` calls do
not parse the native map repeatedly in one session. If Mudlet cannot respond
long enough to run the command, make a backup of the profile's
`map\autosave.dat`, rename that file, restart Mudlet, and let DD_GUI rebuild
from its own persistent map; the generic file is not used by DD_GUI.

For smaller changes, you may wish to work in Mudlet's built-in text editor so you can quickly view the changes, then copy the code over to your local `dd-gui` repo after you're satisfied with it before building the package.


## Customising images etc (players)

Currently assets have this storage structure under your Mudlet Profile (which should have a path on Windows like `C:\Users\myusername\.config\mudlet\profiles\TestMudletGuy\`):

```
DD_GUI_Content\
|-- audio\
|-- avatars\
|-- compass\
|-- custom_rooms\
|-- environments\
|-- mobs\
|-- maps\
`-- layout\
```

Profile pictures for avatars are 160x200 pngs that have the following naming structure (all lowercase):
`race_class_sex_number.png` e.g. the first image option for a female human mage would be named `human_mage_female_1.png`.

Custom profile avatars are selected automatically when a matching file exists in
the `DD_GUI_Content\avatars\` directory under the local Mudlet profile. Name the file
after the character in lowercase, such as `abbadon.png`; the GUI uses it before
falling back to the race and sex portrait. Form-specific portraits still take
precedence while shapeshifted.

Compass images you can figure out yourself if you want to change them.  The relevant Lua file is `dd-gui\src\scripts\compass.resize.lua`.

Custom room images use the 56:30 display ratio; 560x300 pngs are recommended and have the naming structure (all lowercase):
`vnum_name_of_room.png`, e.g. `3054_by_the_temple_altar.png`.

Default sector-type based images use the same 56:30 ratio, are stored in `DD_GUI_Content\environments\`, and have the naming structure (all lowercase):
`sectornumber_sect_nameofsectortype.png`, e.g. `9_sect_air.png`.

Custom mobile/enemy images use the 56:30 display ratio; 560x300 pngs are recommended and have the naming structure (all lowercase):
`vnum_name_of_mobile.png`, e.g. `1_puff.png`. Replace any `'`s in the mob's name with an underscore in the image file name.

Maps should be in Mudlet `.dat` format and you will want to edit the `InitialiseMapper.lua` file to make sure they are loaded in for players.


## Customising images, new maps etc (devs)

Custom assets are automatically downloaded by Mudlet from the relevant subdirectories under `https://www.dragons-domain.org/main/gui/custom/`. To add new custom assets (which would be available to all players), you will need FTP access to the webserver; talk to [nerble](https://github.com/nerble) about this.

You can get a list of all current custom content by executing the php script [here](https://www.dragons-domain.org/main/gui/custom/files.php).

