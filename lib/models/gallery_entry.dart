import 'dart:typed_data';

import '../data/categories.dart';

/// A saved roll: the six values captured at save time, plus the artwork the
/// user later attaches.
///
/// Artwork is held as bytes so one code path covers mobile and web (on web an
/// [XFile] path is a blob URL, which `Image.file` cannot read). Entries live in
/// memory only — nothing here survives a restart yet. When persistence lands,
/// swap [imageBytes] for a stored file reference and add to/from JSON.
class GalleryEntry {
  GalleryEntry({
    required this.id,
    required this.values,
    required this.rotation,
    this.imageBytes,
  });

  final String id;

  /// Every [DieCategory] is present.
  final Map<DieCategory, String> values;

  /// Degrees, in the range -1.5 to 1.5.
  final double rotation;

  final Uint8List? imageBytes;

  bool get hasImage => imageBytes != null;

  GalleryEntry withImage(Uint8List? bytes) {
    return GalleryEntry(
      id: id,
      values: values,
      rotation: rotation,
      imageBytes: bytes,
    );
  }
}
