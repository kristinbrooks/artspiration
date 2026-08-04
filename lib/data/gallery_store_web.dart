import '../models/gallery_entry.dart';
import 'gallery_store.dart';

/// Web has no `dart:io`, and the browser targets exist only for design
/// verification — so the gallery stays in memory there. Entries and photos
/// survive tab reloads on neither; that's a known limit, not a failure path.
class NoopGalleryStore implements GalleryStore {
  const NoopGalleryStore();

  @override
  Future<List<GalleryEntry>> load() async => const [];

  @override
  Future<void> save(List<GalleryEntry> entries) async {}
}

GalleryStore createStore() => const NoopGalleryStore();
