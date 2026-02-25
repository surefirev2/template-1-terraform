# 1Password setup for Terraform CI

Terraform plan and apply (and force-unlock) load secrets from 1Password in a **config-driven** way: the workflow does not list individual secrets; `.github/terraform-env-vars.conf` is the single source of truth.

## Config-driven design

- **Add a new Terraform secret:** add one line to `.github/terraform-env-vars.conf` (e.g. `CLOUDFLARE_API_TOKEN=op://vault/item/field`). No workflow edits.
- **Workflow:** installs 1Password CLI, runs `.github/scripts/terraform-load-env.sh` with `OP_SERVICE_ACCOUNT_TOKEN`. The script reads the config, resolves each `VAR=op://...` ref via `op read`, and writes `.env`.

Config format (one per line):

- `VAR_NAME` — value from environment (e.g. workflow env/secrets).
- `VAR_NAME=op://vault/item/field` — value from 1Password (resolved by the script using the op CLI).

## 1Password secret (template default)

- **Reference:** `op://surefireops/github_actions_secrets_terraform/github_classic_token`
- **Vault:** `surefireops`
- **Item:** `github_actions_secrets_terraform`
- **Field:** `github_classic_token`

The PAT should have at least the scopes needed for the Terraform GitHub provider (e.g. `repo`, and **Vulnerability alerts** read if you manage `github_repository`). See [terraform-app-permissions.md](terraform-app-permissions.md).

## GitHub Actions

1. **Service account token:** In the repository (or org) secrets, set `OP_SERVICE_ACCOUNT_TOKEN` to a 1Password [service account token](https://developer.1password.com/docs/service-accounts/) that can read the vaults/items you reference in `terraform-env-vars.conf`.

2. **Workflows:** Install 1Password CLI (`1password/install-cli-action@v2`), then run `terraform-load-env.sh` with `OP_SERVICE_ACCOUNT_TOKEN`, `TF_GITHUB_ORG`, and `TF_GITHUB_REPO`. The script reads `.github/terraform-env-vars.conf` and resolves every `VAR=op://...` line; no per-secret entries in the workflow YAML.

## Local / non-CI

For local runs or non-CI use, create a `.env` from [env.template](../env.template) and set `TF_HTTP_PASSWORD` (and optionally `TF_VAR_github_token`) to your PAT. You can read it from 1Password with:

```bash
op read "op://surefireops/github_actions_secrets_terraform/github_classic_token"
```
