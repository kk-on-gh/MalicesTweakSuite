# Malice's Tweaks for EllesmereUI

Personal plugin addons for [EllesmereUI](https://www.curseforge.com/wow/addons/ellesmereui), built only on its public plugin and skinning APIs. This repo does not contain or redistribute EllesmereUI itself.

Each tweak is its own addon folder; copy or symlink the folders you want into `Interface/AddOns/`. Every addon declares `## Dependencies: EllesmereUI`, keeps its own SavedVariables, and defaults its features to OFF.

| Addon | What it does | Status |
|---|---|---|
| `PartyCompass/` | Direction arrows toward party members: a movable standalone tile, plus arrows on EUI party/raid frames. Slash command `/pcompass`. | 0.1.0, untested in game |

## Notes
- Target interface: `120000-120105, 16001` (retail Midnight and WoW Forever), matching EllesmereUI's TOC.
- `PartyCompass/Media/Arrow.tga` comes from the Magic Quest Tracker addon (GPL v3); see `CREDITS.md` and `PartyCompass/Media/NOTICE.txt`. Keep them with the image, or replace the texture with your own artwork.
