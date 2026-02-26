# dlake Helm Charts

A curated collection of Helm charts for self-hosted applications, automatically published to [GitHub Pages](https://dlake-io.github.io/helm-charts/) and [GitHub Container Registry](https://ghcr.io/dlake-io).

## Usage

```bash
helm repo add dlake https://dlake-io.github.io/helm-charts/
helm repo update
```

Charts are also available via OCI:

```bash
helm pull oci://ghcr.io/dlake-io/charts/<chart-name> --version <version>
```

## Available Charts

<!-- BEGIN_CHARTS_TABLE -->
| Chart | Version | App Version | Description |
|-------|---------|-------------|-------------|
| [bookstack](charts/bookstack/) | 2.1.1 | 25.11 | BookStack is a simple, self-hosted, easy-to-use platform for organising and storing information. |
| [cryptgeon](charts/cryptgeon/) | 2.9.0 | 2.8.2 | A Helm chart to install cryptgeon |
| [ocsinventory](charts/ocsinventory/) | 1.3.3 | 2.12.3 | Open Computers and Software Inventory Next Generation is an assets management and deployment solution. |
| [pingvin-share](charts/pingvin-share/) | 1.6.2 | v1.6.1 | A Helm chart to install Pingvin Share |
<!-- END_CHARTS_TABLE -->

> The table above is automatically updated on every release by `scripts/update-readme.py`.

---

## Chart Documentation

### bookstack

![Version: 2.1.1](https://img.shields.io/badge/Version-2.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 25.11](https://img.shields.io/badge/AppVersion-25.11-informational?style=flat-square)

BookStack is a simple, self-hosted, easy-to-use platform for organising and storing information.

See [charts/bookstack/README.md](charts/bookstack/README.md) for full documentation.

---

### cryptgeon

![Version: 2.9.0](https://img.shields.io/badge/Version-2.9.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.8.2](https://img.shields.io/badge/AppVersion-2.8.2-informational?style=flat-square)

A Helm chart to install cryptgeon — a secure, encrypted note and file sharing service.

See [charts/cryptgeon/README.md](charts/cryptgeon/README.md) for full documentation.

---

### ocsinventory

![Version: 1.3.3](https://img.shields.io/badge/Version-1.3.3-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.12.3](https://img.shields.io/badge/AppVersion-2.12.3-informational?style=flat-square)

Open Computers and Software Inventory Next Generation is an assets management and deployment solution.

See [charts/ocsinventory/README.md](charts/ocsinventory/README.md) for full documentation.

---

### pingvin-share

![Version: 1.6.2](https://img.shields.io/badge/Version-1.6.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v1.6.1](https://img.shields.io/badge/AppVersion-v1.6.1-informational?style=flat-square)

A self-hosted file sharing platform.

> **Note:** Currently limited to 1 replica due to SQLite architecture.

See [charts/pingvin-share/README.md](charts/pingvin-share/README.md) for full documentation.

---

## Contributing

1. Fork the repository
2. Create a feature branch
3. Modify the chart and bump `version` in `Chart.yaml`
4. Run `helm-docs` to regenerate documentation
5. Open a pull request — CI will lint, test, and verify docs automatically

## Security

All released charts are signed with [cosign](https://github.com/sigstore/cosign). Verify a chart with:

```bash
cosign verify ghcr.io/dlake-io/charts/<chart-name>:<version> \
  --certificate-identity-regexp="https://github.com/dlake-io/helm-charts" \
  --certificate-oidc-issuer="https://token.actions.githubusercontent.com"
```
