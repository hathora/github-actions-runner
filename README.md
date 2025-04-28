# GitHub Actions Runner on Hathora

This project enables you to deploy GitHub Actions runners on Hathora Cloud, allowing you to run GitHub Actions workflows in a scalable and managed environment.

## Prerequisites

- A [Hathora](https://hathora.dev) account
- A GitHub organization with admin access
- A GitHub token with appropriate permissions (see Setup section)
- Docker installed locally

## Setup

1. **Generate GitHub Token**
   - Create a Personal Access Token (PAT) in GitHub with the `admin:org` scope
   - Alternatively, you can use a GitHub App with the following permissions:
     - `actions:read` and `actions:write` for runner management
     - `metadata:read` for repository access
   - Store this token securely as you'll need it for deployment

2. **Create a Hathora Application**
   - Log in to the [Hathora Console](https://console.hathora.dev)
   - Create a new application

3. **Configure Environment Variables**
   Go to the "Settings" pane for your Application in Hathora and add the following environment variables
   ```
   GITHUB_TOKEN=your_github_token
   GITHUB_ORG=your_organization_name
   ```

## How It Works

The deployment consists of two main components:

1. **Dockerfile**: Based on the official GitHub Actions runner image, it sets up the environment for running GitHub Actions.

2. **init.sh**: A startup script that:
   - Generates a unique runner name
   - Obtains JIT (Just-In-Time) configuration from GitHub
   - Starts the runner with the obtained configuration

## Configuration Options

- `HATHORA_PROCESS_ID`: Automatically set by Hathora, used to generate unique runner names
- `HATHORA_REGION`: Automatically set by Hathora, indicates the deployment region
- `GITHUB_TOKEN`: Your GitHub token with appropriate permissions
- `GITHUB_ORG`: Your GitHub organization name

## Security Considerations

- Use the minimum required token permissions for your use case:
  - For organization-level runners: `admin:org` scope
  - For repository-level runners: `repo` scope
  - Consider using GitHub Apps for better security and granular permissions
- Each runner is ephemeral and gets a unique name
- The runner automatically registers with your organization using JIT configuration
- Regularly rotate your tokens and monitor their usage

## Troubleshooting

If you encounter issues:

1. Check the Hathora logs for any deployment errors
2. Verify your GitHub token has the correct permissions
3. Ensure your organization name is correct
4. Check that the runner is properly registered in your GitHub organization's settings

## License

This project is open source and available under the MIT License. 