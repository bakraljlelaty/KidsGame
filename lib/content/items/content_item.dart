import 'dart:ui';

import '../../core/audio/voice_catalog.dart';

/// One piece of teachable content: a shape, color, number, letter, animal,
/// or object. Pure data — engines decide how to present it and ItemArt
/// draws it.
class ContentItem {
  const ContentItem({
    required this.id,
    String? artId,
    this.color,
    this.nameVoice,
    this.value,
    this.group,
    this.glyph,
  }) : artId = artId ?? id;

  /// Stable unique id, e.g. 'color_red', 'shape_circle', 'num_3',
  /// 'letter_a', 'ar_alif', 'animal_cow'.
  final String id;

  /// ItemArt painter key (defaults to [id]).
  final String artId;

  /// Fill color for shape/color items (and tile tint for glyphs).
  final Color? color;

  /// The spoken name of this item ("red", "circle", "three", "A"...).
  final VoiceInstruction? nameVoice;

  /// Numeric value for counting content.
  final int? value;

  /// Sorting/pattern category, e.g. 'fruit', 'animal', 'vehicle'.
  final String? group;

  /// Character drawn for letter/number tiles.
  final String? glyph;
}
