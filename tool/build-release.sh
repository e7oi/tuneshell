#!/usr/bin/env bash
# Builds the release APK with the identity of the build: commit, state of the
# working tree and day (FR-034, ADR-025). Extra arguments go to `flutter build`.
set -euo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "build-release.sh: run it inside the Git checkout of TuneShell." >&2
  exit 1
}
cd "$root"

commit="$(git rev-parse --short=7 HEAD)"
if [ -n "$(git status --porcelain)" ]; then dirty=true; else dirty=false; fi
day="$(date -u +%Y-%m-%d)"

echo "Build ${commit} (modified: ${dirty}, ${day})"
flutter build apk --release \
  --dart-define=BUILD_COMMIT="${commit}" \
  --dart-define=BUILD_DIRTY="${dirty}" \
  --dart-define=BUILD_DATE="${day}" \
  "$@"
