# 1Password setup for Terraform CI

Terraform plan and apply (and force-unlock) use secrets loaded from 1Password in CI for the GitHub PAT, plus **GitHub Actions secrets** for AWS (S3 backend). **Design:** env vars are config-driven via `.github/terraform-env-vars.conf` and `.github/scripts/terraform-load-env.sh`; see [TERRAFORM_CI_DESIGN.md](TERRAFORM_CI_DESIGN.md).

## 1Password (GitHub PAT)

- **Reference:** `op://surefireops/github_actions_secrets_terraform/github_classic_token`
- **Vault:** `surefireops`
- **Item:** `github_actions_secrets_terraform`
- **Field:** `github_classic_token`

The PAT should have at least the scopes needed for the Terraform GitHub provider (e.g. `repo`, and **Vulnerability alerts** read if you manage `github_repository`). See [terraform-app-permissions.md](terraform-app-permissions.md).

## GitHub Actions secrets

1. **Service account token:** Set `OP_SERVICE_ACCOUNT_TOKEN` to a 1Password [service account token](https://developer.1password.com/docs/service-accounts/) that can read the vault/item above.

2. **AWS (S3 remote state):** Set repository secrets **`AWS_ACCESS_KEY_ID`** and **`AWS_SECRET_ACCESS_KEY`** for an IAM principal that can read/write the state bucket (and S3 native lock objects). Region is written into `.env` from `terraform-env-vars.conf` as `AWS_DEFAULT_REGION=us-east-1` unless you change the config.

3. **Workflow:** The workflow installs the 1Password CLI and runs `terraform-load-env.sh`, which reads `.github/terraform-env-vars.conf`, resolves `op://` refs, copies AWS secrets from the job `env`, and writes `.env` (including `TF_VAR_github_token` derived from `GITHUB_PAT`).

## Local / non-CI

Create a `.env` from [env.template](../../env.template) with `AWS_*` and optionally `GITHUB_PAT` / `TF_VAR_github_token`. To fetch the PAT from 1Password:

```bash
op read "op://surefireops/github_actions_secrets_terraform/github_classic_token"
```
