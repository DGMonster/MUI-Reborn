# MUI Reborn

> A complete, customizable user interface for WoW Retail, WoW Forever, Classic Era, TBC Classic and MoP Classic.

[![Version](https://img.shields.io/badge/version-1.0.8--rc.1-orange)](https://github.com/DGMonster/MUI-Reborn)
[![WoW Retail](https://img.shields.io/badge/WoW_Retail-12.1-blue)](https://worldofwarcraft.blizzard.com/)
[![WoW Forever](https://img.shields.io/badge/WoW_Forever-1.60.1-purple)](https://worldofwarcraft.blizzard.com/)
[![Development status](https://img.shields.io/badge/status-release_candidate-orange)](https://github.com/DGMonster/MUI-Reborn/issues)
[![Discord](https://img.shields.io/badge/Discord-MUI_Reborn-5865F2?logo=discord&logoColor=white)](https://discord.gg/eqpFHhJyyV)

**[Download MUI Reborn](https://github.com/DGMonster/MUI-Reborn/releases) | [Join our Discord](https://discord.gg/eqpFHhJyyV) | [Report a Bug](https://github.com/DGMonster/MUI-Reborn/issues)**

---

## Welcome to MUI Reborn

**MUI Reborn** is a customizable user interface for **World of Warcraft Retail, WoW Forever, Classic Era, TBC Classic and MoP Classic**.

As a continuation of MayronUI, MUI Reborn preserves its distinctive interface design while restoring functionality, improving compatibility and introducing new customization options.

The goal is to provide a clean, compact and coordinated user interface that combines multiple UI elements into one consistent experience.

With its guided installer, extensive configuration menu, flexible layouts and character profile management, MUI Reborn makes it easy to create a personalized interface.

---

## Supported World of Warcraft Clients

| WoW Client | Support |
|---|---|
| World of Warcraft Retail | Supported |
| WoW Forever | Supported — Primary development focus |
| Classic Era | Supported |
| TBC Classic | Supported |
| MoP Classic | Supported |

**Development currently focuses on WoW Forever.**

New functionality, restored interface elements and compatibility improvements are primarily developed and tested on Forever.

Retail and the supported Classic variants remain part of the project. New features are evaluated separately for compatibility before being introduced to other clients.

**Features and available settings may differ between supported WoW clients.**

---

## Features

MUI Reborn combines multiple interface elements into one coordinated and customizable UI experience.

### Interface & Customization

- Guided installation with multiple layout choices
- Extensive configuration menu
- Customizable interface panels and data texts
- Profile and layout management
- Per-character profile support
- Styled chat frames and minimap
- Integrated inventory system
- Aura and timer-bar modules where supported
- Blizzard Edit Mode compatibility where available
- Localization support for eleven languages

### Action Bars & Unit Frames

- Multiple action-bar layouts powered by Bartender4
- Custom player, target, party and raid layouts
- Shadowed Unit Frames integration
- Client-specific unit-frame configuration
- Coordinated interface styling
- Customizable action-bar positioning and layouts

### Minimap & Interface Elements

- Customizable minimap appearance
- Adjustable minimap size and scaling
- Independent map-marker and addon-button scaling
- Customizable zone-name display
- Adjustable positioning and layout options
- Optional MinimapButtonBag Reborn integration

---

## Optional Addon Integrations

MUI Reborn supports selected third-party addons to extend interface functionality and visual customization.

These integrations are optional and do not affect the core functionality of MUI Reborn when the corresponding addon is not installed.

### Details! Damage Meter

On **WoW Forever**, Details! can use a native MUI Reborn skin.

Features include:

- Class-colored accents
- MUI fonts and coordinated interface styling
- Adjusted window and bar spacing
- Optional installer preset
- Support for alternative Details! skins
- Ability to restore a previously saved appearance where available

**Commands:**
- `/muidetails on` — Apply the MUI Reborn skin
- `/muidetails off` — Restore the previous appearance where a backup is available

### Questie

On **WoW Forever**, Questie can use optional MUI tracker styling.

Features include:

- Custom MUI textures
- Theme-color accents
- Translucent tracker background
- Optional installer preset
- Independently configurable styling

**Commands:**
- `/muiquestie on` — Enable MUI Questie styling
- `/muiquestie off` — Disable MUI Questie styling

### MinimapButtonBag Reborn

MinimapButtonBag Reborn provides optional minimap addon-button management.

MUI Reborn offers:

- Optional MUI menu styling
- Class-color integration
- Coordinated theme colors
- Improved visual consistency with the MUI interface

### Masque

Masque provides additional button-skin customization for supported interface elements.

**Important:** All optional addons are independent projects and are not bundled with MUI Reborn.

Client-specific integrations may not be available on every supported WoW version.

---

## Requirements

MUI Reborn requires **Bartender4** and **Shadowed Unit Frames**.

These addons are separate projects and must be installed independently.

### Bartender4

**[Download Bartender4](https://www.curseforge.com/wow/addons/bartender4)**

Bartender4 provides the action-bar functionality used by MUI Reborn, including the Micro Menu.

Install the appropriate version for your WoW client.

### Shadowed Unit Frames

MUI Reborn uses different Shadowed Unit Frames editions depending on the WoW client.

| WoW Client | Required Edition |
|---|---|
| Retail | [Shadowed Unit Frames Redux](https://www.curseforge.com/wow/addons/shadowed-unit-frames-redux) |
| WoW Forever | [Shadowed Unit Frames Redux](https://www.curseforge.com/wow/addons/shadowed-unit-frames-redux) |
| Classic Era | [Original Shadowed Unit Frames](https://www.curseforge.com/wow/addons/shadowed-unit-frames) |
| TBC Classic | [Original Shadowed Unit Frames](https://www.curseforge.com/wow/addons/shadowed-unit-frames) |
| MoP Classic | [Original Shadowed Unit Frames](https://www.curseforge.com/wow/addons/shadowed-unit-frames) |

**Important:**

- Install only the SUF edition appropriate for your WoW client.
- Do not install both SUF editions in the same client.
- Both editions must provide the addon identity `ShadowedUnitFrames`.
- Compatibility and availability of external dependencies depend on their respective maintainers.

---

## Installation

1. Close World of Warcraft.
2. Install the appropriate version of **Bartender4**.
3. Install the correct **Shadowed Unit Frames** edition for your client.
4. Download the latest compatible MUI Reborn release.
5. Extract the `MUI-Reborn` folder into your WoW client's `Interface/AddOns/` directory.
6. Start World of Warcraft and enable MUI Reborn and its required addons.
7. Follow the guided installer or enter `/mui install` in chat.

### Folder Structure

Example for Retail:

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

**Important installation notes:**

- The addon folder must be named `MUI-Reborn`, including the hyphen.
- Avoid creating nested folders such as `MUI-Reborn/MUI-Reborn`.
- The package includes multiple TOC files for supported WoW clients. Leave these files in place.

### Updating MUI Reborn

To update an existing installation:

1. Close World of Warcraft.
2. Back up your **WTF folder**.
3. Replace the existing MUI Reborn addon files with the complete updated version.
4. Keep your SavedVariables to preserve existing settings.

**A full installer rerun is not required for normal updates.**

Applying addon presets is optional and may overwrite existing settings of the selected addons.

Previously overwritten settings cannot be recovered automatically.

---

## Character Profiles

MUI Reborn supports **Profile Per Character** functionality.

When enabled, MUI, Bartender4 and Shadowed Unit Frames use separate character profiles.

Existing settings are copied into character profiles while shared profiles are retained.

This helps prevent configuring MUI on one character from unintentionally overwriting shared Bartender4 or SUF presets used by another character.

---

## Useful Commands

### General Commands

| Command | Description |
|---|---|
| `/mui` | Show available MUI commands |
| `/mui config` | Open the configuration menu |
| `/mui install` | Launch the guided installer |
| `/mui layouts` | Open layout management |
| `/mui profiles` | Open the profile manager |
| `/mui report` | Open the issue reporter |
| `/mui version` | Display the installed version |

### Additional WoW Forever Commands

| Command | Description |
|---|---|
| `/muiquestie on` | Enable MUI Questie tracker styling |
| `/muiquestie off` | Disable MUI Questie tracker styling |
| `/muidetails on` | Apply the MUI Details skin |
| `/muidetails off` | Restore previous Details appearance where available |
| `/muimicro on` | Show the Micro Menu outside combat |
| `/muimicro off` | Hide the Micro Menu outside combat |
| `/muilootstyle on` | Enable native loot-window styling |
| `/muilootstyle off` | Restore native loot appearance for the current session |
| `/muitimers` | Show MUI timer bars |
| `/muitimers off` | Temporarily hide MUI timer bars until reload |

For permanently disabling timer bars, use the appropriate settings in the MUI configuration menu.

Forever timer-bar settings and profile changes may require a UI reload.

---

## Compatibility & Known Limitations

MUI Reborn supports multiple World of Warcraft clients with different APIs and interface systems.

Some functionality may therefore behave differently depending on the client.

Current limitations include:

- New functionality and visual improvements currently prioritize WoW Forever.
- Features and configuration options may differ between supported clients.
- Forever timer bars currently support player and target fields.
- Certain legacy aura-filter and appearance options are unavailable on Forever.
- Blizzard's native buff and debuff icons remain in use on Forever.
- The Classic Era tracking menu remains an open issue.
- MoP Dungeon Finder activation requires further testing with an eligible character.
- Full regression testing of combat transitions, bank purchases and character/profile switching remains incomplete.
- Automated tests do not replace testing inside World of Warcraft.

**MUI Reborn is actively maintained and tested, but bugs and compatibility issues may still occur.**

Feedback and bug reports from all supported clients are welcome.

---

## Update Notifications

MUI Reborn supports public-version notifications between players.

Version information is exchanged through supported communication channels:

- Guild
- Party
- Raid
- Instance groups

When players share one of these channels, existing users may receive a notification if another player is running a newer public release.

Simply passing another player in the game world does not trigger a version exchange.

**Updates must still be downloaded and installed manually.**

---

## Bug Reports & Feedback

Found a bug, encountered a Lua error or have an idea for improving MUI Reborn?

**[Report a Bug or Request a Feature on GitHub](https://github.com/DGMonster/MUI-Reborn/issues)**

When reporting a problem, please include:

- Your WoW client variant and game version
- Your MUI Reborn version
- The complete Lua error, if available
- Steps required to reproduce the issue
- Your Bartender4 version
- Your Shadowed Unit Frames edition (Original or Redux) and version
- Other relevant addons and their versions
- A screenshot if the issue is visual

Please specify the exact WoW client when reporting compatibility problems.

Feature suggestions, translations and constructive feedback are also welcome.

---

## Join the Community

**MUI Reborn has its own Discord community!**

Join our Discord to connect with other users, discuss interface layouts, ask questions, share feedback and follow the development of MUI Reborn.

**[Join the MUI Reborn Discord](https://discord.gg/eqpFHhJyyV)**

For reproducible bugs and feature requests that need tracking, please use GitHub Issues.

---

## Credits & Project Origin

MUI Reborn is a continuation of **MayronUI**.

The original design, architecture and substantial portions of the implementation were created by **Mayron and the MayronUI contributors**.

Their work remains the foundation of this project.

**Original Project:** [MayronUI Official](https://github.com/cradzwill/MayronUI-Official)

**MUI Reborn Development & Maintenance**
- Monster — Development, maintenance and bug fixes

**Community Support**
- Monster / Alizmer [GER]

**Translation Support**
- Monster / Alizmer [GER]
- Royking89
- ExLinux
- Pharma
- EarlGrey

Bartender4, Shadowed Unit Frames, Shadowed Unit Frames Redux, Masque, MinimapButtonBag Reborn, Questie and Details! are independent projects maintained by their respective authors.

See [CREDITS.md](CREDITS.md) for additional attribution.

---

## Support MUI Reborn

MUI Reborn continues to evolve through active development, testing and community feedback.

Every bug report, compatibility test and constructive suggestion helps improve the interface across supported World of Warcraft clients.

**Thank you for supporting MUI Reborn and helping continue the legacy of MayronUI!**

**[Download MUI Reborn](https://github.com/DGMonster/MUI-Reborn/releases) | [Join Discord](https://discord.gg/eqpFHhJyyV) | [Report Issues](https://github.com/DGMonster/MUI-Reborn/issues)**
