import 'dart:typed_data';

import '../data/categories.dart';

/// A saved roll: the values captured at save time, plus the artwork the user
/// later attaches.
///
/// Artwork is held as bytes so one code path covers mobile and web (on web an
/// `XFile` path is a blob URL, which `Image.file` cannot read). The bytes are
/// written to a file alongside the JSON index — see `GalleryStore`.
class GalleryEntry {
  GalleryEntry({
    required this.id,
    required this.values,
    required this.rotation,
    this.imageBytes,
  });

  /// Rebuilds an entry from stored JSON. [imageBytes] comes from the entry's
  /// image file, which the store reads separately.
  ///
  /// Categories missing from [json] are skipped rather than defaulted: an entry
  /// saved before a die existed simply has no value for it, and an entry naming
  /// a die that has since been removed drops it. Neither should throw — these
  /// are ordinary consequences of the word lists changing between releases.
  factory GalleryEntry.fromJson(
    Map<String, Object?> json, {
    Uint8List? imageBytes,
  }) {
    final stored = (json['values'] as Map?)?.cast<String, Object?>() ?? {};
    return GalleryEntry(
      id: json['id']! as String,
      values: {
        for (final category in DieCategory.values)
          if (stored[category.name] case final String value)
            category: value,
      },
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
      imageBytes: imageBytes,
    );
  }

  final String id;

  /// Keyed by category. A category can be absent — see [GalleryEntry.fromJson].
  final Map<DieCategory, String> values;

  /// Degrees, in the range -1.5 to 1.5.
  final double rotation;

  final Uint8List? imageBytes;

  bool get hasImage => imageBytes != null;

  /// The image itself is stored in a separate file keyed by [id]; [hasImage]
  /// records whether one should be read back.
  Map<String, Object?> toJson() {
    return {
      'id': id,
      'rotation': rotation,
      'hasImage': hasImage,
      'values': {
        for (final entry in values.entries) entry.key.name: entry.value,
      },
    };
  }

  GalleryEntry withImage(Uint8List? bytes) {
    return GalleryEntry(
      id: id,
      values: values,
      rotation: rotation,
      imageBytes: bytes,
    );
  }
}
