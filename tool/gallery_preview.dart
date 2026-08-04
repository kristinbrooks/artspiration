// Design-preview entrypoint: boots into a chosen app state so styling can be
// checked without tapping through.
//
//   flutter run -t tool/gallery_preview.dart -d chrome
//   flutter run -t tool/gallery_preview.dart -d chrome --dart-define=entries=0
//   flutter run -t tool/gallery_preview.dart -d chrome --dart-define=lockAll=true
//
// Not part of the shipped app.
import 'package:flutter/material.dart';

import 'package:artspiration/data/categories.dart';
import 'package:artspiration/main.dart';
import 'package:artspiration/state/app_state.dart';

/// Gallery entries to seed. 0 leaves the gallery empty.
const _entries = int.fromEnvironment('entries', defaultValue: 2);

/// Lock every die and stay on the roll tab, to check disabled styling.
const _lockAll = bool.fromEnvironment('lockAll');

void main() {
  final state = ArtspirationState();

  if (_lockAll) {
    for (final category in DieCategory.values) {
      state.toggleLock(category);
    }
  } else {
    // Saving snapshots the current dice and switches to the Gallery tab. Rolls
    // settle asynchronously, so seeded entries share values — enough to check
    // card, chip, and slot styling.
    for (var i = 0; i < _entries; i++) {
      state.saveToGallery();
    }
    if (_entries == 0) state.tab = AppTab.gallery;
  }

  runApp(ArtspirationApp(state: state));
}
