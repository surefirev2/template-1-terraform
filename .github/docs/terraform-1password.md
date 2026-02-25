# 1Password setup for Terraform CI

Terraform plan and apply (and force-unlock) use a **personal GitHub PAT** loaded from 1Password in CI.

## 1Password secret

- **Reference:** `op://surefireops/github_actions_secrets_terraform/github_classic_token`
- **Vault:** `surefireops`
- **Item:** `github_actions_secrets_terraform`
- **Field:** `github_classic_token`

The PAT should have at least the scopes needed for the Terraform GitHub provider (e.g. `repo`, and **Vulnerability alerts** read if you manage `github_repository`). See [terraform-app-permissions.md](terraform-app-permissions.md).

## GitHub Actions

1. **Service account token:** In the repository (or org) secrets, set `OP_SERVICE_ACCOUNT_TOKEN` to a 1Password [service account token](https://developer.1password.com/docs/service-accounts/) that can read the vault/item above.

2. **Workflows:** The Terraform and Terraform force-unlock workflows use `1password/load-secrets-action@v3` with `export-env: true`, then run `.github/scripts/terraform-load-env.sh` to build `.env` from a configurable list (`.github/terraform-env-vars.conf`). That script copies listed env vars into `.env` and derives `TF_HTTP_PASSWORD` and `TF_VAR_github_token` from `GITHUB_PAT`. Downstream repos can add more variable names to `terraform-env-vars.conf` and set them in the workflow (e.g. extra 1Password refs or GitHub secrets) to customize which env vars Terraform gets in `.env`.

## Local / non-CI

For local runs or non-CI use, create a `.env` from [env.template](../env.template) and set `TF_HTTP_PASSWORD` (and optionally `TF_VAR_github_token`) to your PAT. You can read it from 1Password with:

```bash
op read "op://surefireops/github_actions_secrets_terraform/github_classic_token"
```
