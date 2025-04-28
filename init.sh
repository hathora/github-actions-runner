#!/bin/bash
if [ -n "$HATHORA_PROCESS_ID" ]; then
  RUNNER_NAME="hathora-${HATHORA_REGION}-${HATHORA_PROCESS_ID}"
else
  RUNNER_NAME="runner-$(openssl rand -hex 4)"
fi

# Get encoded JIT config from GitHub API
encoded_jit_config=$(curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer ${GITHUB_TOKEN}" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/orgs/${GITHUB_ORG}/actions/runners/generate-jitconfig \
  -d "{\"name\":\"${RUNNER_NAME}\",\"runner_group_id\":1,\"labels\":[\"self-hosted\",\"linux\"]}" | jq -r .encoded_jit_config)

if [ -z "$encoded_jit_config" ]; then
  echo "Failed to get JIT config from GitHub API"
  exit 1
fi

# Start the runner in the background
./run.sh --jitconfig ${encoded_jit_config} &
RUNNER_PID=$!

# Function to forward signals to the runner process
forward_signal() {
  echo "Received signal $1, forwarding to runner process"
  kill -$1 $RUNNER_PID
}

# Trap signals and forward them to the runner process
trap 'forward_signal SIGTERM' SIGTERM
trap 'forward_signal SIGINT' SIGINT
trap 'forward_signal SIGHUP' SIGHUP

# Wait for the runner process to complete
wait $RUNNER_PID
