import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// The search field that replaces the title of a list: a back arrow that
/// closes the search, the text, and a button that clears it (FR-027).
///
/// It holds the keyboard focus only for an empty field: a search restored
/// when the user comes back to the view does not bring the keyboard up.
///
/// @implements FR-027
class SearchField extends StatefulWidget {
  const new({
    required this.text,
    required this.hint,
    required this.clearLabel,
    required this.backLabel,
    required this.onChanged,
    required this.onClose,
    super.key,
  });

  /// The text the field starts with.
  final String text;
  final String hint;
  final String clearLabel;
  final String backLabel;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  State<SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<SearchField> {
  static const _target = BoxConstraints.tightFor(
    width: TsSize.touchTarget,
    height: TsSize.touchTarget,
  );

  late final TextEditingController _controller = TextEditingController(
    text: widget.text,
  );
  late final FocusNode _focus = FocusNode();
  late final bool _autofocus = widget.text.isEmpty;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _clear() {
    _controller.clear();
    widget.onChanged('');
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: TsSize.touchTarget + TsSpace.s,
      child: Row(
        children: [
          IconButton(
            tooltip: widget.backLabel,
            icon: const Icon(Icons.arrow_back_rounded),
            constraints: _target,
            onPressed: widget.onClose,
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              autofocus: _autofocus,
              textInputAction: TextInputAction.search,
              onChanged: widget.onChanged,
              onSubmitted: (_) => _focus.unfocus(),
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: widget.hint,
                border: InputBorder.none,
                hintStyle: Theme.of(context).textTheme.bodyLarge
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _controller.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: widget.clearLabel,
                    icon: const Icon(Icons.close_rounded),
                    constraints: _target,
                    onPressed: _clear,
                  ),
          ),
        ],
      ),
    );
  }
}
