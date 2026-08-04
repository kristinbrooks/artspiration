import '../models/gallery_entry.dart';
import 'gallery_store_web.dart'
    if (dart.library.io) 'gallery_store_io.dart' as platform;

/// Where saved rolls live between launches.
///
/// The implementation is chosen at compile time: file-backed on iOS and
/// Android, a no-op on web. `dart:io` cannot be imported into a web build at
/// all, hence the conditional import rather than a runtime `kIsWeb` check.
abstract class GalleryStore {
  /// Returns the stored entries, newest first. Never throws — unreadable or
  /// corrupt storage yields an empty gallery rather than a failed launch.
  Future<List<GalleryEntry>> load();

  /// Writes [entries] and drops any image files they no longer reference.
  Future<void> save(List<GalleryEntry> entries);
}

/// The store for the platform this was compiled for.
GalleryStore createGalleryStore() => platform.createStore();
