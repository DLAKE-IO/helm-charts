# Changelog

All notable changes to the dlake Helm Charts repository are documented here.

## [Unreleased]

### Added
- **wazuh** version `2.0.0`; new chart deploying Wazuh XDR/SIEM platform (manager, indexer, dashboard, agent DaemonSet); sourced from clyso-dr/wazuh-helm

### Fixed
- **bookstack** version bump `2.5.1` → `2.5.2`; set `valkey.architecture: standalone` to prevent the Bitnami Valkey subchart from defaulting to `replication` mode (which deploys an unneeded primary + 3-replica cluster)

### Added
- **bookstack** `valkey.auth.password` value; inline Valkey password passed to the Bitnami subchart

### Changed
- **bookstack** version bump `2.4.1` → `2.5.1`; when `valkey.auth.enabled: true`, `VALKEY_PASSWORD` is now injected via `secretKeyRef` from the referenced Secret and `REDIS_SERVERS` is composed as `host:port:db:$(VALKEY_PASSWORD)` — Kubernetes expands the variable at container start time, delivering the correct four-part connection string BookStack requires, without relying on Helm `lookup()`
- **bookstack** `valkey.auth.existingSecret` and `valkey.auth.existingSecretPasswordKey` values; `REDIS_PASSWORD` is now injected from the referenced Secret when `valkey.auth.enabled` is true
- **bookstack** `externalValkey.auth.existingSecret` and `externalValkey.auth.existingSecretPasswordKey` values for authenticated external Valkey/Redis
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
- **bookstack** version bump `2.4.0` → `2.4.1`; patch bump for CI/CD pipeline testing
- **bookstack** version bump `2.3.0` → `2.4.0`; authenticated Valkey support via `REDIS_PASSWORD` injected from a Kubernetes Secret
- **bookstack** version bump `2.2.1` → `2.3.0`; `SESSION_DRIVER` and `CACHE_DRIVER` automatically set to `redis` when Valkey is configured; `storage-framework-cache` and `storage-framework-sessions` emptyDir mounts are now chart-managed and omitted when Valkey is active; MariaDB subchart migrated to OCI registry (`oci://registry-1.docker.io/bitnamicharts`) and version bumped `20.x.x` → `23.x.x`
- **bookstack** version bump `2.2.0` → `2.2.1`; appVersion bumped `25.11` → `25.12`
- **bookstack** version bump `2.1.1` → `2.2.0`; hardened pod security (`readOnlyRootFilesystem: true`, `seccompProfile: RuntimeDefault`, `runAsGroup`); added `extraVolumeMounts`/`extraVolumes` Deployment support with seven emptyDir mounts for all runtime-writable paths
- **bookstack** version bump `2.1.0` → `2.1.1`
- **cryptgeon** version bump `2.9.0` → `2.10.0`; migrated from Bitnami Redis `20.x.x` (HTTPS repo) to Bitnami Valkey `5.x.x` (OCI registry); `redis.*` / `externalRedis.*` values renamed to `valkey.*` / `externalValkey.*` (**breaking**)
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

## wazuh

### [2.0.0] — 2026-04-17
- Initial chart: Wazuh 4.14.3 XDR/SIEM platform (manager master + workers, OpenSearch indexer, dashboard, agent DaemonSet)
- Sourced from [clyso-dr/wazuh-helm](https://github.com/clyso-dr/wazuh-helm), originally [morgoved/wazuh-helm](https://github.com/morgoved/wazuh-helm)
- cert-manager subchart dependency (condition: `cert-manager.enabled`)
- ARM architecture support via nodeSelector
- cert-manager integration for TLS certificate management

---

## bookstack

### [2.5.2] — 2026-03-06
- Fixed `valkey.architecture: standalone` not being set; the Bitnami Valkey subchart was defaulting to `replication` architecture and deploying a 4-pod cluster (1 primary + 3 replicas) instead of a single instance

### [2.5.1] — 2026-03-06
- Added `valkey.auth.password` value for inline Valkey password (passed to the Bitnami subchart; stored in the auto-generated `<release>-valkey` Secret)
- When `valkey.auth.enabled: true`, a `VALKEY_PASSWORD` env var is now injected via `secretKeyRef` from the referenced Secret (or the Bitnami auto-generated Secret), and `REDIS_SERVERS` is set to `host:port:db:$(VALKEY_PASSWORD)`. Kubernetes expands the variable at container start time, giving BookStack the full four-part connection string it requires
- Removed the Helm `lookup()`-based chart-managed Secret approach: that approach silently produced an empty password in GitOps environments (ArgoCD, Flux) and clusters with restricted Secret-read RBAC. The `$(VAR_NAME)` substitution mechanism is reliable in all environments
- Removed the incorrect standalone `REDIS_PASSWORD` env var from the bundled Valkey path (BookStack does not read this variable; the password must be the 4th field of `REDIS_SERVERS`)

### [2.4.1] — 2026-03-06
- Patch version bump for CI/CD pipeline testing

### [2.4.0] — 2026-03-06
- Added `valkey.auth.existingSecret` and `valkey.auth.existingSecretPasswordKey` values to the Valkey auth block
- Deployment now injects `REDIS_PASSWORD` from the referenced Kubernetes Secret when `valkey.auth.enabled: true`; falls back to the Bitnami auto-generated Secret (`<release>-valkey`, key: `valkey-password`) when no `existingSecret` is specified
- Added `externalValkey.auth.existingSecret` and `externalValkey.auth.existingSecretPasswordKey` for authenticated external Valkey/Redis connections

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

### [2.10.0] — 2026-03-06

**Breaking changes:**
- `redis.*` values key renamed to `valkey.*` — update your `values.yaml` overrides accordingly
- `externalRedis.*` values key renamed to `externalValkey.*`
- The Bitnami Redis subchart (`https://charts.bitnami.com/bitnami`, `20.x.x`) has been replaced by the Bitnami Valkey subchart (`oci://registry-1.docker.io/bitnamicharts`, `5.x.x`)
- Under the new `valkey` block, `master.persistence` is replaced by `primary.persistence` (Valkey primary/replica naming convention)

**Changes:**
- Migrated cache/store backend from Bitnami Redis to Bitnami Valkey (`oci://registry-1.docker.io/bitnamicharts/valkey ^5.x.x`)
- Added `externalValkey` values block for connecting to an existing Redis-compatible service when `valkey.enabled: false`
- Added `cryptgeon.valkey.fullname` template helper in `_helpers.tpl`
- Internal REDIS URI updated from `redis://<release>-redis-master` to `redis://<release>-valkey-primary`
- Updated `values.schema.json` to validate `valkey` and `externalValkey` keys

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
alidation (enforces `replicaCount: 1`)
- Added Artifact Hub annotations
- Added `ci/default-values.yaml` for install testing

### [1.6.1]
- Initial chart version tracked in this repository
.3.2]
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
alidation (enforces `replicaCount: 1`)
- Added Artifact Hub annotations
- Added `ci/default-values.yaml` for install testing

### [1.6.1]
- Initial chart version tracked in this repository
