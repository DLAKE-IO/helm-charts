# Changelog

All notable changes to the dlake Helm Charts repository are documented here.

## [Unreleased]

### Added
- **bookstack** Valkey subchart dependency (`oci://registry-1.docker.io/bitnamicharts/valkey ^5.4.3`) for centralized PHP session and cache storage; enables horizontal scaling with multiple replicas
- **bookstack** `externalValkey` values block for connecting to an existing Redis-compatible service instead of the bundled subchart
- **bookstack** `bookstack.valkey.fullname`, `bookstack.redisServers`, and `bookstack.redis.enabled` template helpers in `_helpers.tpl`
- **bookstack** NetworkPolicy egress rule for Valkey port 6379 when `valkey.enabled`
- `values.schema.json` for all four charts (bookstack, cryptgeon, ocsinventory, pingvin-share)
- `ci/` test values directories for all charts — enables reliable `ct install` testing
- `README.md.gotmpl` templates for bookstack, cryptgeon, and ocsinventory
- `scripts/update-readme.py` — auto-updates root README charts table on release
- Artifact Hub annotations (`artifacthub.io/category`, `artifacthub.io/prerelease`) in all `Chart.yaml` files
- Maintainers block in `cryptgeon` and `pingvin-share` Chart.yaml
- helm-docs binary caching in CI workflow (faster PR validation)
- `restartPolicy: Never` on ocsinventory Helm test pod

### Changed
- **bookstack** version bump `2.2.1` → `2.3.0`; `SESSION_DRIVER` and `CACHE_DRIVER` automatically set to `redis` when Valkey is configured; `storage-framework-cache` and `storage-framework-sessions` emptyDir mounts are now chart-managed and omitted when Valkey is active; MariaDB subchart migrated to OCI registry (`oci://registry-1.docker.io/bitnamicharts`) and version bumped `20.x.x` → `23.x.x`
- **bookstack** version bump `2.2.0` → `2.2.1`; appVersion bumped `25.11` → `25.12`
- **bookstack** version bump `2.1.1` → `2.2.0`; hardened pod security (`readOnlyRootFilesystem: true`, `seccompProfile: RuntimeDefault`, `runAsGroup`); added `extraVolumeMounts`/`extraVolumes` Deployment support with seven emptyDir mounts for all runtime-writable paths
- **bookstack** version bump `2.1.0` → `2.1.1`
- **cryptgeon** version bump `2.8.2` → `2.9.0`; Redis subchart upgraded `17.x.x` → `20.x.x`
- **ocsinventory** version bump `1.3.2` → `1.3.3`; `image.tag` fixed to `""` (was `"2.12.1"` mismatched with appVersion `2.12.3`); metrics exporter updated from `debian-11` to `debian-12`
- **pingvin-share** version bump `1.6.1` → `1.6.2`
- `validate-chart-schema` enabled in `ct.yaml` (was disabled)
- Git identity in release workflow changed to `github-actions[bot]` (was `helm-bot`)
- GHCR push/sign steps refactored — digest captured from initial push, eliminating duplicate push
- Busybox image in cryptgeon and pingvin-share test pods pinned to `busybox:1.37.0`
- curlimages/curl in ocsinventory test pod pinned to `curlimages/curl:8.11.0`
- Root `README.md` restructured with proper intro, navigation, and auto-update markers
- `dependabot.yml` updated with action grouping and Renovate recommendation for Helm deps

### Removed
- Deprecated workflows directory `.github/workflows/deprecated/`
- `CHANGELOG.md` placeholder (replaced with this file)

---

## bookstack

### [2.3.0] — 2026-03-05
- Added Valkey subchart dependency (`oci://registry-1.docker.io/bitnamicharts/valkey ^5.x.x`) for centralized PHP session and cache storage
- Added `externalValkey` values block for using an existing Redis-compatible service
- `SESSION_DRIVER` and `CACHE_DRIVER` automatically set to `redis` when `valkey.enabled` or `externalValkey.host` is configured
- `storage-framework-cache` and `storage-framework-sessions` emptyDir mounts are now chart-managed; omitted from the pod spec when Valkey (or externalValkey) is active
- Added `bookstack.valkey.fullname`, `bookstack.redisServers`, and `bookstack.redis.enabled` template helpers
- Added NetworkPolicy egress rule for Valkey port 6379
- Migrated MariaDB subchart from Bitnami Helm repository to OCI registry (`oci://registry-1.docker.io/bitnamicharts`); version bumped `20.x.x` → `23.x.x`

### [2.2.1] — 2026-03-05
- Bumped appVersion `25.11` → `25.12`

### [2.2.0] — 2026-03-05
- Enabled `readOnlyRootFilesystem: true` on the BookStack container
- Added `runAsGroup: 33` and `seccompProfile: RuntimeDefault` to both pod and container security contexts
- Added `extraVolumeMounts` and `extraVolumes` support to the Deployment template
- Mounted seven `emptyDir` volumes for all runtime-writable paths: `/tmp`, `/run`, `bootstrap/cache`, `storage/logs`, `storage/framework/cache`, `storage/framework/sessions`, `storage/framework/views`

### [2.1.1] — 2026-02-26
- Added `values.schema.json` for values validation
- Added Artifact Hub annotations
- Added `ci/mariadb-values.yaml` for install testing
- Added `README.md.gotmpl` template

### [2.1.0] — 2026-02
- Added OIDC authentication support (full configuration with group sync, avatar fetching, RP-initiated logout)
- Added commented OIDC configuration examples in values.yaml

### [2.0.x]
- Added existingSecret support for APP_KEY and database credentials
- Added TLS certificate support for external database connections
- Added LDAP authentication support
- Added NetworkPolicy support
- Added PodDisruptionBudget support
- Added startup probe

---

## cryptgeon

### [2.9.0] — 2026-02-26
- Added maintainers block
- Upgraded Redis subchart from `17.x.x` to `20.x.x`
- Added `values.schema.json` for values validation
- Added Artifact Hub annotations
- Added `ci/default-values.yaml` for install testing
- Added `README.md.gotmpl` with TL;DR and installation sections

### [2.8.2]
- Initial chart version tracked in this repository

---

## ocsinventory

### [1.3.3] — 2026-02-26
- Fixed `image.tag` — changed from hardcoded `"2.12.1"` to `""` (uses appVersion `2.12.3`)
- Updated metrics exporter image from `debian-11` to `debian-12`
- Added `values.schema.json` for values validation
- Added Artifact Hub annotations
- Added `ci/mariadb-values.yaml` for install testing
- Added `README.md.gotmpl` with TL;DR and database note

### [1.3.2]
- MariaDB dependency via OCI registry

### [1.3.x]
- Added Prometheus ServiceMonitor support for Apache exporter
- Added basic auth support for ingress paths

---

## pingvin-share

### [1.6.2] — 2026-02-26
- Added maintainers block
- Added `values.schema.json` for values validation (enforces `replicaCount: 1`)
- Added Artifact Hub annotations
- Added `ci/default-values.yaml` for install testing

### [1.6.1]
- Initial chart version tracked in this repository
