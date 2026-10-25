import 'package:flutter/material.dart';
import 'package:tuneshell/ui/theme/tuneshell_tokens.dart';

/// The heading of a group of settings (FR-023.1).
///
/// @implements FR-010
class SettingsSectionHeader extends StatelessWidget {
  const new(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      TsSpace.screenMargin,
      TsSpace.xl,
      TsSpace.screenMargin,
      TsSpace.xs,
    ),
    child: Semantics(
      header: true,
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    ),
  );
}

/// A setting that opens a page: label, explanation, an optional badge, and
/// an arrow (FR-023.1).
///
/// @implements FR-010
class SettingsNavTile extends StatelessWidget {
  const new({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badge,
    this.semanticsLabel,
    this.showArrow = true,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// The arrow says that a page opens; an action has none.
  final bool showArrow;

  /// Greyed and silent while false (an action that has to wait).
  final bool enabled;

  /// A short text in the warning colour, such as "1 absent": the state is
  /// in words, not in the colour alone (BR-007, rule 3).
  final String? badge;
  final String? semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: semanticsLabel ?? [title, ?subtitle, ?badge].join(', '),
      enabled: enabled,
      onTap: enabled ? onTap : null,
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TsSize.settingsRow),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TsSpace.screenMargin,
              vertical: TsSpace.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.titleMedium?.copyWith(
                          color: enabled
                              ? null
                              : TsColors.of(context).unavailable,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                if (badge != null) ...[
                  const SizedBox(width: TsSpace.s),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(TsRadius.full),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: TsSpace.s,
                        vertical: TsSpace.xs,
                      ),
                      child: Text(
                        badge!,
                        style: text.labelMedium?.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
                if (showArrow) ...[
                  const SizedBox(width: TsSpace.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A setting with two states: label, explanation, switch (FR-023.1). When
/// [enabled] is false it is greyed, and the explanation says why.
///
/// @implements FR-010
class SettingsSwitchTile extends StatelessWidget {
  const new({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = enabled ? null : TsColors.of(context).unavailable;
    return Semantics(
      toggled: value,
      enabled: enabled,
      label: [title, ?subtitle].join(', '),
      onTap: enabled ? () => onChanged(!value) : null,
      excludeSemantics: true,
      child: InkWell(
        onTap: enabled ? () => onChanged(!value) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: TsSize.settingsRow),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: TsSpace.screenMargin,
              vertical: TsSpace.s,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: text.titleMedium?.copyWith(color: muted),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          style: text.bodyMedium?.copyWith(
                            color: muted ?? scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: TsSpace.m),
                ExcludeSemantics(
                  child: Switch(
                    value: value,
                    onChanged: enabled ? onChanged : null,
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

/// A setting with a few exclusive choices, as a segmented button (FR-024.1).
///
/// @implements FR-010
class SettingsSegmentedTile<T> extends StatelessWidget {
  const new({
    required this.title,
    required this.choices,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final String title;

  /// Each choice with the label it shows.
  final List<(T value, String label)> choices;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: TsSpace.screenMargin,
      vertical: TsSpace.s,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: TsSpace.s),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<T>(
            showSelectedIcon: false,
            segments: [
              for (final (value, label) in choices)
                ButtonSegment<T>(value: value, label: Text(label)),
            ],
            selected: {selected},
            onSelectionChanged: (selection) => onChanged(selection.first),
          ),
        ),
      ],
    ),
  );
}
