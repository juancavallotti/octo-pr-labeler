#!/usr/bin/env bash
set -euo pipefail

release="${1:?usage: platform-version.sh RELEASE_VERSION_OR_TAG}"

# Release Please names this component's Git tag octo-pr-labeler-vX.Y.Z, while
# Octo versions use the component version itself. Accept all forms used by the
# automatic and manual workflow paths and always emit the canonical platform
# tag.
if [[ "$release" =~ ^(octo-pr-labeler-)?v?([0-9]+\.[0-9]+\.[0-9]+(-[0-9A-Za-z.-]+)?(\+[0-9A-Za-z.-]+)?)$ ]]; then
  printf 'v%s\n' "${BASH_REMATCH[2]}"
  exit 0
fi

echo "Invalid release version or tag: $release" >&2
echo "Expected X.Y.Z, vX.Y.Z, or octo-pr-labeler-vX.Y.Z." >&2
exit 1
