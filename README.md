# artspiration

An app to help inspire artwork.

Roll dice across eight prompt categories (Medium, Mood, Palette, Style, Setting,
Texture, Subject, Composition), lock the results you like, reroll the rest, and
save combos to a gallery where you attach a photo of the finished piece.

Dice can be switched off individually from the **Choose dice** button under the
title, for a simpler prompt. A switched-off die greys out in place, sits out of
rolls, and is left out of anything saved from then on.

That button stands where the handoff's "Lock what you like, reroll the rest"
tagline was. The eight-dice grid clears an iPhone screen by only a few pixels,
so the header had room for the tagline or a findable control, not both.

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
- **The subhead tagline is gone**, replaced by the Choose dice button. There was
  room in the header for one or the other, and the tagline restated what the
  Lock and Reroll buttons already say.

## Storage

The gallery survives restarts. Under the app documents directory:

```
gallery/index.json   which dice are in play, plus the entries, newest first
gallery/<id>.img     one file per attached photo
```

Photos are separate files rather than inlined into the JSON, so rewriting the
index — which happens on every save, remove, and photo attach — doesn't rewrite
megabytes of image data. Writes are queued one at a time in `ArtspirationState`,
because removing a card while its photo is still being written would otherwise
race.

Loading is defensive by design. A corrupt index, a missing photo file, or a
value naming a die that no longer exists all degrade to a smaller gallery rather
than a crash — the word lists change between releases, and an entry saved by an
older build has to keep opening. Entries genuinely differ in arity: one saved
with three dice in play sits beside one saved with eight, so nothing may assume
every category is present.

The index is at schema version 2. Version 1 had no `enabledDice` key and is read
as every die in play.

`dart:io` can't be compiled into a web build, so the store is chosen by
conditional import: file-backed on iOS and Android, a no-op on web. The browser
targets exist for design verification, so nothing persists there.

## Not built yet

- **Dice values and locks aren't persisted**, only the gallery and which dice
  are in play. Values and locks reset on launch, which is what you want from a
  prompt generator; which dice you use is a preference, so it persists.
- **Photo picker test coverage.** Picking a photo works — confirmed by hand on
  the iOS simulator, with the usage strings in `Info.plist` — but nothing
  automated covers it. `image_picker` needs its platform channel faked to test,
  so a regression here would go unnoticed. The bytes round-trip through real
  files *is* covered, in `test/gallery_store_test.dart`.
- **Photos are held in memory** once loaded, all of them, for the life of the
  session. Fine for a personal gallery; a few hundred entries would want lazy
  loading from the stored files instead.
