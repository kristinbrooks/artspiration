import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../theme/tokens.dart';

/// One of the six prompt dice.
///
/// Each carries its own accent color and its own slightly-off geometry. The
/// radii and rotations are per-category on purpose — reusing one set across
/// all six cards is what makes the grid look machine-made.
enum DieCategory {
  medium(
    label: 'Medium',
    accent: Color(0xFFE2572B),
    cardRotation: -1.6,
    pillRotation: -2,
    corners: (16, 22, 18, 24),
    options: [
      'Watercolor',
      'Charcoal',
      'Digital Paint',
      'Collage',
      'Ink Wash',
      'Clay Sculpt',
      'Colored Pencil',
      'Gouache',
      'Linocut Print',
      'Embroidery',
    ],
  ),
  mood(
    label: 'Mood',
    accent: Color(0xFF1F8A70),
    cardRotation: 1.4,
    pillRotation: 2,
    corners: (22, 16, 24, 18),
    options: [
      'Melancholic',
      'Joyful',
      'Eerie',
      'Nostalgic',
      'Chaotic',
      'Serene',
      'Whimsical',
      'Tense',
      'Dreamy',
      'Triumphant',
    ],
  ),
  palette(
    label: 'Palette',
    accent: Color(0xFF7C5CBF),
    cardRotation: 1.8,
    pillRotation: -2,
    corners: (24, 18, 16, 22),
    options: [
      'Sunset Warm',
      'Monochrome Blue',
      'Neon Pop',
      'Earth Tones',
      'Pastel Candy',
      'Black & White',
      'Jewel Tones',
      'Autumn Rust',
    ],
  ),
  style(
    label: 'Style',
    accent: Color(0xFFC98A1F),
    cardRotation: -1.2,
    pillRotation: 2,
    corners: (18, 24, 22, 16),
    options: [
      'Surrealism',
      'Art Nouveau',
      'Cubism',
      'Pop Art',
      'Ukiyo-e',
      'Brutalism',
      'Impressionism',
      'Bauhaus',
      'Vaporwave',
      'Folk Art',
    ],
  ),
  setting(
    label: 'Setting',
    accent: Color(0xFF2F6FB0),
    cardRotation: -1.4,
    pillRotation: -2,
    corners: (20, 16, 26, 18),
    options: [
      'Underwater City',
      'Abandoned Carnival',
      'Floating Market',
      'Desert Ruins',
      'Neon Alleyway',
      'Mountain Monastery',
      'Overgrown Library',
      'Space Station',
      'Foggy Harbor',
      'Enchanted Forest',
    ],
  ),
  texture(
    label: 'Texture',
    accent: Color(0xFFB23A6B),
    cardRotation: 1.6,
    pillRotation: 2,
    corners: (16, 20, 18, 26),
    options: [
      'Rough Burlap',
      'Glossy Ceramic',
      'Cracked Earth',
      'Soft Velvet',
      'Rusted Metal',
      'Woven Basket',
      'Frosted Glass',
      'Tree Bark',
      'Crumpled Paper',
      'Scaly Skin',
    ],
  );

  const DieCategory({
    required this.label,
    required this.accent,
    required this.cardRotation,
    required this.pillRotation,
    required this.corners,
    required this.options,
  });

  final String label;
  final Color accent;

  /// Degrees.
  final double cardRotation;
  final double pillRotation;

  /// CSS order: top-left, top-right, bottom-right, bottom-left.
  final (double, double, double, double) corners;

  final List<String> options;

  BorderRadius get borderRadius =>
      AppShape.radii(corners.$1, corners.$2, corners.$3, corners.$4);

  /// Picks a random option, avoiding [exclude] so a reroll always visibly
  /// changes. Falls through when the list has only one entry.
  String roll(math.Random random, {String? exclude}) {
    if (options.length == 1) return options.first;
    var value = options[random.nextInt(options.length)];
    while (value == exclude) {
      value = options[random.nextInt(options.length)];
    }
    return value;
  }
}
