#!/usr/bin/env bash
set -euo pipefail

tag="${1:?usage: deploy.sh RELEASE_TAG}"
if [[ -n "${CI:-}" && -z "${OCTOPAAS_KEY:-}" ]]; then
  echo "Set the OCTOPAAS_KEY GitHub Actions secret before deploying." >&2
  exit 1
fi

integration_id="8ec66cf4-e38b-45fe-b9c8-fb43eb865bae"
deployment_id="7b8ec3f4-f63c-461d-819b-980dd58d3972"
suite_resource=".octo/tests/github-pull-request_test.yaml"

versions_json="$(octopaas versions list "$integration_id" --output json)"
if jq -e --arg tag "$tag" 'any(.[]; .tag == $tag)' <<<"$versions_json" >/dev/null; then
  echo "Version $tag already exists; rolling it out again."
else
  octopaas files put "$integration_id" integration.yaml --from integration.yaml

  suite_id="$(
    octopaas resources list "$integration_id" --output json |
      jq -r --arg name "$suite_resource" '[.[] | select(.name == $name and .kind == "template")] | first | .id // empty'
  )"
  if [[ -n "$suite_id" ]]; then
    octopaas resources update "$integration_id" "$suite_id" \
      --kind template --name "$suite_resource" --from "$suite_resource"
  else
    octopaas resources create "$integration_id" \
      --kind template --name "$suite_resource" --from "$suite_resource"
  fi

  octopaas versions create "$integration_id" "$tag"
fi

octopaas deployments rollout "$deployment_id" --version "$tag"
