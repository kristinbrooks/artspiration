import 'package:flutter/material.dart' show showModalBottomSheet;
import 'package:flutter/widgets.dart';
import 'package:image_picker/image_picker.dart';

import '../data/categories.dart';
import '../models/gallery_entry.dart';
import '../state/app_state.dart';
import '../theme/tokens.dart';
import '../widgets/sticker.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key, required this.state, required this.topInset});

  final ArtspirationState state;
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final entries = state.gallery;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(18, topInset, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _GalleryHeader(count: entries.length),
          const SizedBox(height: 16), // 14px column gap + 2px header margin
          if (entries.isEmpty)
            const _EmptyState()
          else
            for (var i = 0; i < entries.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              _GalleryCard(
                entry: entries[i],
                onRemove: () => state.removeEntry(entries[i].id),
                onPickImage: () => _pickImage(context, entries[i].id),
              ),
            ],
        ],
      ),
    );
  }

  Future<void> _pickImage(BuildContext context, String id) async {
    final source = await _chooseSource(context);
    if (source == null) return;

    final file = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2000,
      imageQuality: 88,
    );
    if (file == null) return;

    // Bytes rather than a path so the same code works on web, where an
    // XFile path is a blob URL that Image.file cannot read.
    state.attachImage(id, await file.readAsBytes());
  }

  Future<ImageSource?> _chooseSource(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0x00000000),
      builder: (context) => const _SourceSheet(),
    );
  }
}

class _GalleryHeader extends StatelessWidget {
  const _GalleryHeader({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = switch (count) {
      0 => 'No saved rolls yet',
      1 => '1 saved roll',
      _ => '$count saved rolls',
    };

    return Column(
      children: [
        Transform.rotate(
          angle: AppShape.deg(-1.5),
          child: Text('Your Gallery', style: AppText.kalam(26)),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppText.nunito(13, color: AppColors.mutedBrown)),
      ],
    );
  }
}

class _GalleryCard extends StatelessWidget {
  const _GalleryCard({
    required this.entry,
    required this.onRemove,
    required this.onPickImage,
  });

  final GalleryEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onPickImage;

  @override
  Widget build(BuildContext context) {
    return Sticker(
      rotation: entry.rotation,
      borderRadius: AppShape.radii(18, 22, 18, 22),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _ArtworkSlot(entry: entry, onTap: onPickImage),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final category in DieCategory.values)
                _ValueChip(
                  label: entry.values[category]!,
                  color: category.accent,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Remove',
                  style: AppText.nunito(
                    12,
                    weight: 600,
                    color: AppColors.removeRed,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 170px artwork slot. Empty it invites a photo; filled it shows one, and
/// tapping again replaces it.
class _ArtworkSlot extends StatelessWidget {
  const _ArtworkSlot({required this.entry, required this.onTap});

  final GalleryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(12);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 170,
        child: entry.hasImage
            ? ClipRRect(
                borderRadius: radius,
                child: Image.memory(
                  entry.imageBytes!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              )
            : Sticker(
                borderRadius: radius,
                background: const Color(0x14241C14),
                borderColor: AppColors.dashedRule,
                borderWidth: 1.5,
                dashed: true,
                showShadow: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('+', style: AppText.kalam(28, color: AppColors.emptyTitle)),
                      const SizedBox(height: 2),
                      Text(
                        'Tap to add your artwork',
                        style: AppText.nunito(
                          13,
                          weight: 600,
                          color: AppColors.emptyTitle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _ValueChip extends StatelessWidget {
  const _ValueChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: AppText.nunito(10.5, weight: 800, color: const Color(0xFFFFFFFF)),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Sticker(
      borderRadius: BorderRadius.circular(20),
      background: const Color(0x00000000),
      borderColor: AppColors.dashedRule,
      dashed: true,
      showShadow: false,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 48),
      child: Column(
        children: [
          Text(
            'Nothing here yet!',
            style: AppText.kalam(18, weight: 400, color: AppColors.emptyTitle),
          ),
          const SizedBox(height: 6),
          Text(
            'Roll some dice and save a combo to start your gallery.',
            textAlign: TextAlign.center,
            style: AppText.nunito(13, color: AppColors.emptyBody),
          ),
        ],
      ),
    );
  }
}

/// Photo library vs. camera, in the app's own visual language rather than a
/// stock platform sheet.
class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SourceOption(
              label: 'Choose from photos',
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 10),
            _SourceOption(
              label: 'Take a photo',
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceOption extends StatelessWidget {
  const _SourceOption({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Sticker(
        borderRadius: AppShape.radii(18, 22, 18, 22),
        padding: const EdgeInsets.all(14),
        child: Center(
          child: Text(label, style: AppText.nunito(14, weight: 800)),
        ),
      ),
    );
  }
}
