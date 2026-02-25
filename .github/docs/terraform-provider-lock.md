# Terraform provider lock file and "Missing required provider"

**Best practice:** Pin provider versions by committing **`.terraform.lock.hcl`**. Terraform fills this file when you run `terraform init`; commit it so everyone and CI use the same provider versions.

## Why "Missing required provider" happens

Terraform installs providers based on **`.terraform.lock.hcl`** (the dependency lock file). `terraform init` only installs providers that appear in that file (and that your config requires). It does **not** install providers just because they appear in remote state.

So the error appears when:

1. **State** (on the backend) was created with a provider (e.g. `cloudflare`) — the state file references it.
2. **Lock file** in the repo does **not** include that provider (e.g. you added the provider and resources but never ran `terraform init` and committed the updated lock file).
3. In CI, `terraform init` only installs what’s in the lock file; the first `plan` then fails with "Missing required provider … that provider isn't available".

In other words: **the lock file is out of sync with what state (or config) requires.**

## How to prevent it

After adding or changing providers (or versions):

1. From the repo root, run:
   ```bash
   make init
   ```
   or, to also allow new versions:
   ```bash
   cd terraform && terraform init -upgrade
   ```
2. **Commit** the updated `terraform/.terraform.lock.hcl`.

Then CI will install all required providers and plan/apply will succeed.

## Pre-commit

The **terraform-lockfile** hook runs on changes under `terraform/*.tf` and `terraform/*.hcl`. It runs `terraform init -backend=false -lockfile=readonly` and fails if the lock file would need to be updated, so you fix it before committing. Requires the Terraform CLI on `PATH`; use `SKIP=terraform-lockfile` to skip (e.g. if you only use Docker).

## CI behavior

- The workflow runs `make init` once (Terraform setup + Validate). That installs every provider listed in `.terraform.lock.hcl` into `terraform/.terraform`.
- The wait-unlock script does **not** run `terraform init` again; it reuses that same `.terraform` so provider set is consistent. If the lock file were missing a provider, the first plan (in wait-unlock or in "Run Terraform plan") would still fail until you update and commit the lock file as above.
