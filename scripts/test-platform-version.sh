#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
normalizer="$script_dir/platform-version.sh"

assert_version() {
  local input="$1"
  local expected="$2"
  local actual
  actual="$("$normalizer" "$input")"
  if [[ "$actual" != "$expected" ]]; then
    echo "Expected $input to normalize to $expected, got $actual." >&2
    exit 1
  fi
}

assert_version "1.2.3" "v1.2.3"
assert_version "v1.2.3" "v1.2.3"
assert_version "octo-pr-labeler-v1.2.3" "v1.2.3"
assert_version "octo-pr-labeler-v1.2.3-rc.1" "v1.2.3-rc.1"

if "$normalizer" "not-a-version" >/dev/null 2>&1; then
  echo "Expected an invalid release tag to be rejected." >&2
  exit 1
fi

echo "Platform version normalization passed."
