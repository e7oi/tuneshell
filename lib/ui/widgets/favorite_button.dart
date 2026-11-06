import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// The heart of the full-screen player: filled when the track is a favorite,
/// with a light tap of feedback; TalkBack hears [label] and that it is a
/// toggle (FR-017.5, FR-031.3).
///
/// @implements FR-010
class FavoriteButton extends StatelessWidget {
  const new({
    required this.selected,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final bool selected;

  /// What a tap does: "Add to favorites" or "Remove from favorites".
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: TsSize.touchTarget,
    child: IconButton(
      tooltip: label,
      isSelected: selected,
      icon: const Icon(Icons.favorite_border_rounded),
      selectedIcon: const Icon(Icons.favorite_rounded),
      onPressed: () {
        unawaited(HapticFeedback.lightImpact());
        onPressed();
      },
    ),
  );
}
