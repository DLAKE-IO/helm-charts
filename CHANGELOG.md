# Changelog

All notable changes to the dlake Helm Charts repository are documented here.

## [Unreleased]

### Changed
- **wazuh** version bump `2.7.1` → `2.7.2`; bump all component image tags `4.14.4` → `4.14.5` (indexer, dashboard, manager, agent)

### Fixed
- **wazuh** version bump `2.7.0` → `2.7.1`; add `matchPattern: "*"` DNS proxy rule to both DNS egress entries (`kube-dns` and `coredns`) in the shared `wazuh.ciliumNetworkPolicy.dnsEgress` helper — without this rule Cilium's DNS proxy intercepts port-53 traffic but drops all FQDN responses (policy-mode `dnsProxy` rejects queries with no matching `rules.dns` entry); all four CNPs (master, worker, indexer, dashboard) inherit the fix

### Added
- **wazuh** version bump `2.6.0` → `2.7.0`; add `wazuh.emailNotification.*` values block; parameterize SMTP/email settings in `_ossec_conf.tpl` primary `<global>` block — fixes `wazuh-maild` not starting when email config was injected via `extraConf` second `<global>` (startup script reads first `<email_notification>` only; analysisd reads all blocks — split-brain caused `mail:true` in alerts with no emails delivered)
- **wazuh** version bump `2.5.2` → `2.6.0`; wire `wazuh.localRules` values key to the manager ConfigMap — operators can now inject custom rules via values instead of forking the chart; fixes broken stub that called a non-existent helper template

### Fixed
- **wazuh** version bump `2.5.1` → `2.5.2`; add `fix-permissions` initContainer (alpine:3, chown 999:999) and `fsGroupChangePolicy: OnRootMismatch` to master and worker StatefulSets; correct `fsGroup` from hardcoded `101` to `999` (actual wazuh GID in 4.x images) — fixes stale `root:root` ownership on PVC subPath dirs that caused `wazuh-db: ERROR: Couldn't create SQLite database 'queue/db/global.db'` after pod restarts; add helm template smoke test to CI for wazuh chart (previously excluded from `ct lint`)
- **wazuh** version bump `2.3.2` → `2.3.3`; fix master/worker NetworkPolicy and CiliumNetworkPolicy: when `wazuh.loadBalancer.enabled=true`, all four policies now allow all LB-exposed ports (TCP 1515, 55000, 1514, 514 + UDP 514) from the configured `sourceCIDRs` (or `fromEntities: cluster` / open rule when unset) — the LB Service selector targets both master and worker pods, so both must accept all LB ports to prevent random connection drops
- **wazuh** version bump `2.3.1` → `2.3.2`; fix worker CiliumNetworkPolicy: use `fromCIDR` when `loadBalancer.sourceCIDRs` is set, fall back to `fromEntities: [cluster]` otherwise (combining both is unsupported by Cilium)

### Changed
- **wazuh** version bump `2.3.0` → `2.3.1`; bump all component image tags `4.14.3` → `4.14.4`

### Fixed
- **wazuh** version bump `2.5.0` → `2.5.1`; inject webhook listener sidecar into worker pods (alongside master); add `webhook-https` port (443 → 8080) to `wazuh-manager-lb` when `webhookListener.enabled` so external clusters reach any manager pod through the existing LoadBalancer without a second LB; extend NP/CNP webhook ingress rules to worker

### Added
- **wazuh** version bump `2.4.1` → `2.5.0`; added `webhookListener.sourceCIDRs` (list of external K8s API server CIDRs — generates a `fromCIDR` CiliumNetworkPolicy ingress rule so external clusters can reach the webhook sidecar) and `webhookListener.service.loadBalancerSourceRanges` (restricts LB ingress when `type=LoadBalancer`); enables multi-cluster audit log collection with a single Wazuh deployment
- **wazuh** version bump `2.3.3` → `2.4.0`; added `webhookListener` component: a sidecar container injected into the wazuh-master pod that receives Kubernetes API server audit webhook events over HTTPS (port 8080) and forwards them to the Wazuh manager via the analysisd Unix socket at `/var/ossec/queue/sockets/queue`; gated behind `webhookListener.enabled: false`; includes `webhookListener` Service (port 443 → 8080), cert-manager Certificate CR with 4-SAN FQDN, optional audit policy reference ConfigMap, and webhook ingress rules automatically added to the master NetworkPolicy and CiliumNetworkPolicy when both `webhookListener.enabled` and the respective NP/CNP flags are true

### Fixed
- **wazuh** version bump `2.4.0` → `2.4.1`; replace Flask with Python stdlib `http.server` + `ssl` in the webhook listener script (Flask absent from Wazuh image, `ModuleNotFoundError` on start); add `PYTHONUNBUFFERED=1` env var to sidecar so `kubectl logs` shows output
- **wazuh** version bump `2.3.2` → `2.3.3`; fix master/worker NetworkPolicy and CiliumNetworkPolicy: when `wazuh.loadBalancer.enabled=true`, all four policies now allow all LB-exposed ports (TCP 1515, 55000, 1514, 514 + UDP 514) from the configured `sourceCIDRs` (or `fromEntities: cluster` / open rule when unset) — the LB Service selector targets both master and worker pods, so both must accept all LB ports to prevent random connection drops
- **wazuh** version bump `2.3.1` → `2.3.2`; fix worker CiliumNetworkPolicy: use `fromCIDR` when `loadBalancer.sourceCIDRs` is set, fall back to `fromEntities: [cluster]` otherwise (combining both is unsupported by Cilium)

### Changed
- **wazuh** version bump `2.3.0` → `2.3.1`; bump all component image tags `4.14.3` → `4.14.4`

### Added
- **wazuh** version bump `2.2.0` → `2.3.0`; added `wazuh.loadBalancer.sourceCIDRs` (default `["0.0.0.0/0"]`) for CIDR-scoped LB ingress enforcement — applied to `loadBalancerSourceRanges` on the LB Service, `ipBlock` rules in master/worker NetworkPolicy, and `fromCIDR` rules in master/worker CiliumNetworkPolicy; worker ingress is narrowed to configured CIDRs plus same-namespace pods when LB is enabled
- **wazuh** version bump `2.1.0` → `2.2.0`; added `CiliumNetworkPolicy` support for all four components (dashboard, indexer, manager-master, manager-worker); each component has an independent `ciliumNetworkPolicy.enabled` flag (default `false`, coexists with existing `networkPolicy`); DNS egress (UDP+TCP/53 to kube-dns and coredns) via shared `wazuh.ciliumNetworkPolicy.dnsEgress` named template; syslog ports (514 TCP/UDP) in worker CNP gated on `wazuh.syslog_enable`; CTI egress via `toEntities: ["world"]` in master and worker CNPs; `externalIndexer` guard added to existing NetworkPolicy templates (dashboard, master, worker)
- **wazuh** version bump `2.0.0` → `2.1.0`; ported upstream fixes from morgoved/wazuh-helm (5 commits evaluated through 2026-03-24, 4 applied — 1 already present in clyso-dr refactoring)
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

### [2.7.2] — 2026-05-28
- Changed: bump all component image tags `4.14.4` → `4.14.5`; bump `appVersion` to `4.14.5`

### [2.7.1] — 2026-05-28
- Fixed: add `matchPattern: "*"` DNS proxy rule to both `kube-dns` and `coredns` egress entries in the shared `wazuh.ciliumNetworkPolicy.dnsEgress` helper; without this rule Cilium's DNS proxy intercepts port-53 traffic but rejects all FQDN responses (no matching `rules.dns` policy entry), breaking DNS resolution for all four CNP-enabled components

### [2.7.0] — 2026-05-27
- Added: `wazuh.emailNotification.*` values block (`enabled`, `smtpServer`, `emailFrom`, `emailTo[]`, `maxPerHour`, `logSource`, `alertLevel`); replaced hardcoded SMTP lines in `_ossec_conf.tpl` `<global>` block with template values
- Fixed: `wazuh-maild` not starting when email config was supplied via `extraConf` second `<global>` block — `wazuh-control` startup script reads only the first `<email_notification>` tag; `analysisd` reads all blocks; the mismatch caused `mail:true` in `alerts.json` with zero emails delivered; setting values in the primary `<global>` block fixes both paths

### [2.6.0] — 2026-05-27
- Added: wire `wazuh.localRules` values key to manager ConfigMap (`configmap.yaml`); operators can now override `local_rules.xml` via values — set `wazuh.localRules` to any XML string to inject custom rules without forking the chart
- Fixed: `wazuh.localRules` default in `values.yaml` was a broken stub calling a non-existent helper template (`wazuh.localRules`); replaced with valid empty `<group>` XML

### [2.5.2] — 2026-04-27
- Fixed: add `fix-permissions` initContainer (alpine:3, `runAsUser: 0`) to master and worker StatefulSets; mounts full PVC at `/data`, runs `mkdir -p /data/wazuh && chown -R 999:999 /data/wazuh && chmod -R u+rwX,g+rwX /data/wazuh` before any Wazuh process starts — eliminates `wazuh-db: ERROR: Couldn't create SQLite database 'queue/db/global.db'` caused by kubelet creating subPath dirs as `root:root`
- Fixed: correct `fsGroup` in pod securityContext from hardcoded `101` to `wazuh.fixPermissions.gid` (default `999`); the previous value `101` did not match the actual wazuh process GID (999 in Wazuh 4.x images) and caused kubelet to apply the wrong group to mount points
- Fixed: add `fsGroupChangePolicy: OnRootMismatch` to master and worker pod securityContext (K8s 1.20+; suppress via `wazuh.master.fsGroupChangePolicy: ""` / `wazuh.worker.fsGroupChangePolicy: ""`); acts as belt-and-suspenders against ownership drift on new files
- Added: `wazuh.fixPermissions.{enabled,image,uid,gid}` values (defaults: `true`, `alpine:3`, `999`, `999`) — uid/gid control both the initContainer chown target and the pod securityContext fsGroup; verify with `kubectl exec wazuh-manager-master-0 -- id wazuh`
- Added: helm template smoke test in CI for wazuh chart (chart was previously excluded from `ct lint`; `helm template` now validates template renders correctly on every PR that touches wazuh)

### [2.5.1] — 2026-04-27
- Fixed: inject webhook listener sidecar into worker pods; add `webhook-https` port (443 → 8080) to `wazuh-manager-lb` when `webhookListener.enabled`; extend NP/CNP webhook ingress rules to cover worker pods — external clusters now hit any manager pod through the existing LoadBalancer

### [2.5.0] — 2026-04-27
- Added `webhookListener.sourceCIDRs`: list external K8s API server CIDRs to add a `fromCIDR` CiliumNetworkPolicy ingress rule — enables multi-cluster audit webhook collection
- Added `webhookListener.service.loadBalancerSourceRanges`: restrict LoadBalancer ingress to specified CIDRs when `webhookListener.service.type=LoadBalancer`

### [2.4.1] — 2026-04-27
- Fixed webhook listener sidecar: replaced Flask with Python stdlib `http.server` + `ssl` — Flask is absent from the Wazuh manager image, causing `ModuleNotFoundError` on start; zero external dependencies now required
- Fixed webhook listener sidecar: added `PYTHONUNBUFFERED=1` env var — without it Python buffers stdout and `kubectl logs` shows no output

### [2.4.0] — 2026-04-25
- Added `webhookListener` sidecar component: receives Kubernetes API server audit webhook events over HTTPS and forwards to the Wazuh manager via Unix socket; gated by `webhookListener.enabled: false`
- New values: `webhookListener.service.{port,containerPort,type,annotations}`, `webhookListener.tls.existingSecret`, `webhookListener.auditPolicy.enabled`, `webhookListener.{resources,livenessProbe,readinessProbe,extraEnvVars,podAnnotations}`
- New templates: `templates/webhook-listener/configmap-script.yaml`, `certificate.yaml`, `service.yaml`, `configmap-audit-policy.yaml`
- Modified: `templates/manager/master/statefulset.yaml` (sidecar + volumes); `templates/manager/master/networkpolicy.yaml` (webhook ingress when `webhookListener.enabled`); `templates/manager/master/ciliumnetworkpolicy.yaml` (webhook ingress from `host`/`remote-node` entities)

### [2.3.2] — 2026-04-23
- Fixed worker CiliumNetworkPolicy: mutually exclusive `fromCIDR` (when `loadBalancer.sourceCIDRs` is set) vs `fromEntities: [cluster]` (otherwise) — combining both is unsupported by Cilium

### [2.3.1] — 2026-04-23
- Bumped all component image tags from `4.14.3` to `4.14.4`

### [2.3.0] — 2026-04-23
- Added `wazuh.loadBalancer.sourceCIDRs` (default `["0.0.0.0/0"]`): CIDR list applied to `loadBalancerSourceRanges` on the LB Service, `ipBlock` ingress rules in master and worker NetworkPolicy, and `fromCIDR` ingress rules in master and worker CiliumNetworkPolicy; worker port ingress narrows to configured CIDRs plus same-namespace pods when LB is enabled

### [2.2.0] — 2026-04-23
- Added CiliumNetworkPolicy support for all four components (dashboard, indexer, manager-master, manager-worker) with independent `ciliumNetworkPolicy.enabled` flags

### [2.1.0] — 2026-04-17
- Applied upstream fixes from morgoved/wazuh-helm (commits c3ccd85 through 090a902b / wazuh-1.0.22)
- Added null-checks for `global.dualStack` in all 7 service.yaml files (prevents nil-pointer panic when `global.dualStack` is omitted from user values overrides)
- Added `apiVersion: v1` / `kind: PersistentVolumeClaim` to all 3 volumeClaimTemplates (fixes ArgoCD SSA perpetual diff)
- Added optional resource constraints to indexer init job (`indexer.job.resources`)
- Added NFS-backed snapshot storage for OpenSearch backups (`indexer.snapshot.*`) — new PVC, volume mount, and `path.repo` in opensearch.yml config
- Added `charts/wazuh/UPSTREAM.md` tracking fork lineage and sync log

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
