# MUI Reborn

> A complete, customizable user interface for World of Warcraft Retail and WoW Forever.

[![Version](https://img.shields.io/badge/version-1.0.0--beta.15-00ccff)](https://github.com/DGMonster/MUI-Reborn)
[![WoW Retail](https://img.shields.io/badge/WoW_Retail-12.1-blue)](https://worldofwarcraft.blizzard.com/)
[![WoW Forever](https://img.shields.io/badge/WoW_Forever-1.60.1-purple)](https://worldofwarcraft.blizzard.com/)
[![Development status](https://img.shields.io/badge/status-public_beta-brightgreen)](https://github.com/DGMonster/MUI-Reborn/issues)
[![Discord](https://img.shields.io/badge/Discord-MUI_Reborn-5865F2?logo=discord&logoColor=white)](https://discord.gg/eqpFHhJyyV)

MUI Reborn replaces and enhances large parts of the default World of Warcraft
interface with a clean, compact and highly configurable layout. It includes its
own installer, configuration menu, layout tools and profile management in one
addon.

## Development status

MUI Reborn is currently available as a **public beta** for World of Warcraft
Retail 12.1 and WoW Forever 1.60.1. Forever support is still under active
development, and some features may change before its official release.

Please report reproducible problems through the
[GitHub issue tracker](https://github.com/DGMonster/MUI-Reborn/issues). Include
the complete Lua error, the steps that caused it and the installed versions of
MUI Reborn, Bartender4 and Shadowed Unit Frames Redux.

## Features

- Guided setup with several interface layout choices
- Extensive configuration menu and profile management
- Custom panels, chat frames, data text and minimap styling
- Integrated inventory tools, aura handling and timer bars
- Multiple action-bar layouts powered by Bartender4
- Custom player, target, party and raid layouts powered by Shadowed Unit Frames
- Compatibility with Blizzard Edit Mode for the Micro Menu
- Localization support for eleven languages

## Requirements

The following addons are separate projects and are **not bundled** with MUI
Reborn:

| Addon | Status | Purpose |
| --- | --- | --- |
| [Bartender4](https://www.curseforge.com/wow/addons/bartender4) | Required | Action bars and Micro Menu |
| [Shadowed Unit Frames Redux](https://www.curseforge.com/wow/addons/shadowed-unit-frames-redux) | Required | Player, target, party and raid frames |
| [Masque](https://www.curseforge.com/wow/addons/masque) | Optional | Button skin support |
| [Bagnon](https://www.curseforge.com/wow/addons/bagnon) | Optional | Bag integration |

> Install **Shadowed Unit Frames Redux**, not an outdated original release. It
> provides the compatible `ShadowedUnitFrames` addon identity required by MUI.

## Installation

1. Close World of Warcraft.
2. Install the current versions of **Bartender4** and
   **Shadowed Unit Frames Redux**.
3. Copy the `MUI-Reborn` folder into the matching client directory:
   `_retail_/Interface/AddOns/` for Retail or the Forever client's
   `Interface/AddOns/` directory.
4. Start World of Warcraft and enable MUI Reborn and its required addons.
5. Follow the installer or enter `/mui install` in chat.

The correct folder structure is:

```text
World of Warcraft/
└── _retail_/
    └── Interface/
        └── AddOns/
            └── MUI-Reborn/
                ├── MUI-Reborn.toc
                ├── Config/
                ├── Engine/
                ├── Modules/
                └── Setup/
```

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

## Credits and project origin

MUI Reborn is a continuation of **MayronUI**. The original design, architecture
and substantial portions of the implementation were created by **Mayron and
the MayronUI contributors**. Their work remains the foundation of this project.

- Original project: [MayronUI Official](https://github.com/cradzwill/MayronUI-Official)
- MUI Reborn maintenance, development and bug fixes: **Monster**
- Community support: **Monster / Alizmer [GER]**
- Translation support: **Monster / Alizmer [GER], Royking89, ExLinux, Pharma and EarlGrey**

Bartender4, Shadowed Unit Frames Redux, Masque and Bagnon are independent
projects owned and maintained by their respective authors.

See [CREDITS.md](CREDITS.md) for additional attribution.

## Community and support

- [Join the MUI Reborn Discord](https://discord.gg/eqpFHhJyyV)
- [Report a bug or request an improvement](https://github.com/DGMonster/MUI-Reborn/issues)

Thank you for testing MUI Reborn and helping bring this interface back to life.
