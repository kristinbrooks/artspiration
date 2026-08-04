import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/gallery_entry.dart';
import 'app_store.dart';
import 'categories.dart';

/// Stores app state under the app documents directory:
///
///     gallery/index.json   the settings and entries, newest first
///     gallery/<id>.img     one file per attached photo
///
/// Photos are kept as separate files rather than inlined into the JSON so that
/// rewriting the index — which happens on every save, remove, and photo attach
/// — does not rewrite megabytes of image data.
class FileAppStore implements AppStore {
  FileAppStore({Directory? root}) : this._(root);

  FileAppStore._(this._root);

  static const _folder = 'gallery';
  static const _indexName = 'index.json';
  static const _imageSuffix = '.img';

  /// 1 had no `enabledDice`; files at that version predate switchable dice and
  /// are read as having every die in play.
  static const _schemaVersion = 2;

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
  Future<StoredState> load() async {
    try {
      final dir = await _directory();
      final index = File('${dir.path}/$_indexName');
      if (!await index.exists()) return const StoredState.empty();

      final decoded = jsonDecode(await index.readAsString());
      if (decoded is! Map<String, Object?>) return const StoredState.empty();

      return StoredState(
        entries: await _readEntries(dir, decoded['entries']),
        enabledDice: _readEnabledDice(decoded['enabledDice']),
      );
    } catch (error, stack) {
      // Corrupt or unreadable state should cost the user their history, not
      // their ability to open the app.
      debugPrint('Could not load app state: $error\n$stack');
      return const StoredState.empty();
    }
  }

  Future<List<GalleryEntry>> _readEntries(Directory dir, Object? raw) async {
    if (raw is! List) return const [];

    final entries = <GalleryEntry>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final json = item.cast<String, Object?>();
      if (json['id'] is! String) continue;

      Uint8List? bytes;
      if (json['hasImage'] == true) {
        final file = _imageFile(dir, json['id']! as String);
        if (await file.exists()) bytes = await file.readAsBytes();
      }
      entries.add(GalleryEntry.fromJson(json, imageBytes: bytes));
    }
    return entries;
  }

  /// Names that no longer match a die are dropped. If nothing survives, the
  /// setting is discarded rather than leaving zero dice in play.
  Set<DieCategory>? _readEnabledDice(Object? raw) {
    if (raw is! List) return null;

    final names = raw.whereType<String>().toSet();
    final enabled = {
      for (final category in DieCategory.values)
        if (names.contains(category.name)) category,
    };
    return enabled.isEmpty ? null : enabled;
  }

  @override
  Future<void> save(StoredState state) async {
    final dir = await _directory();

    // Write photos first: a crash between here and the index leaves an orphaned
    // file, which the next save cleans up. The reverse order would leave an
    // index pointing at a photo that was never written.
    for (final entry in state.entries) {
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
        if (state.enabledDice case final enabled?)
          'enabledDice': [for (final category in enabled) category.name],
        'entries': [for (final entry in state.entries) entry.toJson()],
      }),
      flush: true,
    );

    await _deleteOrphans(dir, state.entries);
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

AppStore createStore() => FileAppStore();
