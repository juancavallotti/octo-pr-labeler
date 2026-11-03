# Octo PR Auto Labeler

This repository is the source for the [Octo PR Auto Labeler integration](https://octopaas.dev/platform/i/8ec66cf4-e38b-45fe-b9c8-fb43eb865bae). It verifies GitHub pull request webhooks, reads changed files, and adds `backend`, `front-end`, and `module: name` labels to pull requests in `juancavallotti/octo`.

The integration definition was pulled with `octopaas`. The repo tracks the definition and its Dolphin suite. The platform's `.env.webhook` resource contains live credentials and is deliberately absent from Git.

## Files

| Path | Purpose |
| --- | --- |
| `integration.yaml` | The integration's runtime definition |
| `.octo/tests/github-pull-request_test.yaml` | Dolphin cases, including webhook signatures, pagination, module labels, and rejected signatures |
| `.env.webhook.example` | Synthetic values for local and CI tests |
| `.github/workflows/ci-release.yml` | PR tests, Release Please, and rollout |
| `scripts/deploy.sh` | Upload the tracked files, create a version, and roll out the existing deployment |

## Run the tests locally

Install matching `octo` and `dolphin` binaries from the [Octo v0.11.14 release](https://github.com/juancavallotti/octo/releases/tag/v0.11.14). Then, from this repo:

```bash
test -e .env.webhook || cp .env.webhook.example .env.webhook
dolphin test --config integration.yaml .octo/tests/github-pull-request_test.yaml
```

The suite supplies fake GitHub credentials and mocks GitHub API calls. It does not label real pull requests. The local `.env.webhook` file is ignored by Git.

## Refresh from Octo

Pull into an empty temporary directory, then copy only the tracked definition and suite:

```bash
scratch="$(mktemp -d)"
octopaas integrations pull 8ec66cf4-e38b-45fe-b9c8-fb43eb865bae "$scratch"
cp "$scratch/integration.yaml" integration.yaml
cp "$scratch/.octo/tests/github-pull-request_test.yaml" .octo/tests/
dolphin test --config integration.yaml .octo/tests/github-pull-request_test.yaml
```

Inspect the diff before committing. Keep `$scratch/.env.webhook` and the bundle manifest out of this repository. Delete the temporary directory when done.

## CI and release flow

1. A pull request runs the Dolphin suite on GitHub Actions.
2. A push to `main` runs the suite again. If it passes, [Release Please](https://github.com/googleapis/release-please-action) opens or updates a release PR from Conventional Commits such as `fix: ...` and `feat: ...`.
3. Merging the release PR triggers another `main` run. After tests pass, Release Please creates a GitHub release and a `vX.Y.Z` tag.
4. The deploy job checks out that tag, updates `integration.yaml` and the Dolphin suite on Octo, creates an Octo version with the same tag, and rolls out the existing deployment. It waits for the rollout result.

The deploy script updates the two tracked files individually. It preserves the platform's `.env.webhook` resource and the deployment's existing secret bindings. It also reuses an existing Octo version when rerunning the same release tag.

To retry a released version, run **Test, release, and deploy** from the Actions tab with **Run workflow** and enter an existing `release_tag`. The workflow tests that tag before rolling it out.

## One-time GitHub setup

- Add an `OCTOPAAS_KEY` Actions secret to the `production` environment (or at repository level). Mint an Octo API key from your platform account with permission to edit this integration, create versions, and roll out its deployment. The workflow uses `https://api.octopaas.dev` as `OCTOPAAS_URL`.
- Allow GitHub Actions to create pull requests in **Settings → Actions → General**, so Release Please can open its release PR.
- Optionally add a `RELEASE_PLEASE_TOKEN` secret containing a GitHub App token or PAT with repository content and pull request write access. Without it, Release Please uses `GITHUB_TOKEN`; GitHub does not start separate CI runs for PRs created by that token. The merge into `main` still runs Dolphin before any release or rollout.
- If desired, protect the `production` environment with required reviewers. That holds the rollout until it is approved.

The release manifest starts at `1.0.0`, matching the existing Octo `v1.0.0` version. The first feature release from this repo will use a later version.

## Module labels

The flow adds each touched module once. The mapping covers the root Go module (`runtime/`, `samples/`, and root Go module files), the `orchestrator/`, `logs/`, and `sidecars/` Go modules, the three `apps/` workspaces, and the five `packages/` workspaces. A file outside those paths can still receive `backend` or `front-end` when its extension matches.
