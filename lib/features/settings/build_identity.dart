import 'package:tuneshell/domain/settings/app_info.dart';
import 'package:tuneshell/l10n/generated/app_localizations.dart';

/// The text that says which build is running: "0.1.0 · a1b2c3d · modified ·
/// 2026-11-14", or "0.1.0 · local build" when the build has no identity.
///
/// @implements FR-034
String buildIdentity(AppLocalizations l10n, String version, BuildInfo info) => [
  version,
  if (info.isLocal) l10n.buildLocal else info.commit,
  if (info.dirty) l10n.buildModified,
  if (info.date.isNotEmpty) info.date,
].join(' · ');
