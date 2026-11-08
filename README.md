# MUI Reborn

> A complete, customizable user interface for WoW Retail, WoW Forever, Classic Era, TBC Classic and MoP Classic.

[![Version](https://img.shields.io/badge/version-1.0.5-00ccff)](https://github.com/DGMonster/MUI-Reborn)
[![WoW Retail](https://img.shields.io/badge/WoW_Retail-12.1-blue)](https://worldofwarcraft.blizzard.com/)
[![WoW Forever](https://img.shields.io/badge/WoW_Forever-1.60.1-purple)](https://worldofwarcraft.blizzard.com/)
[![Development status](https://img.shields.io/badge/status-release-brightgreen)](https://github.com/DGMonster/MUI-Reborn/issues)
[![Discord](https://img.shields.io/badge/Discord-MUI_Reborn-5865F2?logo=discord&logoColor=white)](https://discord.gg/eqpFHhJyyV)

MUI Reborn replaces and enhances large parts of the default World of Warcraft
interface with a clean, compact and highly configurable layout. It includes its
own installer, configuration menu, layout tools and profile management in one
addon.

## Development status

**1.0.5** focuses on WoW Forever improvements while retaining the existing Retail,
Classic Era, TBC Classic and MoP Classic manifests.

With character profiles enabled, MUI, Bartender4 and unit-frame settings use separate
profiles for each character. Existing settings are copied and shared profiles retained.
Installing another character no longer overwrites those shared settings. Back up your
WTF folder before updating; previously overwritten settings cannot be recovered automatically.

Forever improvements include MUI styling for the native group/raid manager,
movable character/spellbook/guild windows, targeted master-font support,
a corrected spellbook shortcut, native Lua-error-window styling and a shortcut
to the MUI report form. Inventory handling includes the reagent bag, and the
specialization data text now shows the active Primary/Secondary talent group.
Talent-group switching remains in Blizzard's talent window.

The existing player/target timer bars and player cast-bar styling remain available.
Blizzard buff/debuff icons are retained. Existing profiles are kept; rerunning
the installer is not required.

User testing has covered individual Forever fixes, including the Primary label
and guild-window movement. Reagent-bag handling, Secondary switching and guild
position persistence after reload remain pending in-game checks. A reported SUF
party-position reset is addressed through separate character profiles; the complete
character-switch/installer sequence still needs in-game verification. Full regression testing across
clients is incomplete. Automated checks do not replace in-game testing.

On Forever, timer-bar settings/profile changes require `/reload`. Only player and
target fields are supported; fields using whitelist/blacklist filters are skipped.
Buff/debuff groups have separate bar limits and sorting. Some legacy visual
options are not implemented. `/muitimers off` hides them for the current session;
for a persistent change, disable the module or field in configuration and reload.
The Era tracking menu and MoP dungeon-finder activation remain open checks.

### Changes since public Beta 15

- Fixed compatibility with modern popup input fields and buttons.
- Added the CurseForge project ID to the TOC.
- Added independent scaling, an anchor dropdown and separate X/Y offsets for
  the minimap zone-name widget, plus an option to hide its background.
- Added 0.1-step X/Y position adjustments, including the clock, and reorganized
  the zone-name settings.
- Lowered the minimum minimap size to 100.
- Added separate **Map Icon Scale** and **AddOn Icon Scale** settings for
  Blizzard markers and external buttons such as Wowhead and HarvestGoal.
- Improved addon-button scaling when using MinimapButtonBag.
- Fixed specialization switching on Retail.
- Fixed the error-message fallback when the error window is unavailable.
- Separated internal build versions from public update announcements while
  preserving update notifications for existing beta users.

### Update notifications

MUI Reborn shares public-version information through guild, party, raid and
instance-group channels. Existing beta users can receive an update notice
when sharing one of these channels with a user of a newer public release. Simply passing another
player in the world does not trigger a version exchange. Updates are downloaded
and installed manually.

Please report reproducible problems through the
[GitHub issue tracker](https://github.com/DGMonster/MUI-Reborn/issues). Include
the complete Lua error, the steps that caused it and the installed versions of
MUI Reborn, Bartender4 and the installed Shadowed Unit Frames edition.

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
| Shadowed Unit Frames (client-compatible edition) | Required | Player, target, party and raid frames |
| [Masque](https://www.curseforge.com/wow/addons/masque) | Optional | Button skin support |
| [Bagnon](https://www.curseforge.com/wow/addons/bagnon) | Optional | Bag integration |

> **Retail and Forever:** use [Shadowed Unit Frames Redux](https://www.curseforge.com/wow/addons/shadowed-unit-frames-redux).
> **Classic Era, TBC and MoP:** use the client-compatible original
> [Shadowed Unit Frames](https://www.curseforge.com/wow/addons/shadowed-unit-frames).
> Both editions must provide the addon identity `ShadowedUnitFrames`.

## Installation

1. Close World of Warcraft.
2. Install the current versions of **Bartender4** and
   **Shadowed Unit Frames** suitable for your client.
3. Copy the `MUI-Reborn` folder into the matching client directory:
   use the selected Retail, Forever, Era, TBC or MoP client's
   `Interface/AddOns/` directory.
4. Start World of Warcraft and enable MUI Reborn and its required addons.
5. Follow the installer or enter `/mui install` in chat.

If you are updating an existing installation, replace the addon files while
WoW is closed. Keep your existing SavedVariables to retain your settings;
rerunning the installer is not required just to update the addon.

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
| `/muitimers` / `/muitimers off` | Show / temporarily hide Forever timer bars until reload |

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
