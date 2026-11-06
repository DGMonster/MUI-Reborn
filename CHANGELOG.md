# Changelog

## 1.0.2 – 2026-11-06

- Explicitly skip legacy compact raid-manager changes on WoW Forever, matching the tested patch for the Edit Mode health-color taint error.
- Correct the aura fallback notice to identify WoW Forever or WoW Retail instead of always naming Retail 12.1.
- Remove duplicate MUI Reborn prefixes from aura and cast-bar fallback notices.
- Update the Forever cast-bar notice wording. Blizzard fallback displays remain enabled.

Validation: user confirmed the reported Forever Edit Mode error no longer occurred with the raid-manager test patch. Syntax and package checks performed; full client regression testing remains incomplete.

## 1.0.1-rc – Complete RC package, 2026-10-22

- Add Era, TBC and MoP manifests with client-specific library loading.
- Use independent minimap anchors for protected aura headers in Era/TBC/MoP.
- Preserve Blizzard Edit Mode behavior where available.
- Add modern chat-menu paths for Era/TBC/MoP and standalone secure profession rows for Era/MoP.
- Guard missing legacy tracking dropdowns; the Era tracking menu remains unresolved.
- Replace the obsolete MoP Skills shortcut with the dungeon finder, including saved-binding display.
- Default external AddOn minimap icon scale to 0.8 without overwriting saved values.
- Correct imported bag-break values for Bagnon 12.1.7; the MUI inventory requires no Bagnon.
- Document client-compatible SUF editions; original SUF was used on older clients.
- Keep the public announcement marker at 1.0.0-rc.1 pending publication.

Validation: static load-chain and package checks plus user feedback on reported
Classic issues. No agent-run WoW tests. Era tracking menu/inactive fallback icon
and MoP dungeon-finder activation remain open. Full regression testing is incomplete.

- Add MBB as an optional integration: its settings, profile and button-manager
  windows can adopt MUI's class/theme styling with the updated MBB menu module.
- Keep MBB's standalone menu neutral and independent of MUI.

## 1.0.0-rc.1 – 2026-10-22

First release candidate, based on the internal beta.27 development build.

- Separate minimap map-icon scaling and AddOn-button scaling.
- Restore specialization switching through the modern Retail API.
- Preserve error messages through the chat fallback when the error window is unavailable.
- Separate installed build numbers from public-version announcements.
- Announce published versions to users of the original beta update channel as well as the new release channel.

Retail specialization switching and the minimap change received positive user feedback. This is a release candidate; full Retail/Forever regression testing is not complete.
