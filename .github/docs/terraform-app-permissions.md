# GitHub App permissions for Terraform CI

Workflows that run Terraform using a GitHub App token (`vars.APP_ID` / `secrets.PRIVATE_KEY`) need the App to have the right permissions. Otherwise you may see:

```text
Error: error reading repository vulnerability alerts: GET .../vulnerability-alerts: 403 Resource not accessible by integration
```

## Required permissions

In the GitHub App’s **Repository permissions** (GitHub → Organization → Developer settings → GitHub Apps → your App → Permissions and events):

| Permission              | Access   | Why |
|-------------------------|----------|-----|
| **Vulnerability alerts** | Read-only | Needed when Terraform manages `github_repository` and the provider reads or configures vulnerability alerts. |
| **Contents**            | Read and write | For repos that manage repo content. |
| **Metadata**            | Read-only | Always needed for repo access. |

If your Terraform only manages repositories (create/update repo settings), ensure **Vulnerability alerts** is set to **Read-only**. After changing permissions, existing installation tokens don’t get the new scopes until a new token is issued (e.g. on the next workflow run).

## Where to set them

1. **Organization:** Settings → Developer settings → GitHub Apps → select the App → **Permissions and events**.
2. Under **Repository permissions**, set **Vulnerability alerts** to **Read-only** (or Read and write if you change that setting in Terraform).
3. Save. The next workflow run will use a token that includes the new permission.
