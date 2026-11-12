import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// A piece of text that opens something: underlined, since colour alone must
/// not tell a link from its neighbours, with a touch area of 48 dp and a
/// label for TalkBack (FR-032.5).
///
/// @implements FR-032
class TextLink extends StatelessWidget {
  const new({
    required this.text,
    required this.semanticsLabel,
    required this.onTap,
    this.style,
    super.key,
  });

  final String text;

  /// What TalkBack says: "Open the album {title}".
  final String semanticsLabel;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Semantics(
    link: true,
    label: semanticsLabel,
    excludeSemantics: true,
    onTap: onTap,
    child: InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: TsSize.touchTarget),
        child: Align(
          widthFactor: 1,
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: (style ?? const TextStyle()).copyWith(
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ),
    ),
  );
}
