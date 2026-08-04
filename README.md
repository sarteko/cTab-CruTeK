# cTab CruTeK

![cTab CruTeK](img/cover.jpeg)

A modified build of **cTab** for ARMA 3. It adds *Cam on Galaxy*: live video from helmet cams, turrets, vehicles and drones rendered **inside the Samsung Galaxy screen**, in render-to-texture, both on the open phone and on the small always-on-screen one.

This is not a separate mod: it **replaces cTab**. Do not load both.

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
  - [cTab Compatibility MOD](#ctab-compatibility-mod)
- [Diagnostics](#diagnostics)
- [Technical notes](#technical-notes)
- [Credits](#credits)

---

## What it adds

On top of stock cTab:

- **Cam on Galaxy** — an ACE menu tree to connect the Galaxy to a video source and watch it on the phone screen
- **Sources**: operator helmet cams, and turrets on planes, helicopters, drones, tanks, cars and boats
- **One entry per manned station**: on a vehicle with more than one crewed turret you pick the seat, gunner or commander, and the commander does not have to be armed
- **Turret slewing** on unmanned drones, straight from the video
- **Stepped zoom** taken from real targeting pods
- **Permissions by side, vehicle category and occupant type**, all in the addon options, so they are set per mission
- **Per-mod compatibility profiles**, so vehicles from mods that do not follow the stock conventions are described rather than guessed at
- The stock cTab picture windows (UAV and helmet cam) go from a 512 render target to **1024**

Everything else in cTab — tablet, map, markers, MicroDAGR — works as you know it.

![Drone feed on the Galaxy](img/sc1.jpeg)

*A drone feed inside the phone screen, with source, altitude, zoom and mode overlaid.*

---

## Requirements

| Mod | Required |
|---|---|
| **CBA_A3** | yes |
| **ACE3** | yes, the menu is an ACE self-interaction menu |

**PiP** must be enabled in every player's video options: that is what draws the feed inside the phone screen. With PiP off the screen stays black.

> Do not load stock cTab alongside this one. The internal prefix is still `cTab` and the classes share the same names: they do not coexist well.

---

## Installation

Like any mod: a `@cTab_CruTeK` folder containing `addons\cTab_CruTeK.pbo`, ticked in the launcher instead of cTab.

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

*OpCam on an operator using night vision: the carrier's name, the mode and the distance are shown at the top.*

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
├── Hide feed / Show feed again
├── Disconnect
└── Diagnostics and version
```

On ground and naval vehicles each entry opens one level further, into the manned stations:

```
VehiclesCam
└── Tank
    └── Slammer TUSK  -  120 m  (2)
        ├── ROSSI  -  COMMANDER
        └── BIANCHI  -  GUNNER
```

Each line carries whoever is sitting there and the role, read from the vehicle's own config so the wording is the game's and comes translated. A station shows up if it is manned and declares a gunner optics memory point; it does **not** need to be armed, which is what makes commander seats watchable. Drones and aircraft stay one level up: their source is the pod or the camera memory points, so there is no seat to choose.

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
| `Shift` + middle click | hides the video and returns to the map |

Bound by default, rebindable from the **cTab Camera** section of the CBA keybinds:

| Key | Effect |
|---|---|
| `Shift` + right / left arrow | next / previous vision filter |
| `Shift` + `End` | hide the video |
| `Shift` + `Delete` | disconnect |

Registered in the same section but with **no default key**, bind them yourself if you want them: next operator, previous operator, turret slew.

A second section, **cTab Samsung Position**, moves the small always-on-screen phone. It needs the *where the phone sits* option enabled in the addon options:

| Key | Effect |
|---|---|
| `Ctrl` + `Alt` + left arrow | phone to the left |
| `Ctrl` + `Alt` + down arrow | phone to the centre |
| `Ctrl` + `Alt` + right arrow | phone to the right |

> Those three combinations also recenter the feed camera, so with a feed running they do two things at once. Rebind them if that gets in your way.

The feed controls only respond **while a feed is running**. With no feed the combination falls through and steals nothing from other mods.

---

## Settings

Everything lives in the **addon options**, in four separate categories. They are mission settings, so you set them once per scenario from the editor.

### cTab-Cam on Galaxy

Applies to crewed vehicles.

**Observable sides** — own, BLUFOR, OPFOR, Independent, Civilian. Default: own, BLUFOR and Civilian.

**Vehicle categories** — air, land, sea. All on.

**Transmit only the Gunner or Commander seat, for land and amphibious vehicles** — on by default. Only somebody sitting in a turret counts: driver and passengers do not. A vehicle with only a driver has its turret wherever it was left, and the feed points nowhere useful. Untick it and the menu lists every seat available in the vehicle, following the rule below. Aircraft are never affected.

**Who must be aboard** — four values, first one is the default:

| Value | Meaning |
|---|---|
| player or AI | anyone will do |
| players only | a player must be aboard |
| AI only | an AI must be aboard |
| empty vehicles too | no check at all |

> "Empty vehicles too" is not the default for a reason: the turret of an empty vehicle sits wherever it was left, and the feed points nowhere useful.

**Gameplay limits** — maximum distance from the source (4000 m), minimum altitude, and a minimum view distance while a feed is running.

> Minimum altitude is a **hard threshold**, and it defaults to `0`. An aircraft parked on the runway measures a few centimetres *below* zero, because the model origin sits under the landing gear, so at the default it never makes the list while it is on the ground. Set it to a negative value if you want grounded aircraft to show up: `-10` is plenty.

> View distance is a **single global value** for all rendering: raising it for the feed also raises your own real view while the feed is open. It defaults to `0`, meaning the mod does not touch it. If you need it, the clean way is to raise the ACE value for whoever acts as drone operator.

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

### cTab Compatibility MOD

Some mods do not follow Bohemia's conventions, and the generic rules are not enough for their vehicles. This category holds **one profile per mod**, each switched on and off on its own, so widening the rules where they are needed does not change how stock vehicles behave.

Section **Aircraft and vehicle mods**:

| Setting | Default | Covers |
|---|---|---|
| **USAF Mod** | on | turret compatibility for USAF aircraft |

What the USAF profile changes, and only on USAF vehicles:

- **AC-130U** — only the **IR Operator**, **TV Operator** and **Electronic Warfare Officer** stations can be watched on the phone. The pilot pod is not offered as a source: on a gunship the useful view is the sensor, not the cockpit.
- **Aiming on stations that slew by animation** instead of by swinging a gun barrel. On these aircraft the sensor ball rotates while the gun muzzles stay fixed to the fuselage, so reading the aim from the weapon left the picture frozen however much the sensor was moved.
- **Operator detection on vehicles with more than one turret.** The stock check looks only at the primary gunner and at the driver, so a player sitting at any other station counts as nobody, and thermals and zoom are never mirrored.
- **A-10, F-35, MQ-9 and RQ-4A** are declared explicitly and keep the sources they already used. Nothing changes for them.

Turn it off if the USAF mod is not loaded, or if a future version of it stops needing the profile.

---

## Diagnostics

On startup, in the `.rpt`:

```
[crutek_dcam] versione 2026-08-04-o9
[crutek_dcam] impostazioni registrate: cTab-Cam on Galaxy e cTab-HelmetCam
```

If the first line is missing, the module did not start. In game, the **Diagnostics and version** entry at the bottom of the menu prints version and current state on screen.

### Troubleshooting

| Symptom | What to check |
|---|---|
| the Cam on Galaxy menu never appears | are you carrying the Galaxy (`ItemAndroid`)? is ACE loaded? |
| black phone screen | is PiP enabled in the video options? |
| a vehicle is missing from the list | is its side enabled? is the category on? is it within maximum distance? does it satisfy the who-must-be-aboard rule? |
| an aircraft parked on the ground is missing | minimum altitude is a hard threshold and a grounded aircraft measures just below zero. Set it negative |
| an operator is missing | does he carry `ItemcTabHCam`? is his side among the observable ones in cTab-HelmetCam? |
| a modded vehicle shows the wrong camera, or none at all | is its profile on in cTab Compatibility MOD? a mod with no profile falls back to the generic rules |
| a seat is missing from the vehicle's station list | is somebody sitting in it? does that turret declare a gunner optics memory point? without one there is nowhere to put the camera |
| right mouse does not slew | it only works on **unmanned** drones and with the phone open, and slewing must be enabled in cTab-Drones |
| grainy image | that is the PiP video setting, and it is per player |

---

## Technical notes

**The feed fills the whole phone screen.** No side bars, even at the cost of framing wider than the real optic would.

**The operator's zoom is the limit.** When you connect you start where he is looking, and from there you can only zoom in — you cannot pull back past his field of view. The steps come from real targeting pods. This holds on ground and naval vehicles too: whoever sits in a turret publishes what he is looking at, so his zoom and his thermal mode reach the phone.

**Aiming comes from the turret, not from the barrel.** A station is pointed using its animation sources, the body azimuth and the gun elevation, because those *are* where the sight is looking. Reading the direction from the weapon only works where barrel and optics coincide, which on a tank they do and on plenty of other vehicles they do not: there the picture sat frozen while the gunner slewed. The weapon is kept as a fallback for turrets that declare no animation sources.

**Not every weapon can aim.** Smoke launchers, countermeasures, illumination rounds, laser designators and horns are filtered out before anything is used as an aiming reference. One smoke launcher bolted to the hull was enough to freeze a commander's view, since its presence alone won over the animation sources.

**Vanilla thermals.** The mod does not depend on A3TI and does not reproduce its look: A3TI works with effects drawn on the player's screen, and a screen cannot enter a render target.

**Compatibility profiles are declarations, not guesswork.** Every mod gets its own folder under `comp_mod`, and inside it a table saying which stations of which vehicle families may be watched, and where to look when none of them is available — the pilot pod, the vehicle camera memory points, or nowhere. A vehicle that is listed and has no usable source is **dropped from the menu** rather than falling back to something arbitrary, and a vehicle that no table mentions is left entirely alone.

**Opening the arsenal disconnects the feed.** Both the ACE one and the vanilla one: opening the arsenal with a feed running drops it instead of leaving it hanging.

**CBA keybinds and the profile.** CBA ties keys to the action's internal name and writes them to the profile on first registration: from then on the default in the code no longer matters, the saved one wins. That is the same property that makes player rebinds survive. This is why the name prefix carries a version: change it and CBA sees new actions that start from the default again. Only touch it when changing the defaults, knowing it wipes the rebinds players made.

---

## Credits

Based on **cTab** by Gundy and contributors. The changes in this build are by **CruTeK / ArTeK**.

Bug reports and ideas are welcome: [github.com/sarteko](https://github.com/sarteko)
