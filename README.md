# Malice's Tweak Suite for EllesmereUI

I did this stuff mostly for myself, and then for a handful of friends, so maybe it'll suit some others too.

Small quality-of-life tweaks for [EllesmereUI](https://www.curseforge.com/wow/addons/ellesmereui), all in one **Malice's Tweak Suite** section of the EllesmereUI options panel. Type `/mts` to open it.

Every module starts switched off and does no work until you turn something on.

## Installation

Install via CurseForge, Wago, or a CurseForge-compatible addon manager. Or download the zip from [Releases](https://github.com/kk-on-gh/MalicesTweakSuite/releases) and extract it into your `Interface/AddOns` directory: you should end up with `MalicesTweakSuite`, `MalicesTweakSuite_PartyCompass` and `MalicesTweakSuite_FieldGuideCoats` folders.

See [CHANGELOG.md](CHANGELOG.md) for release notes.

## License

GPL-3.0. See [LICENSE](LICENSE).

## Modules

### Party Compass

Arrows pointing toward your party members, so you can find them at a glance. `/pcompass`

- **Standalone tile:** an arrow, name and distance for each party member. Move it in EllesmereUI's Unlock Mode, lay it out horizontally or vertically, and style the arrows, text and background.
- **Frame arrows:** a direction arrow on each EllesmereUI party and raid frame, with optional distance text.
- Distances in yards or meters. Works outside instances, where the game provides party positions.

### Field Guide Coats

*Needs [Field Guide Forever](https://www.curseforge.com/wow/addons/field-guide-forever). WoW Forever only.*  You don't need it installed to use this addon, this module just won't load without FGF. `/fgcoats`

Field Guide Forever marks silver, gold and shiny creatures, but it draws those marks on Blizzard's frames, which EllesmereUI replaces. This module puts them back, on EllesmereUI's frames:

![image](https://cdn.jsdelivr.net/gh/kk-on-gh/MalicesTweakSuite-Media@master/Screenshots/FGFLaurel.png)

- **Target portrait:** Field Guide's laurel around your target's portrait, with the shiny light sweep.
- **Nameplates:** Field Guide's quality mark beside the health bar.
- **Found coats:** optionally make coats you haven't collected on that creature yet glow, and fade the ones you have, so you know at a glance what's worth chasing.
- Size, position and opacity options, plus a preview to set it all up without hunting for a shiny.

## Requirements

- EllesmereUI.
- WoW Forever. Field Guide Coats also needs Field Guide Forever.

## Notes

- Not affiliated with EllesmereUI or Field Guide Forever. This addon only uses EllesmereUI's public plugin API and contains none of its code.
- Party Compass's arrow art comes from Magic Quest Tracker (GPL v3). Field Guide Coats uses Field Guide Forever's laurel art (GPL-3.0-or-later). See the included notices.

## A few words

Malice's Tweak Suite is where I put the small things I wanted from EllesmereUI that it doesn't do (yet). If something breaks, feels awkward, or you've got an idea for it, I really want to hear about it. Bug reports, suggestions, and pull requests are all welcome.
