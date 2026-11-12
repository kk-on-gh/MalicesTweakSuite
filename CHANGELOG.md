# Changelog

One section per addon in this repo. Tags are per addon: `<Addon>-v<version>`.

## FieldGuideCoats

### [0.1.0] - Unreleased
- Field Guide Forever's laurel around the EllesmereUI target portrait, with size, offset, leaves side, minimum coat, shiny shimmer and a rare/elite/boss hide.
- Field Guide Forever's quality mark beside EllesmereUI nameplate health bars, with size, opacity, side, gap, offset and minimum coat.
- Shiny Shimmer: Field Guide's own light sweep across the shiny laurel, masked to the laurel (a mirrored mask ships for a mirrored laurel).
- Found Coats options on both: glow (laurel pulse, nameplate ping) on a coat this character has not found on that species yet, and partial desaturation plus fade (Found Desaturation, Found Opacity) on one it has. Shimmer Found Shinies keeps a faded sweep on a dimmed shiny. Updates the moment a coat is found.
- Preview Coat and Preview As (New / Found) to place and style the marks without finding a silver, gold or shiny.
- Uses `EllesmereUI.GetNameplateForUnit` when EUI has it, otherwise EUI's exposed plate table.
- Every feature is off by default and only registers events while enabled.

## PartyCompass

### [Unreleased]
- Shares the "Malice's Tweak Suite" EUI panel section with the other suite addons (`Suite.lua`).

### [0.1.0] - 2026-10-24
- Standalone tile with a direction arrow, name and distance toward a party member. Movable in EllesmereUI unlock mode.
- Direction arrows on EllesmereUI party and raid frames.
- Own section in the EllesmereUI panel. `/pcompass` opens it.
- Every feature is off by default and only runs while enabled. No per-frame polling.
