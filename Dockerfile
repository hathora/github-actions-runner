FROM ghcr.io/actions/actions-runner:2.323.0

# Copy and make init.sh executable
COPY init.sh .

# Use shell as entrypoint for proper signal handling
ENTRYPOINT ["/bin/bash", "init.sh"]
