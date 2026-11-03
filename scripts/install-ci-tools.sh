#!/usr/bin/env bash
set -euo pipefail

version="${OCTO_TOOL_VERSION:-v0.11.14}"
destination="${1:?usage: install-ci-tools.sh DESTINATION}"
base_url="https://github.com/juancavallotti/octo/releases/download/${version}"
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

mkdir -p "$destination"
curl --fail --location --silent --show-error --retry 3 \
  --output "$scratch/checksums.txt" "$base_url/checksums.txt"

for tool in octo dolphin octopaas; do
  archive="${tool}_linux_amd64.tar.gz"
  curl --fail --location --silent --show-error --retry 3 \
    --output "$scratch/$archive" "$base_url/$archive"
done

(
  cd "$scratch"
  grep -E ' (octo|dolphin|octopaas)_linux_amd64\.tar\.gz$' checksums.txt |
    sha256sum --check -
)

for tool in octo dolphin octopaas; do
  tar -xzf "$scratch/${tool}_linux_amd64.tar.gz" -C "$scratch" "$tool"
  install -m 0755 "$scratch/$tool" "$destination/$tool"
done
