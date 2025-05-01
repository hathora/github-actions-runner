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
ALL_LABELS=("self-hosted" "linux")
ALL_LABELS+=("${ADDITIONAL_LABELS_ARRAY[@]}")

# Convert labels array to JSON array
LABELS_JSON=$(printf '%s\n' "${ALL_LABELS[@]}" | jq -R . | jq -s .)

# Get JIT configuration from GitHub API
response=$(curl -sSL \
  -w "%{http_code}" \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  "https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/generate-jitconfig" \
  -d "{\"name\":\"${RUNNER_NAME}\",\"runner_group_id\":1,\"labels\":${LABELS_JSON}}")

# Extract the HTTP status code (last 3 characters)
http_code=${response: -3}
# Extract the response body (everything except last 3 characters)
response_body=${response:0:-3}

# Check if the request was successful
if [ "$http_code" != "201" ]; then
  error_message=$(echo "$response_body" | jq -r '.message // "Unknown error"')
  echo "❌ Failed to get JIT config from GitHub API (HTTP $http_code): $error_message"
  exit 1
fi

# Extract the encoded JIT config
encoded_jit_config=$(echo "$response_body" | jq -r '.encoded_jit_config')

# Verify we got a valid JIT config
if [ -z "${encoded_jit_config}" ] || [ "${encoded_jit_config}" = "null" ]; then
  echo "❌ Failed to get JIT config from GitHub API: No encoded_jit_config in response"
  exit 1
fi

echo "✅ Successfully obtained JIT configuration"

# Start the runner
echo "🚀 Starting GitHub Actions runner..."
exec ./run.sh --jitconfig "${encoded_jit_config}"
