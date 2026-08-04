# artspiration

An app to help inspire artwork.

Roll dice across six prompt categories (Medium, Mood, Palette, Style, Setting,
Texture), lock the results you like, reroll the rest, and save combos to a
gallery where you attach a photo of the finished piece.

Built in Flutter from the design handoff in `design_handoff_artspiration/`.

## Running

```sh
flutter pub get
flutter run -d chrome      # or an iOS simulator / Android emulator
flutter test
```

## Layout

```
lib/
  main.dart                  app entry + theme
  data/categories.dart       the six dice: word lists, accent colors, geometry
  models/gallery_entry.dart  a saved roll
  state/app_state.dart       dice, gallery, tab; the roll timer chain
  screens/                   home shell, roll screen, gallery screen
  widgets/                   sticker surface, paper grain, die card, wobble, tab bar
tool/gallery_preview.dart    design-preview entrypoint (not shipped)
```

## Design notes

The hand-drawn look depends on values that read as mistakes but aren't. Don't
normalize them:

- **Four different corner radii** per card/button, roughly 16–28px. Each of the
  six dice cards has its own set (see `DieCategory.corners`).
- **A small rotation** on nearly everything, -2° to 2°.
- **Flat offset shadows only** — `Offset(5, 5)` with zero blur, never a soft
  shadow. `Roll All Dice` casts its shadow in mustard; everything else in ink.
- **2–2.5px ink borders** throughout; dashed for empty and add states.

Fonts are bundled from Google Fonts under the OFL (see `assets/fonts/`). Nunito
ships as a variable font, so weights are applied through the `wght` axis via
`AppText.nunito` rather than by selecting separate files.

Rolling is a timer chain rather than one animation, because the value has to
change on each tick: seven ticks at widening intervals (70, 85, 100, 115, 130,
145, 160ms), each picking a value that differs from the one before it, with the
`Wobble` rotate/scale loop running until it settles.

Verified against the design on an iPhone 17 Pro simulator (iOS 26.5), a Pixel 7
emulator (Android 16 / API 36), and in Chrome.

## Not built yet

- **Persistence.** Dice and gallery live in memory only — a restart clears them,
  including any attached photos. `GalleryEntry` is shaped so this can drop in.
- **Photo picker on-device check.** The picker is wired to `image_picker` and
  the iOS usage strings are in `Info.plist`, but choosing an actual photo has
  only been exercised by hand, not in an automated test.
