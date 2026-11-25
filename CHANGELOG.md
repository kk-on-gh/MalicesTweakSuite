# Changelog

Malice's Tweak Suite for EllesmereUI. One version for the whole suite.

## [0.2] - 2026-11-24

### Added
- **Hawk Watch** module (hunters with the Summon Hawk talent): a movable tile showing which Summon Hawk hawks are out, their time left, and the cooldown shared with Arcane Shot. Optional recast hint when a hawk is missing or the older one is about to leave. Off by default. `/hawkwatch` opens its options.
- **MobInfo2 Button** module (needs MobInfo2): EllesmereUI's minimap skipped MobInfo2's minimap button because its name ends in a number. This module lets the minimap group it with the other addon buttons. MobInfo2's own Show Minimap Button option still applies. Off by default.
- **Field Guide Coats:** Sound Alert page. A sound when a coated mob's nameplate comes into range, with a sound per coat, Alert From, and Alert On: any coat, a coat not found yet on that species, or a species not recorded at all. Optional repeat every few seconds while the mob stays in range, silenced once you target it. Skips mobs tapped by other players, and can also name the mob on screen.

### Fixed
- **Field Guide Coats:** real coats showed two nameplate marks, Field Guide's own and this one. Field Guide's is now hidden while the nameplate mark is on (Hide Field Guide's Mark, on by default).

## [0.1] - 2026-11-12

First release.

### Added
- Every module lives in one **Malice's Tweak Suite** section of the EllesmereUI options panel. `/mts` opens it. Every feature is off by default and only runs while enabled.
- **Party Compass** module: direction arrows toward party members. `/pcompass` opens its options.
  - Standalone tile with an arrow, name and distance per member, movable in EllesmereUI Unlock Mode.
  - Direction arrows on EllesmereUI party and raid frames.
- **Field Guide Coats** module (needs Field Guide Forever): Field Guide Forever's silver, gold and shiny marks on EllesmereUI frames, which replace the Blizzard frames Field Guide draws on. `/fgcoats` opens its options.
  - Laurel around the EllesmereUI target portrait, with size, offset, leaves side, and an optional hide on rare, elite and boss targets.
  - Field Guide's light sweep across shiny laurels.
  - Quality mark beside EllesmereUI nameplate health bars, with size, opacity, side, gap and offset.
  - Found coats: an optional glow on coats you have not found on that species yet, and optional fading and partial desaturation on ones you have, with a faint shimmer kept on found shinies.
  - Show From: every coat, gold and up, or shiny only.
  - Preview any coat, as new or found, to place and style the marks.
