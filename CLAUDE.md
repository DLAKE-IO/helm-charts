# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a Helm charts repository that hosts multiple application charts. Charts are automatically published to GitHub Pages via chart-releaser when changes are merged to main.

## Available Charts

- **bookstack** - Self-hosted platform for organizing and storing information
- **cryptgeon** - Secure note sharing application with Redis backend
- **ocsinventory** - IT assets management and deployment solution with MariaDB backend
- **pingvin-share** - File sharing application (note: limited to 1 replica due to architecture)

## Development Commands

### Linting and Testing

```bash
# Lint charts (uses ct lint)
ct lint --config ./.github/configs/ct.yaml --lint-conf ./.github/configs/lintconf.yaml

# Install and test charts (requires kind cluster)
ct install --config ./.github/configs/ct.yaml

# List changed charts
ct --config ./.github/configs/ct.yaml list-changed
```

### Helm Operations

```bash
# Add required dependency repositories
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update dependencies for a chart
helm dependency update charts/<chart-name>

# Template a chart to preview manifests
helm template <release-name> charts/<chart-name> -f charts/<chart-name>/values.yaml

# Package a chart
helm package charts/<chart-name>
```

### Documentation

All charts use helm-docs for automatic README generation. After making changes to Chart.yaml or values.yaml:

```bash
# Generate/update README.md for charts
helm-docs
```

## Chart Structure

Each chart follows the standard Helm structure:
- `Chart.yaml` - Chart metadata (version, appVersion, dependencies, maintainers)
- `values.yaml` - Default configuration values
- `templates/` - Kubernetes manifest templates
- `requirements.yaml` - Legacy dependency specification (only in older charts like bookstack)

Charts may include external dependencies:
- **cryptgeon**: Bitnami Redis (17.x.x)
- **ocsinventory**: Bitnami MariaDB (20.x.x)
- **pingvin-share**: Bitnami Common (2.x.x)

## CI/CD Workflows

The repository uses GitHub Actions for automation:

- **lint-test.yaml** - Runs on PRs to lint and test changed charts
- **helm-test.yml** - Runs on push/PR to main branch for CI testing
- **release.yaml** - Automatically packages and publishes charts to GitHub Pages on main branch pushes

## Chart Testing Configuration

Chart testing is configured via `.github/configs/ct.yaml`:
- Target branch: `main`
- Chart directory: `charts/`
- Validates maintainers and YAML
- Excludes deprecated charts

## Chart Versioning

When modifying charts:
1. Increment `version` in Chart.yaml for chart changes
2. Update `appVersion` in Chart.yaml when upgrading the application version
3. Run `helm-docs` to regenerate the README with updated version badges

## Common Patterns

Charts in this repository commonly include:
- Ingress support with configurable annotations and className
- Persistent volume claims for stateful applications
- Security contexts with fsGroup and runAsUser/runAsNonRoot
- ServiceAccount creation with configurable annotations
- External database support (disable internal DB, provide external connection details)
- Health probes (liveness/readiness) where applicable
- Resource limits/requests (often left unspecified by default)

## Release Process

Charts are released automatically when merged to main:
1. chart-releaser packages changed charts
2. Creates GitHub releases with chart archives
3. Updates the Helm repository index on GitHub Pages

Users can add the repository with:
```bash
helm repo add dlake https://dlake-io.github.io/helm-charts/
```
