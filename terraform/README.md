# Terraform (template hello-world)

## Remote state (S3)

- **Bucket:** `surefirev2-terraform-state` (region `us-east-1`)
- **Key:** `github/surefirev2/template-1-terraform/terraform.tfstate`
- **Locking:** S3 native (`use_lockfile = true` in the backend block)

**tfstate.dev:** That HTTP backend is **no longer used**. The service appears **down entirely**, so prior remote state could not be migrated. This repo starts **fresh state** in S3. The next `apply` will treat every managed object as new—if real resources already exist elsewhere, you may see “already exists” errors or drift; fix with **import**, state surgery, or manual cleanup as appropriate. Do not `apply` blindly on shared environments without a plan.

**Credentials:** Put `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` in `.env` (see [env.template](../env.template)). `make` passes `.env` into the Terraform Docker runs.

**Missing required provider?** CI installs providers from `terraform/.terraform.lock.hcl`. If you add a new provider (e.g. Cloudflare), run `make init` and **commit** the updated lock file. See [.github/docs/terraform-provider-lock.md](../.github/docs/terraform-provider-lock.md).

**CI (GitHub Actions):** Plan and apply build `.env` via `.github/terraform-env-vars.conf` and `terraform-load-env.sh`. You need:

- `OP_SERVICE_ACCOUNT_TOKEN` (1Password service account)
- `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` (IAM user or role keys for the state bucket)

See [.github/docs/terraform-1password.md](../.github/docs/terraform-1password.md).

**GitHub token permissions:** If Terraform manages `github_repository` (or similar) and plan fails with `403 Resource not accessible by integration` on vulnerability-alerts, the PAT needs **Vulnerability alerts** (Read-only). See [.github/docs/terraform-app-permissions.md](../.github/docs/terraform-app-permissions.md).

## State cleanup (orphaned resources)

If remote state contains resources that are no longer in this config, clean it so only current resources remain.

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
