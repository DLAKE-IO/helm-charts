# GitHub Actions Workflows - Quick Reference

## Active Workflows

### 🔍 CI Workflow (`ci.yaml`)
**Purpose:** Validate charts in pull requests

**Triggers:**
- Pull requests to `main` branch
- Manual dispatch

**What it does:**
1. Checks out code
2. Sets up Helm, Python, chart-testing
3. Adds dependency repositories (Bitnami)
4. Lists changed charts
5. Validates helm-docs are up to date
6. Lints changed charts
7. Creates kind cluster
8. Tests chart installation
9. Reports results in workflow summary

**When it runs:** Every PR to main
**Duration:** ~5-8 minutes (if charts changed)
**Fails if:** 
- Helm-docs outdated
- Linting errors
- Installation fails

---

### 🚀 Release Workflow (`release.yaml`)
**Purpose:** Publish charts to GitHub Pages and GHCR

**Triggers:**
- Push to `main` branch (when `charts/**` files change)
- Manual dispatch

**What it does:**
1. Checks out code
2. Sets up Helm
3. Adds dependency repositories (Bitnami)
4. Logs into GitHub Container Registry
5. Runs chart-releaser (publishes to GitHub Pages)
6. Installs cosign
7. Pushes charts to GHCR as OCI artifacts
8. Signs charts with cosign
9. Generates release summary

**When it runs:** After merge to main (if chart versions bumped)
**Duration:** ~3-5 minutes
**Publishes to:**
- GitHub Pages: `https://<owner>.github.io/helm-charts/`
- GHCR: `ghcr.io/<owner>/charts/<chart-name>`

---

## Key Tool Versions

| Tool | Version |
|------|---------|
| Helm | v3.15.2 |
| Python | 3.12 |
| chart-testing | v2.7.0 |
| helm-docs | v1.14.2 |
| kind-action | v1.12.0 |
| chart-releaser | v1.7.0 |

---

## Common Developer Tasks

### Before Creating a PR
```bash
# 1. Update chart documentation
helm-docs

# 2. Lint your changes locally
ct lint --config .github/configs/ct.yaml --lint-conf .github/configs/lintconf.yaml

# 3. Test installation (optional, requires kind)
ct install --config .github/configs/ct.yaml

# 4. Commit everything
git add .
git commit -m "feat: add new feature"
git push origin feature-branch
```

### Releasing a Chart
```bash
# 1. Bump version in Chart.yaml
# version: 1.0.0 → 1.0.1 (patch)
# version: 1.0.0 → 1.1.0 (minor)
# version: 1.0.0 → 2.0.0 (major)

# 2. Update appVersion if application version changed
# appVersion: "2.1.0" → "2.2.0"

# 3. Run helm-docs to update README
helm-docs

# 4. Commit and merge to main
git add charts/*/Chart.yaml charts/*/README.md
git commit -m "chore: bump chart version to 1.0.1"
git push origin main

# 5. Release workflow runs automatically
```

---

## Workflow Status Checks

### CI Workflow Checks
- ✅ Changed charts detected
- ✅ Helm-docs up to date
- ✅ Linting passed
- ✅ Installation test passed

### Release Workflow Checks
- ✅ Charts packaged
- ✅ Published to GitHub Pages
- ✅ Pushed to GHCR as OCI
- ✅ Signed with cosign

---

## Using Published Charts

### From GitHub Pages (Traditional)
```bash
helm repo add dlake https://dlake-io.github.io/helm-charts/
helm repo update
helm install my-release dlake/bookstack
```

### From GHCR (OCI)
```bash
helm install my-release oci://ghcr.io/dlake-io/charts/bookstack --version 1.0.0
```

### Verify Chart Signature
```bash
cosign verify ghcr.io/dlake-io/charts/bookstack:1.0.0
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| CI fails: "helm-docs out of date" | Run `helm-docs` locally and commit |
| Release doesn't trigger | Bump `version` in Chart.yaml |
| Installation test fails | Check chart dependencies in values.yaml |
| GHCR push fails | Check repository settings → Packages permissions |
| Lint errors | Run `ct lint --config .github/configs/ct.yaml --lint-conf .github/configs/lintconf.yaml` locally |

---

## Configuration Files

| File | Purpose |
|------|---------|
| `.github/configs/ct.yaml` | Chart testing configuration |
| `.github/configs/lintconf.yaml` | YAML linting rules |
| `.github/configs/cr.yaml` | Chart releaser configuration |

---

## Workflow Permissions

### CI Workflow
- `contents: read` (default)

### Release Workflow
- `contents: write` - Create releases and push to gh-pages
- `packages: write` - Push to GHCR
- `id-token: write` - Sign with cosign

---

## Best Practices

1. **Always run helm-docs** before committing chart changes
2. **Bump chart version** for every change (follow semver)
3. **Test locally** with `ct lint` before pushing
4. **Write clear commit messages** (they become release notes)
5. **Update appVersion** when upgrading application version
6. **Check workflow logs** if CI fails

---

## Getting Help

- **Workflow logs:** GitHub Actions tab in repository
- **Migration guide:** `.github/WORKFLOW_MIGRATION.md`
- **Chart testing docs:** https://github.com/helm/chart-testing
- **Helm docs:** https://helm.sh/docs/

---

## Quick Links

- [View Workflows](../../actions)
- [Migration Guide](.github/WORKFLOW_MIGRATION.md)
- [Chart Testing Config](.github/configs/ct.yaml)
- [Releases](../../releases)
- [Packages](../../packages)
