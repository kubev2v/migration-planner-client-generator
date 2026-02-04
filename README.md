# OpenAPI Client Generator

A GitOps repository providing a reusable GitHub Actions workflow for generating and publishing OpenAPI clients to npm.

## Overview

This repository contains a [reusable workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows) that can be called from other repositories to generate TypeScript clients from OpenAPI specifications and publish them to npm.

### Features

- **Reusable Workflow**: Call from any authorized repository using `workflow_call`
- **Hardcoded Generator Settings**: Consistent client generation with standardized configuration
- **Authorization Control**: Only authorized repositories can trigger the workflow
- **Dry-Run Mode**: Test client generation without publishing

## Usage

### Calling the Reusable Workflow

Add the following workflow to your repository (e.g., `.github/workflows/update-api-client.yml`):

```yaml
name: Update API Client Package

on:
  push:
    branches: [main]
    paths: ['api/openapi.yaml']
  workflow_dispatch:
    inputs:
      version:
        description: 'Version to publish'
        required: true

# Required for npm Trusted Publishing (OIDC)
permissions:
  id-token: write
  contents: read

jobs:
  generate-client:
    uses: kubev2v/migration-planner-client-generator/.github/workflows/generate-and-publish.yml@main
    with:
      openapi-spec-url: "https://raw.githubusercontent.com/your-org/your-repo/main/api/openapi.yaml"
      package-name: "@your-scope/api-client"
      package-version: ${{ inputs.version || '0.0.1' }}
    # Required: passes OIDC permissions to the reusable workflow
    secrets: inherit
```

### Workflow Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `openapi-spec-url` | Yes | - | URL to the OpenAPI specification file |
| `package-name` | Yes | - | npm package name (e.g., `@scope/package-name`) |
| `package-version` | Yes | - | Package version to publish (semver) |
| `npm-registry` | No | `https://registry.npmjs.org` | npm registry URL |
| `dry-run` | No | `false` | Skip npm publish (for testing) |

### npm Publishing Authentication

This workflow uses **npm Trusted Publishing (OIDC)** as the primary authentication method:

- **No long-lived npm tokens needed** - OIDC provides short-lived, workflow-specific credentials
- Requires `id-token: write` permission in calling workflow
- Requires [Trusted Publisher](https://docs.npmjs.com/trusted-publishers) configured on npmjs.com
- Use `secrets: inherit` to pass OIDC permissions to the reusable workflow

### Required Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `ALLOWED_REPOS` | Yes | JSON array of authorized repository names |
| `NPM_TOKEN` | No | Only needed for local testing with act-cli (OIDC fallback) |

## Generator Configuration

The workflow uses hardcoded generator settings that **cannot be modified by callers**:

| Setting | Value |
|---------|-------|
| Generator | `typescript-fetch` |
| Output Directory | `generated-client` |
| `ensureUniqueParams` | `true` |
| `supportsES6` | `true` |
| `withInterfaces` | `true` |
| `importFileExtension` | `.js` |

These settings match the configuration in [kubev2v/migration-planner-ui](https://github.com/kubev2v/migration-planner-ui).

## Authorization Model

### How Authorization Works

The workflow includes a mandatory authorization check before generating and publishing clients.

1. **Self-Authorization**: Calls from this repository (`kubev2v/migration-planner-client-generator`) are automatically authorized for CI/testing purposes
2. **Secret-based Allowlist**: External repositories must be listed in the `ALLOWED_REPOS` secret (JSON array)
3. **Exact Match**: Uses `jq` for precise string matching (no partial matches)
4. **Fail-Fast**: Unauthorized requests are rejected before any generation occurs

### Configuring Authorization

Set the `ALLOWED_REPOS` secret in this repository with a JSON array of external repositories:

```json
["kubev2v/migration-planner", "kubev2v/migration-planner-ui"]
```

> **Note**: You don't need to add this repository to `ALLOWED_REPOS` - it's automatically authorized.

### Security Features

- Allowlist is stored as a secret (never exposed in logs or workflow file)
- Exact string matching prevents partial name attacks
- JSON format is validated before use
- Error messages don't reveal which repos are authorized

## Local Development

### Testing with act-cli

Use [act](https://github.com/nektos/act) to test GitHub Actions locally:

```bash
# Install act (macOS)
brew install act

# Setup secrets file (first time)
make setup-secrets

# Run test workflow (dry-run mode - no npm publishing)
make test

# Run test workflow with actual npm publishing (requires real NPM_TOKEN)
make test-publish

# Cleanup generated files
make clean
```

### Make Targets

| Command | Description |
|---------|-------------|
| `make test` | Run workflow in dry-run mode (tests generation/build only) |
| `make test-publish` | Run workflow with actual npm publishing + cleanup |
| `make test-verbose` | Run workflow with verbose output |
| `make setup-secrets` | Create `.secrets` file template |
| `make clean` | Remove generated artifacts |

### CI Feature Toggle

The test workflow runs in **dry-run mode by default** to avoid npm rate limits.

To enable actual npm publishing in CI:
1. Go to Settings > Secrets and variables > Actions > Variables
2. Add: `TEST_NPM_PUBLISH` = `true`
3. Bump `TEST_PACKAGE_VERSION` in `test.yml` before each test

When enabled, test packages are automatically unpublished after successful publish.

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── generate-and-publish.yml   # Reusable workflow
│       └── test.yml                   # CI test workflow
├── .actrc                             # act-cli configuration
├── .gitignore                         # Ignores generated-client/, secrets, etc.
├── Makefile                           # Local testing commands (make test, make clean)
├── AGENTS.md                          # AI agent guidelines
├── LICENSE                            # Apache-2.0
└── README.md                          # This file
```

## Related

- [ECOPROJECT-3956](https://issues.redhat.com/browse/ECOPROJECT-3956) - Jira issue for this project
- [kubev2v/migration-planner-ui](https://github.com/kubev2v/migration-planner-ui) - UI monorepo using this workflow
- [kubev2v/migration-planner](https://github.com/kubev2v/migration-planner) - Backend API repository
- [openapi-generator](https://openapi-generator.tech/) - OpenAPI Generator documentation

## License

Apache-2.0
