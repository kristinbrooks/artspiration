# artspiration

An app to help inspire artwork.

Roll dice across eight prompt categories (Medium, Mood, Palette, Style, Setting,
Texture, Subject, Composition), lock the results you like, reroll the rest, and
save combos to a gallery where you attach a photo of the finished piece.

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
  data/categories.dart       the dice: word lists, accent colors, geometry
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
  dice cards has its own set (see `DieCategory.corners`).
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

Verified against the design on iPhone 17 and iPhone 17 Pro simulators (iOS
26.5), a Pixel 7 emulator (Android 16 / API 36), and in Chrome.

### Departures from the handoff

The handoff describes six dice. At eight, a phone screen no longer fits the
grid, so a few of its values were changed deliberately — restoring them will put
the last row back below the fold:

- **Roll All / Save are pinned** above the tab bar rather than scrolling with
  the dice, so saving stays reachable. Each screen owns its own scrolling to
  make that possible.
- **Spacing is tighter** than specified: card padding 14→10px, card internal
  gaps 8→6px, grid gutter 14→10px. Radii, rotations, borders, shadows, and
  horizontal padding are untouched.
- **Die values stay on one line**, scaling down when long, so every card is the
  same height and the layout can't shift with the roll. The handoff's wrapping
  made the fit depend on which values came up.
- **Android's overscroll stretch is disabled** (`_NoOverscrollStretch` in
  `main.dart`). It scales the viewport on overscroll, warping the card borders
  and offset shadows. Platform scroll physics are otherwise untouched.

## Not built yet

- **Persistence.** Dice and gallery live in memory only — a restart clears them,
  including any attached photos. `GalleryEntry` is shaped so this can drop in.
- **Photo picker test coverage.** Picking a photo works — confirmed by hand on
  the iOS simulator, with the usage strings in `Info.plist` — but nothing
  automated covers it. `image_picker` needs its platform channel faked to test,
  so a regression here would go unnoticed.
