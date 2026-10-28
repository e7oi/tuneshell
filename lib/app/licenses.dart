import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the licence of the application and those of its fonts to the ones
/// Flutter lists for the packages (FR-026.2). Called once at start.
void registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'TuneShell',
    ], await rootBundle.loadString('LICENSE'));
    yield LicenseEntryWithLineBreaks([
      'Manrope',
    ], await rootBundle.loadString('assets/fonts/Manrope-OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Inter',
    ], await rootBundle.loadString('assets/fonts/Inter-OFL.txt'));
  });
}
