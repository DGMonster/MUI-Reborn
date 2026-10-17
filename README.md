# MUI Reborn

> A modern Retail continuation of MayronUI, rebuilt as a single addon for World of Warcraft.

[![Version](https://img.shields.io/badge/version-1.0.0--alpha.20-00ccff)](https://github.com/DGMonster/MUI-Reborn)
[![WoW Retail](https://img.shields.io/badge/WoW_Retail-12.1-blue)](https://worldofwarcraft.blizzard.com/)
[![Development status](https://img.shields.io/badge/status-public_alpha-orange)](https://github.com/DGMonster/MUI-Reborn/issues)
[![Discord](https://img.shields.io/badge/Discord-MUI_Reborn-5865F2?logo=discord&logoColor=white)](https://discord.gg/eqpFHhJyyV)

MUI Reborn continues the design and functionality of **MayronUI Compat22** for
modern World of Warcraft Retail clients. The former Core, Config and Setup
packages are now combined in one `MUI_Reborn` addon folder.

## Development status

MUI Reborn is currently a **public alpha**. The full interface is usable and
the installer, configuration menu and layout tools are included, but bugs and
visual inconsistencies may still occur.

Please report reproducible problems through the
[GitHub issue tracker](https://github.com/DGMonster/MUI-Reborn/issues). Include
the complete Lua error, the steps that caused it and the versions of MUI Reborn,
Bartender4 and Shadowed Unit Frames Redux.

## Features

- Complete MUI interface in a single addon folder
- Integrated installer, configuration menu and profile manager
- MUI layouts, panels, chat styling, inventory tools, auras and timer bars
- Retail 12.1 compatibility for interface versions `120100` and `120105`
- Blizzard Edit Mode compatibility for the Bartender4 Micro Menu
- Eleven synchronized localization files
- Existing MayronUI saved-variable names retained for profile compatibility

## Requirements

The following addons remain separate projects and are **not bundled** with
MUI Reborn:

| Addon | Status | Purpose |
| --- | --- | --- |
| [Bartender4](https://www.curseforge.com/wow/addons/bartender4) | Required | Action bars and Micro Menu |
| [Shadowed Unit Frames Redux](https://www.curseforge.com/wow/addons/shadowed-unit-frames-redux) | Required | Player, target, party and raid frames |
| [Masque](https://www.curseforge.com/wow/addons/masque) | Optional | Button skin support |
| [Bagnon](https://www.curseforge.com/wow/addons/bagnon) | Optional | Bag integration |

> Install **Shadowed Unit Frames Redux**, not an outdated original release. It
> retains the compatible `ShadowedUnitFrames` addon identity required by MUI.

## Installation

1. Close World of Warcraft.
2. Back up your current `Interface/AddOns` and `WTF` folders.
3. Install the current versions of **Bartender4** and
   **Shadowed Unit Frames Redux**.
4. Remove or disable the old `MUI_Core`, `MUI_Config` and `MUI_Setup` folders.
5. Copy the `MUI_Reborn` folder into:
   `_retail_/Interface/AddOns/`
6. Start World of Warcraft and enable MUI Reborn and its required addons.
7. Run `/mui install` if the installer does not open automatically.

The correct folder structure is:

```text
World of Warcraft/
└── _retail_/
    └── Interface/
        └── AddOns/
            └── MUI_Reborn/
                ├── MUI_Reborn.toc
                ├── Config/
                ├── Engine/
                ├── Modules/
                └── Setup/
```

## Migrating an existing Compat22 profile

World of Warcraft stores saved variables under the addon folder name. To reuse
an existing Compat22 profile:

1. Close World of Warcraft completely.
2. Open `WTF/Account/<ACCOUNT>/SavedVariables/`.
3. Back up `MUI_Core.lua`.
4. Copy `MUI_Core.lua` and rename the copy to `MUI_Reborn.lua`.
5. Start the game and verify the profile before deleting any backup.

Skip these steps if you prefer a clean installation.

## Useful commands

| Command | Action |
| --- | --- |
| `/mui` | Show all MUI commands |
| `/mui config` | Open the configuration menu |
| `/mui install` | Open the installer |
| `/mui layouts` | Open the layout tool |
| `/mui profiles` | Open the profile manager |
| `/mui report` | Open the issue reporter |
| `/mui version` | Show the installed version |

## Credits

MUI Reborn is based on **MayronUI**. The original design, architecture and
substantial portions of the implementation were created by **Mayron and the
MayronUI contributors**. Their work remains the foundation of this project.

- Original project: [MayronUI Official](https://github.com/cradzwill/MayronUI-Official)
- MUI Reborn maintenance, development and bug fixes: **Monster**
- Community support: **Monster / Alizmer [GER]**
- Translation support: **Monster / Alizmer [GER], Royking89, ExLinux, Pharma and EarlGrey**

Bartender4, Shadowed Unit Frames Redux, Masque and Bagnon are independent
projects owned and maintained by their respective authors.

See [CREDITS.md](CREDITS.md) for additional project-origin information.

## Community and support

- [Join the MUI Reborn Discord](https://discord.gg/eqpFHhJyyV)
- [Report a bug or request an improvement](https://github.com/DGMonster/MUI-Reborn/issues)

Thank you for testing MUI Reborn and helping bring this interface back to life.
