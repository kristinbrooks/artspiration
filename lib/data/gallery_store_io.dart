import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/gallery_entry.dart';
import 'gallery_store.dart';

/// Stores the gallery under the app documents directory:
///
///     gallery/index.json   the entries, newest first
///     gallery/<id>.img     one file per attached photo
///
/// Photos are kept as separate files rather than inlined into the JSON so that
/// rewriting the index — which happens on every save, remove, and reroll — does
/// not rewrite megabytes of image data.
class FileGalleryStore implements GalleryStore {
  FileGalleryStore({Directory? root}) : this._(root);

  FileGalleryStore._(this._root);

  static const _folder = 'gallery';
  static const _indexName = 'index.json';
  static const _imageSuffix = '.img';
  static const _schemaVersion = 1;

  /// Injectable so tests can use a temp directory instead of the real one.
  final Directory? _root;

  Directory? _resolved;

  Future<Directory> _directory() async {
    final existing = _resolved;
    if (existing != null) return existing;

    final base = _root ?? await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_folder');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return _resolved = dir;
  }

  File _imageFile(Directory dir, String id) =>
      File('${dir.path}/$id$_imageSuffix');

  @override
  Future<List<GalleryEntry>> load() async {
    try {
      final dir = await _directory();
      final index = File('${dir.path}/$_indexName');
      if (!await index.exists()) return const [];

      final decoded = jsonDecode(await index.readAsString());
      if (decoded is! Map<String, Object?>) return const [];
      final rawEntries = decoded['entries'];
      if (rawEntries is! List) return const [];

      final entries = <GalleryEntry>[];
      for (final raw in rawEntries) {
        if (raw is! Map) continue;
        final json = raw.cast<String, Object?>();
        if (json['id'] is! String) continue;

        Uint8List? bytes;
        if (json['hasImage'] == true) {
          final file = _imageFile(dir, json['id']! as String);
          if (await file.exists()) bytes = await file.readAsBytes();
        }
        entries.add(GalleryEntry.fromJson(json, imageBytes: bytes));
      }
      return entries;
    } catch (error, stack) {
      // A corrupt or unreadable gallery should cost the user their history,
      // not their ability to open the app.
      debugPrint('Could not load gallery: $error\n$stack');
      return const [];
    }
  }

  @override
  Future<void> save(List<GalleryEntry> entries) async {
    final dir = await _directory();

    // Write photos first: a crash between here and the index leaves an orphaned
    // file, which the next save cleans up. The reverse order would leave an
    // index pointing at a photo that was never written.
    for (final entry in entries) {
      if (entry.imageBytes case final bytes?) {
        final file = _imageFile(dir, entry.id);
        if (!await file.exists()) {
          await file.writeAsBytes(bytes, flush: true);
        }
      }
    }

    await File('${dir.path}/$_indexName').writeAsString(
      jsonEncode({
        'version': _schemaVersion,
        'entries': [for (final entry in entries) entry.toJson()],
      }),
      flush: true,
    );

    await _deleteOrphans(dir, entries);
  }

  /// Removes image files for entries that are gone, so deleting a card actually
  /// reclaims its photo.
  Future<void> _deleteOrphans(
    Directory dir,
    List<GalleryEntry> entries,
  ) async {
    final keep = {
      for (final entry in entries)
        if (entry.hasImage) '${entry.id}$_imageSuffix',
    };

    await for (final file in dir.list()) {
      if (file is! File) continue;
      final name = file.uri.pathSegments.last;
      if (name == _indexName || keep.contains(name)) continue;
      if (!name.endsWith(_imageSuffix)) continue;
      try {
        await file.delete();
      } catch (_) {
        // Losing a stale file is not worth failing the save over.
      }
    }
  }
}

GalleryStore createStore() => FileGalleryStore();
