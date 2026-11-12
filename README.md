# Malice's Tweak Suite for EllesmereUI

Personal plugin addons for [EllesmereUI](https://www.curseforge.com/wow/addons/ellesmereui), built only on its public plugin and skinning APIs. This repo does not contain or redistribute EllesmereUI itself.

Each tweak is its own addon folder; copy or symlink the folders you want into `Interface/AddOns/`. Every addon declares `## Dependencies: EllesmereUI`, keeps its own SavedVariables, and defaults its features to OFF.

| Addon | What it does | Status |
|---|---|---|
| `PartyCompass/` | Direction arrows toward party members: a movable standalone tile, plus arrows on EUI party/raid frames. Slash command `/pcompass`. | 0.1.0, tested in game: works well so far |
| `FieldGuideCoats/` | [Field Guide Forever](https://github.com/cjber/field-guide-forever)'s silver, gold and shiny marks on the EUI target portrait and nameplates (FGF draws them on Blizzard's frames, which EUI hides). Needs Field Guide Forever. Slash command `/fgcoats`. WoW Forever only. | 0.1.0, not yet tested in game |

Every addon shares one "Malice's Tweak Suite" section in the EUI panel. Each ships an identical copy of `Suite.lua`, which registers the section once at login with every installed addon's module in it; keep the copies identical.

## Notes
- Target interface: `120000-120105, 16001` (retail Midnight and WoW Forever), matching EllesmereUI's TOC.
- `FieldGuideCoats` loads Field Guide Forever's laurel textures from that addon's folder at runtime, and the quality marks are Blizzard atlases. Its one shipped image, `Media/LaurelMask-Shiny-Mirrored.tga`, is FGF's shiny laurel mirrored (GPL-3.0-or-later); see `CREDITS.md` and `FieldGuideCoats/Media/NOTICE.txt`.
- `PartyCompass/Media/Arrow.tga` comes from the Magic Quest Tracker addon (GPL v3); see `CREDITS.md` and `PartyCompass/Media/NOTICE.txt`. Keep them with the image, or replace the texture with your own artwork.
