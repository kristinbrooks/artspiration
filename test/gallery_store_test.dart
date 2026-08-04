import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:artspiration/data/categories.dart';
import 'package:artspiration/data/gallery_store_io.dart';
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

  FileGalleryStore store() => FileGalleryStore(root: root);

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

  File imageFile(String id) => File('${root.path}/gallery/$id.img');

  group('FileGalleryStore', () {
    test('an empty store loads an empty gallery', () async {
      expect(await store().load(), isEmpty);
    });

    test('entries round-trip with their values, rotation, and order', () async {
      await store().save([entry('a', rotation: -1.25), entry('b')]);

      final loaded = await store().load();

      expect(loaded.map((e) => e.id), ['a', 'b']);
      expect(loaded.first.rotation, -1.25);
      expect(loaded.first.values, hasLength(DieCategory.values.length));
      expect(
        loaded.first.values[DieCategory.medium],
        DieCategory.medium.options.first,
      );
    });

    test('photos round-trip', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      await store().save([entry('a', image: bytes)]);

      final loaded = await store().load();

      expect(loaded.single.hasImage, isTrue);
      expect(loaded.single.imageBytes, bytes);
    });

    test('an entry without a photo loads without one', () async {
      await store().save([entry('a')]);
      expect((await store().load()).single.hasImage, isFalse);
    });

    test('removing an entry deletes its photo file', () async {
      await store().save([
        entry('a', image: Uint8List.fromList([1])),
        entry('b', image: Uint8List.fromList([2])),
      ]);
      expect(await imageFile('a').exists(), isTrue);

      await store().save([entry('b', image: Uint8List.fromList([2]))]);

      expect(await imageFile('a').exists(), isFalse);
      expect(await imageFile('b').exists(), isTrue);
      expect((await store().load()).map((e) => e.id), ['b']);
    });

    test('a corrupt index yields an empty gallery rather than throwing',
        () async {
      await store().save([entry('a')]);
      await File('${root.path}/gallery/index.json').writeAsString('{not json');

      expect(await store().load(), isEmpty);
    });

    test('an entry whose photo file vanished still loads', () async {
      await store().save([entry('a', image: Uint8List.fromList([1]))]);
      await imageFile('a').delete();

      final loaded = await store().load();

      expect(loaded, hasLength(1));
      expect(loaded.single.hasImage, isFalse);
    });

    test('values for categories that no longer exist are dropped', () async {
      // Simulates a gallery written by an older build that had a die since
      // removed, alongside one it never knew about.
      await Directory('${root.path}/gallery').create(recursive: true);
      await File('${root.path}/gallery/index.json').writeAsString(
        jsonEncode({
          'version': 1,
          'entries': [
            {
              'id': 'old',
              'rotation': 0.0,
              'hasImage': false,
              'values': {
                'medium': 'Watercolor',
                'aura': 'Retired die',
              },
            },
          ],
        }),
      );

      final loaded = await store().load();

      expect(loaded.single.values, {DieCategory.medium: 'Watercolor'});
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

    test('without a store nothing is written', () async {
      final state = ArtspirationState();
      addTearDown(state.dispose);
      state.saveToGallery();
      await state.settled;

      expect(await store().load(), isEmpty);
    });
  });
}
