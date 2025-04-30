#!/bin/bash
set -euo pipefail

# Generate a unique runner name
if [ -n "${HATHORA_PROCESS_ID:-}" ]; then
  RUNNER_NAME="hathora-${HATHORA_REGION}-${HATHORA_PROCESS_ID}"
else
  RUNNER_NAME="runner-$(openssl rand -hex 4)"
fi

echo "Starting GitHub Actions runner with name: ${RUNNER_NAME}"

# Parse additional labels from environment variable
ADDITIONAL_LABELS_ARRAY=()
if [ -n "${ADDITIONAL_LABELS:-}" ]; then
  # Split the labels string by commas and add each label to the array
  IFS=',' read -ra LABELS <<< "$ADDITIONAL_LABELS"
  for label in "${LABELS[@]}"; do
    # Trim whitespace from each label
    label=$(echo "$label" | xargs)
    if [ -n "$label" ]; then
      ADDITIONAL_LABELS_ARRAY+=("$label")
    fi
  done
fi

# Combine default labels with additional labels
ALL_LABELS=("self-hosted" "linux" "hathora")
ALL_LABELS+=("${ADDITIONAL_LABELS_ARRAY[@]}")

# Convert labels array to JSON array
LABELS_JSON=$(printf '%s\n' "${ALL_LABELS[@]}" | jq -R . | jq -s .)

# Get JIT configuration from GitHub API
encoded_jit_config=$(curl -sSL \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/generate-jitconfig" \
  -d "{\"name\":\"${RUNNER_NAME}\",\"runner_group_id\":1,\"labels\":${LABELS_JSON}}" \
  | jq -r '.encoded_jit_config')

# Verify we got a valid JIT config
if [ -z "${encoded_jit_config}" ]; then
  echo "❌ Failed to get JIT config from GitHub API"
  exit 1
fi

echo "✅ Successfully obtained JIT configuration"

# Start the runner
echo "🚀 Starting GitHub Actions runner..."
exec ./run.sh --jitconfig "${encoded_jit_config}"
