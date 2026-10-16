# MUI Reborn 1.0.0-alpha.20

This development build merges the complete MayronUI Compat22 Core, Config and
Setup packages into the single `MUI_Reborn` addon folder. It is intended for
Retail interfaces 120100 and 120105.

## External addons

- Bartender4 is required and remains a separate addon.
- Shadowed Unit Frames Redux is required and remains a separate addon under
  the compatible `ShadowedUnitFrames` addon identity.
- Masque and Bagnon remain optional external addons.

MUI Reborn includes the complete internal configuration and setup systems. The
setup imports the appropriate external-addon profiles but does not bundle their
code.

## Test status

Alpha 16 is the current structural one-folder merge. It retains the Compat22
saved-variable names. Because World of Warcraft stores them in a file named
after the addon folder, an existing profile is only reused after copying
`MUI_Core.lua` to `MUI_Reborn.lua` while the game is closed. Otherwise the
integrated setup creates a fresh configuration. In-game testing is required
before this branch replaces the smaller Alpha 11 prototype.

Alpha 14 deferred the installer warning's theme coloring until database startup.
This fixes the initial `themeColor` error and the resulting missing
`SetUpModule` registration from Alpha 13.

Alpha 15 no longer forces Blizzard's global UI scale to 0.70 during setup. The
setup slider remains available as an explicit manual option, while fresh
defaults mirror the current Blizzard scale.

Alpha 16 adds a compatibility bridge between Blizzard Edit Mode and the
Bartender4 Micro Menu used by MUI. Orientation, order, menu size, and eye size
from the Blizzard Micro Menu settings are mirrored to the corresponding
Bartender4 bars. The green Bartender4 Micro Menu overlay remains the frame to
drag while Edit Mode is open.

Alpha 17 updates the installer with the MUI Reborn Pandaren banner, modernizes
the Retail 12.1 color picker integration, and synchronizes all locale files to
the same set of 797 translation keys. The German interface translation also
received a broad terminology and grammar cleanup. The Info and Credits content
remains intentionally unchanged for the maintainer to revise separately.

Alpha 18 corrects the vertical TGA orientation of the new installer banner so
it is displayed upright by the World of Warcraft client.

Alpha 19 updates visible legacy branding to MUI Reborn while retaining the
internal MayronUI identifiers required for profile and saved-variable
compatibility. It also changes the German LFD label to LFG and connects the
installer, Discord link and issue reporter to the new MUI Reborn project.

Alpha 20 replaces the legacy information and acknowledgements pages. Patreon,
YouTube and the historical patron list are no longer presented as current MUI
Reborn resources. The original MayronUI project remains credited as the source
and foundation, while current development and support are listed separately.

## Installation

1. Close World of Warcraft and back up the current AddOns and WTF folders.
2. Install current Bartender4 and Shadowed Unit Frames Redux separately.
3. Remove or disable the separate `MUI_Core`, `MUI_Config` and `MUI_Setup`
   folders.
4. Copy the `MUI_Reborn` folder into `_retail_/Interface/AddOns`.
5. For migration, copy
   `WTF/Account/ACCOUNT/SavedVariables/MUI_Core.lua` to `MUI_Reborn.lua`.
   Skip this step when a fresh setup is preferred.
6. Start with Lua errors enabled and run the setup through `/mui install` if
   necessary.

See `CREDITS.md` for project origin and attribution.
