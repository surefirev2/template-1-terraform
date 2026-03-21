#!/bin/bash

# Function to get value from .env if it exists
get_env_var() {
  local var_name="$1"
  if [[ -f .env ]]; then
    grep -E "^$var_name=" .env | head -n1 | cut -d'=' -f2-
  fi
}

# Get defaults from .env if available
DEFAULT_GITHUB_PAT=$(get_env_var "GITHUB_PAT")
DEFAULT_ANTHROPIC_API_KEY=$(get_env_var "ANTHROPIC_API_KEY")

# Prompt for GitHub token
if [[ -n "$DEFAULT_GITHUB_PAT" ]]; then
  read -p "Enter your GitHub Personal Access Token [default: $DEFAULT_GITHUB_PAT]: " GITHUB_PAT
  GITHUB_PAT="${GITHUB_PAT:-$DEFAULT_GITHUB_PAT}"
else
  read -sp "Enter your GitHub Personal Access Token: " GITHUB_PAT
  echo
fi

# Prompt for Anthropic API key
if [[ -n "$DEFAULT_ANTHROPIC_API_KEY" ]]; then
  read -p "Enter your Anthropic API Key [default: $DEFAULT_ANTHROPIC_API_KEY]: " ANTHROPIC_API_KEY
  ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-$DEFAULT_ANTHROPIC_API_KEY}"
else
  read -sp "Enter your Anthropic API Key: " ANTHROPIC_API_KEY
  echo
fi

# Copy env.template to .env in root
echo "Setting up .env in root directory..."
cp env.template .env
sed -i "s|GITHUB_PAT=.*|GITHUB_PAT=$GITHUB_PAT|" .env
if grep -q '^ANTHROPIC_API_KEY=' .env 2>/dev/null; then
  sed -i "s|ANTHROPIC_API_KEY=.*|ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY|" .env
else
  echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" >> .env
fi

# Install pre-commit hook (runs make run-pre-commit)
echo "Setting up git pre-commit hook..."
if [[ -d .git/hooks ]]; then
  cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/sh
# Git pre-commit hook to run pre-commit checks

make run-pre-commit
RESULT=$?
if [ $RESULT -ne 0 ]; then
  echo "Pre-commit checks failed. Commit aborted."
  exit 1
fi

exit 0
HOOK
  chmod +x .git/hooks/pre-commit
else
  echo "Skipping pre-commit hook: .git/hooks not found (run git init first)."
fi

echo "Setup complete."
echo

echo "Next steps:"
echo "  1. Run: npm install"
echo "  2. Then initialize Task Master: npx task-master init"
echo "  3. Configure MCP servers in Cursor (e.g. .cursor/mcp.json) using keys from .env as needed"
echo
