# GitHub Actions Workflow Migration Guide

## Overview

The GitHub Actions workflows have been consolidated and modernized to improve reliability, security, and maintainability.

## Changes Summary

### Before (4 workflows)
- `lint-test.yaml` - PR linting and testing
- `helm-test.yml` - CI testing on main
- `release.yaml` - Simple chart release
- `publish.yml` - Advanced publishing with signing

### After (2 workflows)
- `ci.yaml` - Comprehensive PR validation
- `release.yaml` - Complete chart release and publishing

## What Changed

### 1. CI Workflow (`ci.yaml`)

**Improvements:**
- ✅ Fixed deprecated `::set-output` syntax (now uses `$GITHUB_OUTPUT`)
- ✅ Updated to latest tool versions:
  - Helm: v3.8.1 → v3.15.2
  - Python: 3.7 (EOL) → 3.12
  - chart-testing: v3.5.1 → v2.7.0
- ✅ Added missing Bitnami dependency repository
- ✅ Fixed config file paths (`.github/configs/ct.yaml`)
- ✅ Added helm-docs validation to catch outdated documentation
- ✅ Added workflow summaries for better visibility
- ✅ Only runs when charts actually change (more efficient)

**Behavior:**
- Triggers on pull requests to `main` branch
- Lists changed charts
- Verifies helm-docs are up to date (fails if not)
- Lints changed charts with yamllint
- Tests installation in kind cluster
- Provides summary of validated charts

### 2. Release Workflow (`release.yaml`)

**Improvements:**
- ✅ Fixed broken GHCR login (was `${ GITHUB_REPOSITORY_OWNER }`, now `${{ github.repository_owner }}`)
- ✅ Removed recursive trigger risk (no more commits to main)
- ✅ Added missing Bitnami dependency repository
- ✅ Better error handling for OCI push operations
- ✅ Removed unused tools (oras)
- ✅ Fixed helm-docs usage (validation moved to CI)
- ✅ Added comprehensive release summaries
- ✅ Only triggers on actual chart changes
- ✅ Consolidated GitHub Pages and OCI publishing

**Behavior:**
- Triggers on push to `main` when charts change
- Adds dependency repositories
- Releases to GitHub Pages (traditional Helm repo)
- Publishes to GHCR as OCI artifacts
- Signs charts with cosign
- Generates detailed release summary

## What Was Removed

### Removed from Publishing Workflow:
- ❌ Auto-committing helm-docs changes (should be done in PR)
- ❌ `helm-docs --dry-run > README.md` (was overwriting root README)
- ❌ Unused oras installation
- ❌ Recursive workflow triggers

### Deprecated Workflows:
Old workflows moved to `.github/workflows/deprecated/`:
- `lint-test.yaml`
- `helm-test.yml`
- `publish.yml`

## Migration Checklist

### For Repository Maintainers:

- [ ] Review the new workflows in `.github/workflows/`
- [ ] Test the CI workflow by opening a test PR
- [ ] Verify branch protection rules still apply
- [ ] Update any documentation referencing old workflow names
- [ ] Delete `.github/workflows/deprecated/` after confirming new workflows work

### For Contributors:

- [ ] Run `helm-docs` before committing chart changes
- [ ] Ensure chart documentation is up to date before opening PR
- [ ] Bump chart version in `Chart.yaml` for releases
- [ ] Check GitHub Actions tab for workflow results

## Testing the New Workflows

### Test CI Workflow:
```bash
# Create a test branch
git checkout -b test/workflow-validation

# Make a small change to a chart
echo "# Test" >> charts/bookstack/Chart.yaml

# Commit and push
git add charts/bookstack/Chart.yaml
git commit -m "test: validate CI workflow"
git push origin test/workflow-validation

# Open a PR and watch the CI workflow run
```

### Test Release Workflow:
```bash
# On main branch, bump a chart version
# Edit charts/bookstack/Chart.yaml and increment version

# Commit and push
git add charts/bookstack/Chart.yaml
git commit -m "chore: bump bookstack chart version"
git push origin main

# Watch the release workflow publish the chart
```

## New Workflow Features

### 1. Helm-docs Validation in CI
Charts must have up-to-date documentation. The CI workflow will fail if:
- `helm-docs` generates changes not yet committed
- Chart READMEs are missing required sections

**Fix:** Run `helm-docs` locally and commit changes before opening PR.

### 2. Workflow Summaries
Both workflows now provide GitHub Actions summaries showing:
- Which charts were validated/released
- Distribution channels (GitHub Pages, GHCR)
- Security information (cosign signing)

### 3. Path-Based Triggering
Release workflow only runs when files in `charts/**` change, reducing unnecessary runs.

### 4. Better Error Messages
Failed steps now show clear error messages and suggestions for fixes.

## Security Improvements

1. **No Direct Commits to Main**: Removed auto-commit behavior that bypassed branch protection
2. **Consistent Bot Identity**: All workflows use `helm-bot` for git operations
3. **Chart Signing**: All OCI artifacts are signed with cosign
4. **Minimal Permissions**: Workflows use least-privilege permission model
5. **Fixed Credential Handling**: Corrected GHCR login syntax

## Performance Improvements

1. **Conditional Execution**: Steps only run when charts actually change
2. **Parallel Operations**: Independent steps run concurrently where possible
3. **Removed Redundancy**: Eliminated duplicate linting and testing
4. **Latest Tools**: Updated versions bring performance improvements

## Troubleshooting

### CI Workflow Fails on "Verify helm-docs are up to date"
**Cause:** Chart documentation is outdated.
**Fix:**
```bash
helm-docs
git add charts/*/README.md
git commit -m "docs: update chart documentation"
```

### Release Workflow Doesn't Trigger
**Cause:** No chart version bumps detected.
**Fix:** Increment `version` in `Chart.yaml`:
```yaml
version: 1.2.3  # Bump this number
```

### GHCR Push Fails
**Cause:** Authentication or permission issues.
**Fix:** Ensure `packages: write` permission is set in workflow.

### Chart Installation Test Fails
**Cause:** Chart dependencies not available or misconfigured.
**Fix:** Ensure all dependency repos are added in `Add dependency chart repos` step.

## Rollback Plan

If issues arise, you can temporarily restore old workflows:

```bash
# Restore old workflows
cp .github/workflows/deprecated/*.yaml .github/workflows/
cp .github/workflows/deprecated/*.yml .github/workflows/

# Remove new workflows
rm .github/workflows/ci.yaml
rm .github/workflows/release.yaml

# Commit and push
git add .github/workflows/
git commit -m "revert: restore old workflows"
git push origin main
```

## Benefits Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Workflows** | 4 (overlapping) | 2 (clear separation) |
| **Python Version** | 3.7 (EOL) | 3.12 (current) |
| **Helm Version** | 3.8.1 | 3.15.2 |
| **Deprecated Syntax** | Yes (`::set-output`) | No (modern syntax) |
| **Doc Validation** | No | Yes |
| **Workflow Summaries** | No | Yes |
| **Security** | Unsigned charts | Cosign-signed charts |
| **Efficiency** | Always runs | Conditional execution |
| **Error Handling** | Basic | Comprehensive |

## Questions or Issues?

If you encounter any problems with the new workflows:

1. Check the workflow run logs in GitHub Actions
2. Review this migration guide
3. Check the troubleshooting section
4. Open an issue with workflow logs attached

## Related Documentation

- [Helm Chart Testing Guide](https://github.com/helm/chart-testing)
- [Chart Releaser Action](https://github.com/helm/chart-releaser-action)
- [Cosign Documentation](https://docs.sigstore.dev/cosign/overview/)
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
