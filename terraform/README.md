# Terraform (template hello-world)

Backend: tfstate.dev HTTP, key `surefirev2/template-1-terraform`. Requires `.env` with `TF_HTTP_PASSWORD`, `TF_GITHUB_ORG`, `TF_GITHUB_REPO` (see Terraform setup action).

**CI (GitHub Actions):** Plan and apply use a personal GitHub PAT loaded from 1Password at `op://surefireops/github_actions_secrets_terraform/github_classic_token`. The repo must have `OP_SERVICE_ACCOUNT_TOKEN` set in GitHub Actions secrets (1Password service account token). See [.github/docs/terraform-1password.md](../.github/docs/terraform-1password.md).

**GitHub token permissions:** If Terraform manages `github_repository` (or similar) and plan fails with `403 Resource not accessible by integration` on vulnerability-alerts, the PAT (or GitHub App, if used elsewhere) needs **Vulnerability alerts** (Read-only). See [.github/docs/terraform-app-permissions.md](../.github/docs/terraform-app-permissions.md).

## State cleanup (orphaned resources)

If remote state was written by an old/different config (e.g. it contains `github_*` resources that are no longer in this config), clean it so only current resources remain.

**Using Make (from repo root):**

```bash
# Ensure .env exists and init has run (backend + providers)
make init

# See what's in state
make state-list

# Remove every resource except local_file.hello_world
make state-clean-orphans
```

**Manual (same backend via Docker):**

```bash
# From repo root; .env must exist
make init

# List state resources
docker run --rm --env-file .env \
  -u $(id -u):$(id -g) \
  -v "$(pwd)/terraform:/workspace" -w /workspace \
  terraform state list

# Remove one resource by address (repeat for each orphan)
docker run --rm --env-file .env \
  -u $(id -u):$(id -g) \
  -v "$(pwd)/terraform:/workspace" -w /workspace \
  terraform state rm 'github_repository.repos["example"]'
```

After cleanup, `make plan` should only show the `local_file.hello_world` resource (or no changes if it already exists in state).
