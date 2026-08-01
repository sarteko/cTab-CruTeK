# cTab CruTeK

![cTab CruTeK](img/cover.jpeg)

An **extension for [cTAB Advanced [BETA]](https://steamcommunity.com/sharedfiles/filedetails/?id=3438246217)** by GrueArbre. It adds *Cam on Galaxy*: live video from helmet cams, turrets, vehicles and drones rendered **inside the Samsung Galaxy screen**, in render-to-texture, both on the open phone and on the small always-on-screen one.

It started as a standalone fork of the original cTab and grew, along the way, into an eighth component that plugs into cTAB Advanced. It **adds** to that mod, it does not replace it: their tablet, messaging and compass stay theirs.

---

## Contents

- [What it adds](#what-it-adds)
- [Requirements](#requirements)
- [Installation](#installation)
- [Using it](#using-it)
  - [What you need to carry](#what-you-need-to-carry)
  - [The menu](#the-menu)
  - [Controls](#controls)
- [Settings](#settings)
  - [cTab-Cam on Galaxy](#ctab-cam-on-galaxy)
  - [cTab-Drones](#ctab-drones)
  - [cTab-HelmetCam](#ctab-helmetcam)
- [Diagnostics](#diagnostics)
- [Technical notes](#technical-notes)
- [Building the PBO](#building-the-pbo)
- [Credits](#credits)

---

## What it adds

On top of cTAB Advanced:

- **Cam on Galaxy** — an ACE menu tree to connect the Galaxy to a video source and watch it on the phone screen
- **Sources**: operator helmet cams, and turrets on planes, helicopters, drones, tanks, cars and boats
- **Turret slewing** on unmanned drones, straight from the video
- **Stepped zoom** read from the vehicle's own optics
- **Permissions by side, vehicle category and occupant type**, all in the addon options, so they are set per mission

Nothing of cTAB Advanced is touched or overwritten.

![Drone feed on the Galaxy](img/sc1.jpeg)

*A drone feed inside the phone screen, with your telemetry along the top and the source along the bottom.*

---

## Requirements

| Mod | Required |
|---|---|
| **[cTAB Advanced [BETA]](https://steamcommunity.com/sharedfiles/filedetails/?id=3438246217)** | yes, this is an extension of it |
| **CBA_A3** | yes |
| **ACE3** | yes, the menu is an ACE self-interaction menu |

**PiP** must be enabled in every player's video options: that is what draws the feed inside the phone screen. With PiP off the screen stays black.

> Do not load the original cTab by Gundy. cTAB Advanced already replaces that one, and this extension is built for cTAB Advanced.

---

## Installation

Like any mod: a `@cTab_CruTeK` folder containing `addons\ctab_camera.pbo`, ticked in the launcher **alongside** cTAB Advanced, not instead of it.

The items are unchanged — `ItemcTab`, `ItemAndroid`, `ItemMicroDAGR`, `ItemcTabHCam` — so missions written for cTab keep working untouched.

---

## Using it

### What you need to carry

**To watch**: the **Samsung Galaxy** (`ItemAndroid`) in your inventory. That is the screen the feed comes out on.

**To be watched**:

| Source | What is needed |
|---|---|
| Helmet cam | the **`ItemcTabHCam`** item carried by the operator |
| Turrets and drones | nothing carried: what matters is the vehicle, its side and who is aboard |

The helmet cam item class is configurable in the settings if you use a different one.

![Helmet cam at night](img/sc3.jpeg)

*OpCam on an operator using night vision: your own telemetry along the top, the carrier's name along the bottom.*

### The menu

**ACE self-interaction** menu, entry **Cam on Galaxy**. It only shows up if you are carrying the Galaxy.

```
Cam on Galaxy
├── OpCam                 operator helmet cams
├── AircraftCam
│   ├── Drone
│   ├── Plane
│   └── Heli
├── VehiclesCam
│   ├── Drone
│   ├── Tank
│   └── Car
├── BoatsCam
│   ├── Drone
│   └── Boat
└── Hide feed / Show feed again
```

Empty branches and categories are not drawn: if there are no helicopters around, the Heli branch does not appear. Only vehicles allowed by the settings make the list.

Drones get their own entry inside every environment, and that is not cosmetic: they are the only ones whose turret you can slew.

![ACE self-interaction menu](img/sc2.jpeg)

*Each branch carries the number of sources currently available, so you know whether it is worth opening before you open it.*

### Controls

Always active, nothing to bind:

| Control | Effect |
|---|---|
| Right mouse held on the video | slews the turret — unmanned drones only, open phone only |
| `Shift` + wheel | next / previous operator — OpCam only |

Bound by default, rebindable from the **cTab Camera** section of the CBA keybinds:

| Key | Effect |
|---|---|
| `Shift` + right / left arrow | next / previous vision filter |
| `Shift` + `End` | hide the video |
| `Shift` + `Delete` | disconnect |

Registered but with **no default key**, bind them yourself if you want them: next operator, previous operator, turret slew.

All of these only respond **while a feed is running**. With no feed the combination falls through and steals nothing from other mods.

---

## Settings

Everything lives in the **addon options**, in three separate categories. They are mission settings, so you set them once per scenario from the editor.

### cTab-Cam on Galaxy

Applies to crewed vehicles.

**Observable sides** — own, BLUFOR, OPFOR, Independent, Civilian. Default: own, BLUFOR and Civilian.

**Vehicle categories** — air, land, sea. All on.

**Who must be aboard** — four values, first one is the default:

| Value | Meaning |
|---|---|
| player or AI | anyone will do |
| players only | a player must be aboard |
| AI only | an AI must be aboard |
| empty vehicles too | no check at all |

> "Empty vehicles too" is not the default for a reason: the turret of an empty vehicle sits wherever it was left, and the feed points nowhere useful.

**Gameplay limits** — maximum distance from the source (4000 m), minimum altitude, and a minimum view distance while a feed is running.

> View distance is a **single global value** for all rendering: raising it for the feed also raises your own real view while the feed is open. It defaults to `0`, meaning the mod does not touch it. It never lowers it, it stays under the ACE view distance limiter's own maximum, and it raises the object view distance in the same proportion you already had.

### cTab-Drones

A category of its own, because on a drone the crew question is meaningless: **whoever commands a drone sits at the terminal, not aboard**. A drone's crew is always AI, even while you are flying it.

- master switch for the drone category
- its own set of sides, independent from the vehicle ones
- **who commands the drone**: player or AI, players only, AI only — this reads who is connected at the terminal
- its own maximum distance (6000 m)
- turret slewing on or off

### cTab-HelmetCam

- master switch
- **item class** required, `ItemcTabHCam` by default
- maximum distance (2000 m)
- **who carries the cam**: player or AI, players only, AI only
- its own set of sides

---

## Diagnostics

On startup, in the `.rpt`:

```
[crutek_dcam] versione 2026-08-01-c2
```

If that line is missing, the module did not start.

### Troubleshooting

| Symptom | What to check |
|---|---|
| the Cam on Galaxy menu never appears | are you carrying the Galaxy (`ItemAndroid`)? are cTAB Advanced and ACE loaded? |
| black phone screen | is PiP enabled in the video options? |
| a vehicle is missing from the list | is its side enabled? is the category on? is it within maximum distance? does it satisfy the who-must-be-aboard rule? |
| an operator is missing | does he carry `ItemcTabHCam`? is his side among the observable ones in cTab-HelmetCam? |
| right mouse does not slew | it only works on **unmanned** drones and with the phone open, and slewing must be enabled in cTab-Drones |
| grainy image | that is the PiP video setting, and it is per player |

---

## Technical notes

**The feed fills the whole phone screen.** No side bars, even at the cost of framing wider than the real optic would.

**The HUD is two bands.** The top one is your own telemetry — your altitude, your heading, your grid. The bottom one is the feed — vision filter, magnification, source name. White text with a black outline, green only in night vision.

**The operator's zoom is the limit.** When you connect you start where he is looking, and from there you can only zoom in. The steps are the discrete optics the vehicle declares in its config, so the feed sits where the operator's optic would sit.

**Thermals are the engine's own.** TH1 is white hot, TH2 is black hot. A3TI is not required and its look is not reproduced: A3TI works with effects drawn on the player's screen, and those never reach a render target.

**Opening the arsenal disconnects the feed.** Both the ACE one and the vanilla one: opening the arsenal with a feed running drops it instead of leaving it hanging.

**CBA keybinds and the profile.** CBA ties keys to the action's internal name and writes them to the profile on first registration: from then on the default in the code no longer matters, the saved one wins. That is the same property that makes player rebinds survive. This is why the name prefix carries a version: change it and CBA sees new actions that start from the default again. Only touch it when changing the defaults, knowing it wipes the rebinds players made.

---

## Building the PBO

`mkpbo.py` in this repository packs the source folder and, unlike some GUI packers, **writes the prefix into the PBO header**. Without that header every path fails at startup with `Script ... not found`.

```
python mkpbo.py ctab_camera ctab_camera.pbo ctab_camera
```

Then drop the `.pbo` into `@cTab_CruTeK\addons\`.

---

## Credits

Built on top of **cTAB Advanced** by GrueArbre, which in turn descends from **cTab** by Gundy and contributors. The camera extension is by **ArTeK** and **Cruiser**.

Bug reports and ideas are welcome: [github.com/sarteko](https://github.com/sarteko)
