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

jobs:
  generate-client:
    uses: kubev2v/migration-planner-client-generator/.github/workflows/generate-and-publish.yml@main
    with:
      openapi-spec-url: "https://raw.githubusercontent.com/your-org/your-repo/main/api/openapi.yaml"
      package-name: "@your-scope/api-client"
      package-version: ${{ inputs.version || '0.0.1' }}
    secrets:
      NPM_TOKEN: ${{ secrets.NPM_TOKEN }}
      ALLOWED_REPOS: ${{ secrets.ALLOWED_REPOS }}
```

### Workflow Inputs

| Input | Required | Default | Description |
|-------|----------|---------|-------------|
| `openapi-spec-url` | Yes | - | URL to the OpenAPI specification file |
| `package-name` | Yes | - | npm package name (e.g., `@scope/package-name`) |
| `package-version` | Yes | - | Package version to publish (semver) |
| `npm-registry` | No | `https://registry.npmjs.org` | npm registry URL |
| `dry-run` | No | `false` | Skip npm publish (for testing) |

### Required Secrets

| Secret | Description |
|--------|-------------|
| `NPM_TOKEN` | npm access token with publish permissions |
| `ALLOWED_REPOS` | JSON array of authorized repository names |

## Generator Configuration

The workflow uses hardcoded generator settings that **cannot be modified by callers**:

| Setting | Value |
|---------|-------|
| Generator | `typescript-fetch` |
| `ensureUniqueParams` | `true` |
| `supportsES6` | `true` |
| `withInterfaces` | `true` |
| `importFileExtension` | `.js` |

These settings match the configuration in [kubev2v/migration-planner-ui](https://github.com/kubev2v/migration-planner-ui).

## Authorization Model

### How Authorization Works

The workflow includes a mandatory authorization check that validates the calling repository against an allowlist stored as a repository secret.

1. **Secret-based Allowlist**: The `ALLOWED_REPOS` secret contains a JSON array of authorized repository names
2. **Exact Match**: Uses `jq` for precise string matching (no partial matches)
3. **Fail-Fast**: Unauthorized requests are rejected before any generation occurs

### Configuring Authorization

Set the `ALLOWED_REPOS` secret in this repository with a JSON array:

```json
["kubev2v/migration-planner", "kubev2v/migration-planner-ui"]
```

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

# Create a .secrets file with test secrets
cat > .secrets << 'EOF'
NPM_TOKEN=fake-token-for-testing
ALLOWED_REPOS=["kubev2v/migration-planner-client-generator"]
EOF

# Run the test workflow
act push -W .github/workflows/test.yml
```

### .actrc Configuration

The repository includes a `.actrc` file with default settings:

```
-P ubuntu-latest=catthehacker/ubuntu:act-latest
--secret-file .secrets
```

## Repository Structure

```
.
├── .github/
│   └── workflows/
│       ├── generate-and-publish.yml   # Reusable workflow
│       └── test.yml                   # CI test workflow
├── .actrc                             # act-cli configuration
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
