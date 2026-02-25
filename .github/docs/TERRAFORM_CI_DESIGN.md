# Terraform CI design

This document describes how the Terraform workflow and scripts are structured so that design and implementation stay clear as files are synced or customized.

## Overview

- **Config-driven secrets**: Repo-specific `.github/terraform-env-vars.conf` lists env var names and optional `op://` refs. A generic script resolves refs and writes `.env`; the workflow only supplies `OP_SERVICE_ACCOUNT_TOKEN` and org/repo. No workflow edits when adding new secrets.
- **Lock file**: Committed `.terraform.lock.hcl` is generated with `terraform init -backend=false` so it only contains `required_providers` (no backend-only providers). Pre-commit and CI run the same check; the hook can auto-fix the file and exit 1 so you commit the fix. Use `make lockfile` to regenerate.
- **State lock**: Before plan/apply, a wait-unlock script polls with `terraform plan` until the state is free or a timeout; then it may force-unlock so the run can proceed. Plan/apply use `make` (Docker + `.env`).

## Pipeline phases (workflow)

1. **Bootstrap**: Checkout, make scripts executable, optional lockfile check (pre-commit), Docker setup.
2. **Env**: Install 1Password CLI → run `terraform-load-env.sh` (reads `terraform-env-vars.conf`, writes `.env`) → terraform-setup action.
3. **Validate**: `make validate` (init + validate in Docker with `.env`).
4. **Init for plan**: `make init` so `.terraform` and providers exist in the workspace for the wait-unlock script (which runs plan in Docker).
5. **Wait unlock (pre-plan)**: `terraform-wait-unlock.sh` — init once in container, then loop plan until unlocked or timeout; force-unlock on timeout if a lock ID can be parsed.
6. **Plan**: `make plan`; on failure, parse lock ID and run lock-handle (force-unlock if stale, else cache for next run).
7. **Apply** (push to main only): Wait unlock again, then apply with unlock-retry script.

## Key files

| File | Role |
|------|------|
| `.github/terraform-env-vars.conf` | Repo-specific list of env vars (and optional `op://` refs). Add `TF_VAR_<name>` here for Terraform variables; the generic script does not derive them. |
| `.github/scripts/terraform-load-env.sh` | Generic: reads config, resolves `op://` with 1Password CLI, writes `.env`. Derives only `TF_HTTP_PASSWORD` / `TF_VAR_github_token` from `GITHUB_PAT` so the backend works. |
| `.github/scripts/terraform-wait-unlock.sh` | Runs `terraform init -reconfigure` once so providers exist, then polls `terraform plan` until state is unlocked or timeout; force-unlocks on timeout when possible. |
| `.github/scripts/terraform-lockfile-readonly.sh` | Pre-commit / CI: `init -backend=false -lockfile=readonly` in a temp dir; on failure, overwrites repo lock file with `init -backend=false` and exits 1. |
| `.github/workflows/terraform.yaml` | Orchestrates the phases above; step names and comments mirror this design. |

## Customizing per repo

- **Secrets**: Edit only `terraform-env-vars.conf`. Use `VAR=op://...` for 1Password; use `TF_VAR_<terraform_var>=op://...` so Terraform sees the variable. The load script is generic and must not contain provider- or repo-specific logic so it can be reverse-synced.
- **Lock file**: Regenerate with `make lockfile` after changing providers; commit the result. Do not commit a lock file produced by `make init` (with backend) or pre-commit will fail.
