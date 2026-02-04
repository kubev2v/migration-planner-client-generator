# AGENTS.md

Guidelines for AI agents working on this repository.

## Project Overview

This is a **GitOps repository** providing a reusable GitHub Actions workflow for generating and publishing OpenAPI clients to npm. It uses the `workflow_call` trigger pattern, allowing authorized external repositories to invoke it.

**Jira Issue:** [ECOPROJECT-3956](https://issues.redhat.com/browse/ECOPROJECT-3956)

## Architecture

```
.
├── .github/workflows/
│   ├── generate-and-publish.yml   # Main reusable workflow (workflow_call)
│   └── test.yml                   # CI test workflow
├── .actrc                         # act-cli configuration
├── .gitignore
├── LICENSE                        # Apache-2.0
├── Makefile                       # Local testing commands
└── README.md
```

### Key Components

1. **Reusable Workflow** (`.github/workflows/generate-and-publish.yml`)
   - Triggered via `workflow_call` from external repositories
   - Two jobs: `authorize` (security check) → `generate-and-publish`
   - Uses `openapi-generators/openapitools-generator-action@v1`

2. **Authorization Model**
   - Uses `jq` for exact-match validation against `ALLOWED_REPOS` secret
   - Secret contains JSON array: `["org/repo1", "org/repo2"]`
   - Fails fast before any generation occurs

## Critical Constraints

### Hardcoded Generator Settings (DO NOT MODIFY)

These settings are intentionally hardcoded and must match [kubev2v/migration-planner-ui/openapitools.json](https://raw.githubusercontent.com/kubev2v/migration-planner-ui/refs/heads/main/openapitools.json):

| Setting | Value | Reason |
|---------|-------|--------|
| `generator` | `typescript-fetch` | Standardized across organization |
| `ensureUniqueParams` | `true` | Required for API compatibility |
| `supportsES6` | `true` | Modern JavaScript support |
| `withInterfaces` | `true` | TypeScript interface generation |
| `importFileExtension` | `.js` | ESM module compatibility |

**Callers cannot override these settings.** This is by design to ensure consistent client generation.

### Workflow Inputs (Caller-Configurable)

| Input | Required | Description |
|-------|----------|-------------|
| `openapi-spec-url` | Yes | URL to OpenAPI spec file |
| `package-name` | Yes | npm package name (@scope/name) |
| `package-version` | Yes | Semver version to publish |
| `npm-registry` | No | Defaults to npmjs.org |
| `dry-run` | No | Skip publish (for testing) |

### Required Secrets

**In this repository:**
- `ALLOWED_REPOS` - JSON array of authorized repository names
- `NPM_TOKEN` - npm access token

**In calling repositories:**
- `NPM_TOKEN` - npm token with publish permissions
- `ALLOWED_REPOS` - Must be passed through to the reusable workflow

## Local Development

### Testing with act-cli

```bash
# Setup (first time)
make setup-secrets

# Run tests
make test

# Verbose output for debugging
make test-verbose

# Cleanup generated files
make clean
```

### Prerequisites

- [act-cli](https://github.com/nektos/act): `brew install act`
- Docker must be running

## Code Style Guidelines

### GitHub Actions Workflows

- Use descriptive step names with emoji prefixes (📥, 🔨, 🚀, ✅)
- Group related steps with comment headers using `# ---` separators
- Always validate inputs/secrets before using them
- Use `>-` for multi-line strings without trailing newlines
- Format `--additional-properties` as comma-separated key=value pairs (no spaces)

### Shell Scripts in Workflows

- Use `set -e` behavior (fail on errors)
- Validate environment variables exist before use
- Use `jq` for JSON processing (pre-installed on ubuntu-latest)
- Output to `$GITHUB_STEP_SUMMARY` for job summaries

## Security Considerations

1. **Never expose the ALLOWED_REPOS list** - Error messages should not reveal authorized repos
2. **Use exact string matching** - `jq index()` prevents partial name attacks
3. **Validate JSON before parsing** - Use `jq empty` to verify format
4. **Secrets are masked** - GitHub automatically masks secret values in logs

## Related Repositories

| Repository | Relationship |
|------------|--------------|
| [kubev2v/migration-planner](https://github.com/kubev2v/migration-planner) | Backend API, triggers client generation |
| [kubev2v/migration-planner-ui](https://github.com/kubev2v/migration-planner-ui) | Consumes generated `@migration-planner-ui/api-client` |

## Common Tasks

### Adding a New Authorized Repository

1. Update the `ALLOWED_REPOS` secret in GitHub Settings
2. Add the repo to the JSON array: `["existing/repo", "new/repo"]`
3. No code changes required

### Updating Generator Settings

**Warning:** Changes affect all consumers. Coordinate with dependent repositories.

1. Update `command-args` in `.github/workflows/generate-and-publish.yml`
2. Update the reference table in this file and README.md
3. Test with `make test` before committing
4. Notify teams using this workflow

### Debugging Authorization Failures

1. Check `ALLOWED_REPOS` secret is valid JSON
2. Verify exact repository name match (case-sensitive)
3. Ensure calling workflow passes `ALLOWED_REPOS` secret through
