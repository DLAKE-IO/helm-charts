# GitHub Actions Workflows

This directory contains automated workflows for chart validation and publishing.

## Active Workflows

### 🔍 [ci.yaml](./ci.yaml)
**Validates charts in pull requests**

- Runs on: Pull requests to `main`
- Duration: ~5-8 minutes
- Checks: helm-docs, linting, installation tests

### 🚀 [release.yaml](./release.yaml)
**Publishes charts to GitHub Pages and GHCR**

- Runs on: Push to `main` (when charts change)
- Duration: ~3-5 minutes  
- Publishes to: GitHub Pages + GHCR (OCI)
- Security: Signs charts with cosign

## Documentation

📖 **[Quick Reference](../WORKFLOWS_QUICK_REFERENCE.md)** - Common commands and tasks  
📋 **[Migration Guide](../WORKFLOW_MIGRATION.md)** - Detailed migration information  
📊 **[Changes Summary](../WORKFLOW_CHANGES_SUMMARY.md)** - Visual comparison and improvements

## For Contributors

Before opening a PR:
```bash
helm-docs  # Update documentation
ct lint --config .github/configs/ct.yaml  # Lint locally
```

To release a chart:
```bash
# 1. Bump version in Chart.yaml
# 2. Run helm-docs
# 3. Commit and merge to main
```

## Deprecated Workflows

Old workflows have been moved to [`deprecated/`](./deprecated/) and can be safely deleted after testing the new workflows.

---

**Need help?** Check the [Quick Reference](../WORKFLOWS_QUICK_REFERENCE.md) or [Migration Guide](../WORKFLOW_MIGRATION.md).
