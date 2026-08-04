import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:artspiration/data/app_store.dart';
import 'package:artspiration/data/app_store_io.dart';
import 'package:artspiration/data/categories.dart';
import 'package:artspiration/models/gallery_entry.dart';
import 'package:artspiration/state/app_state.dart';

/// Exercises the real file-backed store against a temp directory, so the JSON
/// and the image files are genuinely written and read back.
void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('artspiration_test');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  FileAppStore store() => FileAppStore(root: root);

  GalleryEntry entry(String id, {Uint8List? image, double rotation = 0.5}) {
    return GalleryEntry(
      id: id,
      rotation: rotation,
      values: {
        for (final category in DieCategory.values)
          category: category.options.first,
      },
      imageBytes: image,
    );
  }

  Future<void> saveEntries(List<GalleryEntry> entries) =>
      store().save(StoredState(entries: entries));

  File imageFile(String id) => File('${root.path}/gallery/$id.img');

  Future<void> writeIndex(Map<String, Object?> json) async {
    await Directory('${root.path}/gallery').create(recursive: true);
    await File(
      '${root.path}/gallery/index.json',
    ).writeAsString(jsonEncode(json));
  }

  group('FileAppStore', () {
    test('an empty store loads empty state', () async {
      final loaded = await store().load();
      expect(loaded.entries, isEmpty);
      expect(loaded.enabledDice, isNull);
    });

    test('entries round-trip with their values, rotation, and order', () async {
      await saveEntries([entry('a', rotation: -1.25), entry('b')]);

      final loaded = await store().load();

      expect(loaded.entries.map((e) => e.id), ['a', 'b']);
      expect(loaded.entries.first.rotation, -1.25);
      expect(
        loaded.entries.first.values[DieCategory.medium],
        DieCategory.medium.options.first,
      );
    });

    test('photos round-trip', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      await saveEntries([entry('a', image: bytes)]);

      expect((await store().load()).entries.single.imageBytes, bytes);
    });

    test('removing an entry deletes its photo file', () async {
      await saveEntries([
        entry('a', image: Uint8List.fromList([1])),
        entry('b', image: Uint8List.fromList([2])),
      ]);
      expect(await imageFile('a').exists(), isTrue);

      await saveEntries([entry('b', image: Uint8List.fromList([2]))]);

      expect(await imageFile('a').exists(), isFalse);
      expect(await imageFile('b').exists(), isTrue);
      expect((await store().load()).entries.map((e) => e.id), ['b']);
    });

    test('a corrupt index yields empty state rather than throwing', () async {
      await saveEntries([entry('a')]);
      await File('${root.path}/gallery/index.json').writeAsString('{not json');

      expect((await store().load()).entries, isEmpty);
    });

    test('an entry whose photo file vanished still loads', () async {
      await saveEntries([entry('a', image: Uint8List.fromList([1]))]);
      await imageFile('a').delete();

      final loaded = await store().load();

      expect(loaded.entries, hasLength(1));
      expect(loaded.entries.single.hasImage, isFalse);
    });

    test('values for categories that no longer exist are dropped', () async {
      await writeIndex({
        'version': 2,
        'entries': [
          {
            'id': 'old',
            'rotation': 0.0,
            'hasImage': false,
            'values': {'medium': 'Watercolor', 'aura': 'Retired die'},
          },
        ],
      });

      expect((await store().load()).entries.single.values, {
        DieCategory.medium: 'Watercolor',
      });
    });
  });

  group('FileAppStore enabled dice', () {
    test('the enabled set round-trips', () async {
      await store().save(
        StoredState(
          entries: const [],
          enabledDice: {DieCategory.medium, DieCategory.mood},
        ),
      );

      expect((await store().load()).enabledDice, {
        DieCategory.medium,
        DieCategory.mood,
      });
    });

    test('a version 1 file reads as every die in play', () async {
      // Written before dice could be switched off: no enabledDice key at all.
      await writeIndex({'version': 1, 'entries': <Object>[]});

      expect((await store().load()).enabledDice, isNull);
    });

    test('names that no longer match a die are dropped', () async {
      await writeIndex({
        'version': 2,
        'enabledDice': ['medium', 'aura'],
        'entries': <Object>[],
      });

      expect((await store().load()).enabledDice, {DieCategory.medium});
    });

    test('a set naming nothing recognisable falls back to every die', () async {
      // Rather than leaving the app with zero dice and nothing to roll.
      await writeIndex({
        'version': 2,
        'enabledDice': ['aura'],
        'entries': <Object>[],
      });

      expect((await store().load()).enabledDice, isNull);
    });
  });

  group('ArtspirationState persistence', () {
    test('restores a previously saved gallery', () async {
      final first = ArtspirationState(store: store());
      addTearDown(first.dispose);
      first.saveToGallery();
      final expected = first.gallery.single.values;
      await first.settled;

      final second = ArtspirationState(store: store());
      addTearDown(second.dispose);
      await second.restore();

      expect(second.gallery, hasLength(1));
      expect(second.gallery.single.values, expected);
    });

    test('a removed entry stays gone after restart', () async {
      final first = ArtspirationState(store: store());
      addTearDown(first.dispose);
      first
        ..saveToGallery()
        ..saveToGallery();
      first.removeEntry(first.gallery.first.id);
      await first.settled;

      final second = ArtspirationState(store: store());
      addTearDown(second.dispose);
      await second.restore();

      expect(second.gallery, hasLength(1));
    });

    test('an attached photo survives a restart', () async {
      final bytes = Uint8List.fromList([9, 8, 7]);
      final first = ArtspirationState(store: store());
      addTearDown(first.dispose);
      first.saveToGallery();
      first.attachImage(first.gallery.single.id, bytes);
      await first.settled;

      final second = ArtspirationState(store: store());
      addTearDown(second.dispose);
      await second.restore();

      expect(second.gallery.single.imageBytes, bytes);
    });

    test('switched-off dice survive a restart', () async {
      final first = ArtspirationState(store: store());
      addTearDown(first.dispose);
      first
        ..setEnabled(DieCategory.texture, false)
        ..setEnabled(DieCategory.subject, false);
      await first.settled;

      final second = ArtspirationState(store: store());
      addTearDown(second.dispose);
      await second.restore();

      expect(second.die(DieCategory.texture).enabled, isFalse);
      expect(second.die(DieCategory.subject).enabled, isFalse);
      expect(second.die(DieCategory.medium).enabled, isTrue);
    });

    test('without a store nothing is written', () async {
      final state = ArtspirationState();
      addTearDown(state.dispose);
      state.saveToGallery();
      await state.settled;

      expect((await store().load()).entries, isEmpty);
    });
  });
}
