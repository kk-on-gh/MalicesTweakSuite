# Changelog

Malice's Tweak Suite for EllesmereUI. One version for the whole suite.

## [0.2.0]

### Added
- **Field Guide Coats** module (needs Field Guide Forever, WoW Forever only): Field Guide Forever's silver, gold and shiny marks on EllesmereUI frames, which replace the Blizzard frames Field Guide draws on.
  - Laurel around the EllesmereUI target portrait, with size, offset, leaves side, and an optional hide on rare, elite and boss targets.
  - Field Guide's light sweep across shiny laurels.
  - Quality mark beside EllesmereUI nameplate health bars, with size, opacity, side, gap and offset.
  - Found coats: an optional glow on coats you have not found on that species yet, and optional fading and partial desaturation on ones you have, with a faint shimmer kept on found shinies.
  - Show From: every coat, gold and up, or shiny only.
  - Preview any coat, as new or found, to place and style the marks.

### Changed
- Malice's Tweak Suite is now one addon with modules: a core `MalicesTweakSuite` folder plus a `MalicesTweakSuite_<Module>` folder per module, grouped under the core in the game's AddOns list. Party Compass's folder is now `MalicesTweakSuite_PartyCompass`.
- Every module now shares one **Malice's Tweak Suite** section in the EllesmereUI options panel. `/mts` opens it.

## [0.1.0] - 2026-10-24

### Added
- **Party Compass** module: direction arrows toward party members.
  - Standalone tile with an arrow, name and distance per member, movable in EllesmereUI Unlock Mode.
  - Direction arrows on EllesmereUI party and raid frames.
  - `/pcompass` opens its options.
- Every feature is off by default and only runs while enabled.
