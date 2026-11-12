# Malice's Tweak Suite for EllesmereUI

Small quality-of-life tweaks for [EllesmereUI](https://www.curseforge.com/wow/addons/ellesmereui), built only on its public plugin API. Every module lives in one **Malice's Tweak Suite** section of the EllesmereUI options panel (`/mts` opens it), starts switched off, and does no work until you turn something on.

This suite does not contain or redistribute EllesmereUI itself.

## Modules

### Party Compass
Direction arrows toward your party members. `/pcompass` opens its options.

- **Standalone tile**: an arrow, name and distance for each party member, horizontal or vertical, movable in EllesmereUI Unlock Mode.
  - Arrow size, text size, spacing and background opacity.
  - Arrows in class color, white or a custom color; names in class color or plain, full or first name only.
  - Shows dead, offline and other-zone members, or hides them; hides itself when you are not grouped.
- **Frame arrows**: a direction arrow on each EllesmereUI party and raid frame, with anchor, offset, size, color, optional distance text and a "hide within" range.
- Distances in yards or meters, an adjustable update rate, and a test mode for styling the tile while solo.

### Field Guide Coats
*Needs [Field Guide Forever](https://www.curseforge.com/wow/addons/field-guide-forever). WoW Forever only.* `/fgcoats` opens its options.

Field Guide Forever marks silver, gold and shiny creatures on Blizzard's target frame and nameplates, which EllesmereUI replaces. This module draws those marks on EllesmereUI's frames instead.

- **Portrait laurel**: Field Guide's laurel around the EllesmereUI target portrait.
  - Size, X/Y offset, and which side the leaves fan out to (Auto points them away from the frame).
  - Field Guide's own light sweep across shiny laurels.
  - Optionally left off rare, elite and boss targets, which EllesmereUI's portrait dragon already marks.
- **Nameplate mark**: Field Guide's quality mark beside the EllesmereUI nameplate health bar, with size, opacity, side, gap and offset.
- **Found coats**, on both:
  - A glow on coats this character has not found on that species yet.
  - Fading and partial desaturation on coats it has, adjustable, with an optional faint shimmer kept on found shinies.
  - Updates the moment you find a coat.
- **Show From**: show every coat, or only gold and up, or only shiny.
- **Preview**: show any coat, as new or found, on your target and every nameplate, to place and style the marks without hunting for one.

## Requirements

- EllesmereUI (the Unit Frames and Nameplates modules for Field Guide Coats).
- Retail (Midnight) or WoW Forever. Field Guide Coats loads only on WoW Forever, with Field Guide Forever installed.

## Credits

- `MalicesTweakSuite_PartyCompass/Media/Arrow.tga` comes from the Magic Quest Tracker addon (GPL v3).
- `MalicesTweakSuite_FieldGuideCoats/Media/LaurelMask-Shiny-Mirrored.tga` is Field Guide Forever's shiny laurel, mirrored (GPL-3.0-or-later). The other laurels are loaded from Field Guide Forever's own folder at runtime.

See [CREDITS.md](CREDITS.md) and each module's `Media/NOTICE.txt`.

## Development

- `MalicesTweakSuite/` is the core addon: it owns the shared EllesmereUI section and the `/mts` command. Each module is its own folder, `MalicesTweakSuite_<Module>/`, with `## Group: MalicesTweakSuite` (the game's AddOns list nests it under the core), `## Dependencies: EllesmereUI, MalicesTweakSuite`, and its own SavedVariables. A module adds itself with `MalicesTweakSuite.AddModule(order, spec)` from `ADDON_LOADED`.
- Copy or symlink all the folders into `Interface/AddOns/`; one CurseForge project ships them together, as EllesmereUI does.
- One version for the whole suite, in every TOC; history in [CHANGELOG.md](CHANGELOG.md).
