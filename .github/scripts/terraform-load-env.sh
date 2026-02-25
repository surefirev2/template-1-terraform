#!/usr/bin/env bash
# Build .env for Terraform from the current environment using a configurable list of var names.
# Usage: run from repo root. Set TF_GITHUB_ORG and TF_GITHUB_REPO in CI (e.g. from github.repository_owner / repository.name).
# Config: .github/terraform-env-vars.conf lists env var names to copy into .env (one per line).
# Downstream repos can add more names and provide values via workflow secrets or 1Password.

set -euo pipefail

CONFIG="${1:-.github/terraform-env-vars.conf}"
ENV_FILE="${2:-.env}"

if [[ ! -f "$CONFIG" ]]; then
  echo "Config not found: $CONFIG" >&2
  exit 1
fi

: "${TF_GITHUB_ORG:?TF_GITHUB_ORG is required}"
: "${TF_GITHUB_REPO:?TF_GITHUB_REPO is required}"

# Start fresh .env
: > "$ENV_FILE"

# Copy each listed var from env into .env (value must not contain newlines for simple .env format)
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -z "$line" ]] && continue
  name="$line"
  if [[ -n "${!name:-}" ]]; then
    # Escape for .env: no newlines; quote if value contains space or #
    val="${!name}"
    if [[ "$val" == *$'\n'* ]]; then
      echo "Skipping $name: value contains newline" >&2
      continue
    fi
    if [[ "$val" == *[[:space:]#]* ]]; then
      echo "${name}=\"${val}\"" >> "$ENV_FILE"
    else
      echo "${name}=${val}" >> "$ENV_FILE"
    fi
  fi
done < "$CONFIG"

# Terraform backend and provider: derive from GITHUB_PAT when set
if [[ -n "${GITHUB_PAT:-}" ]]; then
  echo "TF_HTTP_PASSWORD=${GITHUB_PAT}" >> "$ENV_FILE"
  echo "TF_VAR_github_token=${GITHUB_PAT}" >> "$ENV_FILE"
fi

# Required for backend / init
echo "TF_GITHUB_ORG=${TF_GITHUB_ORG}" >> "$ENV_FILE"
echo "TF_GITHUB_REPO=${TF_GITHUB_REPO}" >> "$ENV_FILE"

echo "Wrote $ENV_FILE from $CONFIG and TF_GITHUB_ORG/TF_GITHUB_REPO."
