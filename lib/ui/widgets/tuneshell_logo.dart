import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// The mark of TuneShell: a half shell, a half loudspeaker and a note at the
/// centre, the image kept in `docs/design/brand/` (FR-030). The same drawing
/// as the icon of the application, whatever the theme. Decorative for
/// TalkBack.
///
/// @implements FR-014
/// @implements FR-030
class TuneShellLogo extends StatelessWidget {
  const new({this.size = TsSize.logo, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Image.asset(
        'assets/brand/emblem.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}
