# =============================================================================
# Makefile for OpenAPI Client Generator
# =============================================================================
# Local testing with act-cli
# =============================================================================

.PHONY: help test test-verbose setup-secrets clean check-act

# Default target
help:
	@echo "OpenAPI Client Generator - Local Testing"
	@echo ""
	@echo "Usage:"
	@echo "  make setup-secrets  Create .secrets file template"
	@echo "  make test           Run test workflow with act-cli"
	@echo "  make test-verbose   Run test workflow with verbose output"
	@echo "  make clean          Remove generated artifacts"
	@echo "  make check-act      Verify act-cli is installed"
	@echo ""
	@echo "Variables:"
	@echo "  GITHUB_REPOSITORY   Override github.repository context (default: kubev2v/migration-planner-client-generator)"
	@echo ""
	@echo "Prerequisites:"
	@echo "  - act-cli: brew install act"
	@echo "  - Docker: must be running"

# -----------------------------------------------------------------------------
# Setup
# -----------------------------------------------------------------------------

# Create .secrets file template
setup-secrets:
	@if [ -f .secrets ]; then \
		echo "⚠️  .secrets file already exists. Remove it first to regenerate."; \
	else \
		echo "Creating .secrets file..."; \
		echo '# Secrets for local act-cli testing' > .secrets; \
		echo '# WARNING: Never commit this file!' >> .secrets; \
		echo '' >> .secrets; \
		echo '# npm token (use a fake value for dry-run testing)' >> .secrets; \
		echo 'NPM_TOKEN=fake-token-for-testing' >> .secrets; \
		echo '' >> .secrets; \
		echo '# Allowed repositories (JSON array)' >> .secrets; \
		echo '# Include this repo for local testing' >> .secrets; \
		echo 'ALLOWED_REPOS=["kubev2v/migration-planner-client-generator"]' >> .secrets; \
		echo "✅ Created .secrets file"; \
		echo ""; \
		echo "Edit .secrets if you need to customize the values."; \
	fi

# Check if act is installed
check-act:
	@which act > /dev/null 2>&1 || (echo "❌ act-cli is not installed. Run: brew install act" && exit 1)
	@echo "✅ act-cli is installed: $$(act --version)"

# -----------------------------------------------------------------------------
# Testing
# -----------------------------------------------------------------------------

# Default repository for mocking github.repository context
GITHUB_REPOSITORY ?= kubev2v/migration-planner-client-generator

# Common act flags for Docker-in-Docker support
ACT_FLAGS = --secret-file .secrets \
	--bind \
	--container-options "--privileged" \
	--container-daemon-socket /var/run/docker.sock \
	--var GITHUB_REPOSITORY=$(GITHUB_REPOSITORY) \
	-P ubuntu-latest=catthehacker/ubuntu:act-latest

# Run test workflow
test: check-act
	@if [ ! -f .secrets ]; then \
		echo "❌ .secrets file not found. Run: make setup-secrets"; \
		exit 1; \
	fi
	@echo "🧪 Running test workflow..."
	act push -W .github/workflows/test.yml $(ACT_FLAGS)

# Run test workflow with verbose output
test-verbose: check-act
	@if [ ! -f .secrets ]; then \
		echo "❌ .secrets file not found. Run: make setup-secrets"; \
		exit 1; \
	fi
	@echo "🧪 Running test workflow (verbose)..."
	act push -W .github/workflows/test.yml $(ACT_FLAGS) --verbose

# Run with specific container architecture (useful for Apple Silicon)
test-arm64: check-act
	@if [ ! -f .secrets ]; then \
		echo "❌ .secrets file not found. Run: make setup-secrets"; \
		exit 1; \
	fi
	@echo "🧪 Running test workflow (ARM64)..."
	act push -W .github/workflows/test.yml $(ACT_FLAGS) --container-architecture linux/arm64

# -----------------------------------------------------------------------------
# Cleanup
# -----------------------------------------------------------------------------

# Remove generated artifacts
clean:
	@echo "🧹 Cleaning up generated artifacts..."
	rm -rf generated-client/
	rm -rf .act/
	@echo "✅ Cleanup complete"

# Remove secrets file
clean-secrets:
	@echo "🧹 Removing .secrets file..."
	rm -f .secrets
	@echo "✅ Secrets file removed"

# Full cleanup (including secrets)
clean-all: clean clean-secrets
	@echo "✅ Full cleanup complete"
