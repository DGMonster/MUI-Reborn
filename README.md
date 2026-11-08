# MUI Reborn

> A complete, customizable user interface for WoW Retail, WoW Forever, Classic Era, TBC Classic and MoP Classic.

[![Version](https://img.shields.io/badge/version-1.0.6--rc.1-orange)](https://github.com/DGMonster/MUI-Reborn)
[![WoW Retail](https://img.shields.io/badge/WoW_Retail-12.1-blue)](https://worldofwarcraft.blizzard.com/)
[![WoW Forever](https://img.shields.io/badge/WoW_Forever-1.60.1-purple)](https://worldofwarcraft.blizzard.com/)
[![Development status](https://img.shields.io/badge/status-release_candidate-orange)](https://github.com/DGMonster/MUI-Reborn/issues)
[![Discord](https://img.shields.io/badge/Discord-MUI_Reborn-5865F2?logo=discord&logoColor=white)](https://discord.gg/eqpFHhJyyV)

MUI Reborn replaces and enhances large parts of the default World of Warcraft
interface with a clean, compact and highly configurable layout. It includes its
own installer, configuration menu, layout tools and profile management in one
addon.

## Development status

**1.0.6-rc.1** is a release candidate containing all 1.0.5 fixes plus optional
Forever integrations and further compatibility corrections.

On Forever, Questie can adopt MUI's tracker appearance and Details provides a
native, class-colored MUI Reborn skin. Both remain separate optional addons.
Their presets appear in the installer when loaded; you can continue to choose
other Details skins. The native loot window also uses MUI decoration, and
Bartender's micro menu is hidden through its existing visibility driver.

The update fixes layout-management errors and legacy aura queries on restricted
clients, shortens displayed Forever profile labels, and improves suppression of
the duplicate Blizzard bag window without replacing its methods or parent.

With character profiles enabled, MUI, Bartender4 and unit-frame settings use
separate profiles. Existing settings are copied and shared profiles retained.
Back up WTF before updating; previously overwritten settings cannot be recovered
automatically. A full installer rerun is not required just to update.

User feedback confirms individual fixes and visual changes. Bank first-slot
purchase, combat transitions, complete character/profile switching and other
clients still need regression checks. Automated tests are not WoW runtime tests.

Forever timer bars remain optional, use player/target fields and require reload
after settings/profile changes. Filter lists and some legacy visual options are
not supported. Blizzard buff/debuff icons remain in use. The Era tracking menu
and MoP dungeon-finder activation remain open checks.

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
| Questie | Optional, Forever | Quest tracker with optional MUI appearance |
| Details! | Optional, Forever styling | Damage meter with the native MUI Reborn skin |

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
| `/muiquestie on` / `/muiquestie off` | Enable / disable Forever Questie styling |
| `/muidetails on` / `/muidetails off` | Apply MUI Details skin / restore saved prior appearance |
| `/muimicro on` / `/muimicro off` | Show / hide the Forever micro menu outside combat |
| `/muilootstyle off` | Restore native loot appearance for this session |
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
