# 1Password setup for Terraform CI

Terraform plan and apply (and force-unlock) use secrets loaded from 1Password in CI. **Design:** env vars are config-driven via `.github/terraform-env-vars.conf` and `.github/scripts/terraform-load-env.sh`; see [TERRAFORM_CI_DESIGN.md](TERRAFORM_CI_DESIGN.md).

## 1Password secret

- **Reference:** `op://surefireops/github_actions_secrets_terraform/github_classic_token`
- **Vault:** `surefireops`
- **Item:** `github_actions_secrets_terraform`
- **Field:** `github_classic_token`

The PAT should have at least the scopes needed for the Terraform GitHub provider (e.g. `repo`, and **Vulnerability alerts** read if you manage `github_repository`). See [terraform-app-permissions.md](terraform-app-permissions.md).

## GitHub Actions

1. **Service account token:** In the repository (or org) secrets, set `OP_SERVICE_ACCOUNT_TOKEN` to a 1Password [service account token](https://developer.1password.com/docs/service-accounts/) that can read the vault/item above.

2. **Workflows:** The workflow installs the 1Password CLI and runs `terraform-load-env.sh`, which reads `.github/terraform-env-vars.conf` and resolves `op://` refs into `.env` (including `TF_HTTP_PASSWORD` / `TF_VAR_github_token` derived from `GITHUB_PAT`).

## Local / non-CI

For local runs or non-CI use, create a `.env` from [env.template](../env.template) and set `TF_HTTP_PASSWORD` (and optionally `TF_VAR_github_token`) to your PAT. You can read it from 1Password with:

```bash
op read "op://surefireops/github_actions_secrets_terraform/github_classic_token"
```
