#!/usr/bin/env bash
set -euo pipefail

release="${1:?usage: deploy.sh RELEASE_VERSION_OR_TAG}"
if [[ -n "${CI:-}" && -z "${OCTOPAAS_KEY:-}" ]]; then
  echo "Set the OCTOPAAS_KEY GitHub Actions secret before deploying." >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "$script_dir/.." && pwd)"
tag="$("$script_dir/platform-version.sh" "$release")"

integration_id="8ec66cf4-e38b-45fe-b9c8-fb43eb865bae"
deployment_id="7b8ec3f4-f63c-461d-819b-980dd58d3972"

echo "Publishing Release Please version $release as Octo platform version $tag."

versions_json="$(octopaas versions list "$integration_id" --output json)"
if jq -e --arg tag "$tag" 'any(.[]; .tag == $tag)' <<<"$versions_json" >/dev/null; then
  echo "Version $tag already exists; rolling it out again."
else
  # A push replaces the whole integration with the folder it is given, so we
  # stage exactly the files the tracked manifest names and push that, rather
  # than the checkout with its README, scripts and release files.
  manifest="$repo_dir/.octo/octo-bundle.json"
  bundle_dir="$(mktemp -d)"
  trap 'rm -rf "$bundle_dir"' EXIT
  mkdir -p "$bundle_dir/.octo"
  cp "$manifest" "$bundle_dir/.octo/"
  while IFS= read -r file; do
    mkdir -p "$bundle_dir/$(dirname "$file")"
    cp "$repo_dir/$file" "$bundle_dir/$file"
  done < <(jq -r '.configs[], .resources[].name' "$manifest")
  octopaas integrations push "$integration_id" "$bundle_dir"
  octopaas versions create "$integration_id" "$tag"
fi

octopaas deployments rollout "$deployment_id" --version "$tag"
