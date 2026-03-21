# 1Password setup for Terraform CI

Terraform plan and apply (and force-unlock) load **GitHub PAT and AWS credentials** from 1Password in CI (S3 backend + GitHub provider). **Design:** env vars are config-driven via `.github/terraform-env-vars.conf` and `.github/scripts/terraform-load-env.sh`; see [TERRAFORM_CI_DESIGN.md](TERRAFORM_CI_DESIGN.md).

## 1Password item: `github_actions_secrets_terraform` (vault `surefireops`)

| Purpose | `op read` reference |
|--------|----------------------|
| GitHub PAT | `op://surefireops/github_actions_secrets_terraform/github_classic_token` |
| AWS access key (S3 state) | `op://surefireops/github_actions_secrets_terraform/AWS_ACCESS_KEY_ID` |
| AWS secret key | `op://surefireops/github_actions_secrets_terraform/AWS_SECRET_ACCESS_KEY` |

Add **custom fields** (or labeled fields) on that item named `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` so the CLI can resolve those paths. The IAM principal must be allowed to read/write the Terraform state bucket (and S3 native lock objects).

The PAT should have at least the scopes needed for the Terraform GitHub provider (e.g. `repo`, and **Vulnerability alerts** read if you manage `github_repository`). See [terraform-app-permissions.md](terraform-app-permissions.md).

## GitHub Actions

1. **1Password service account (GitHub secret):** In the repo (or org) **Actions secrets**, create **`OP_SERVICE_ACCOUNT_TOKEN`**. Workflows pass it as `${{ secrets.OP_SERVICE_ACCOUNT_TOKEN }}` into `terraform-load-env.sh`. The value must be a 1Password [service account token](https://developer.1password.com/docs/service-accounts/) that can read the vault/item above (including the AWS fields).

2. **Workflow:** The workflow installs the 1Password CLI (`1password/install-cli-action`) and runs `terraform-load-env.sh`, which resolves every `op://...` line in `.github/terraform-env-vars.conf` and writes `.env` (including `TF_VAR_github_token` derived from `GITHUB_PAT`).

## Local / non-CI

Create a `.env` from [env.template](../../env.template) with `AWS_*` and optionally `GITHUB_PAT` / `TF_VAR_github_token`. To read values from 1Password:

```bash
op read "op://surefireops/github_actions_secrets_terraform/github_classic_token"
op read "op://surefireops/github_actions_secrets_terraform/AWS_ACCESS_KEY_ID"
op read "op://surefireops/github_actions_secrets_terraform/AWS_SECRET_ACCESS_KEY"
```
