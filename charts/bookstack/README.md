# bookstack

![Version: 2.8.0](https://img.shields.io/badge/Version-2.8.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 26.9](https://img.shields.io/badge/AppVersion-26.9-informational?style=flat-square)

BookStack is a simple, self-hosted, easy-to-use platform for organising and storing information.

**Homepage:** <https://www.bookstackapp.com/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Tristan | <5606292+drustan@users.noreply.github.com> |  |
## Source Code

* <https://github.com/BookStackApp/BookStack>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://registry-1.docker.io/bitnamicharts | mariadb | 23.x.x |
| oci://registry-1.docker.io/bitnamicharts | valkey | 5.x.x |

## Networking: Ingress or Gateway API

This chart exposes the app through either a Kubernetes `Ingress` (default) or a
Gateway API `HTTPRoute`. They toggle independently via `ingress.enabled` and
`httpRoute.enabled`.

Gateway API support creates only an `HTTPRoute` (`gateway.networking.k8s.io/v1`)
that attaches to a **pre-existing** Gateway via `httpRoute.parentRefs`; the chart
does not create the Gateway. TLS is terminated at the Gateway listener, so
`httpRoute` has no TLS block. Prerequisites:

- Gateway API CRDs installed in the cluster.
- A Gateway owned by the cluster admin (e.g. `gatewayClassName: cilium` for
  Cilium 1.15+), whose listener `allowedRoutes.namespaces` permits the release
  namespace.

`httpRoute.httpsRedirect` (on by default) additionally creates a second HTTPRoute
`<release>-http-redirect` on the Gateway's HTTP (`:80`) listener that redirects to
HTTPS with a `RequestRedirect` filter (status 301). Name the HTTP listener via
`httpsRedirect.sectionName` and pin the app route's HTTPS listener via
`parentRefs[].sectionName` — the two must differ or the chart refuses to render
(a shared listener would loop). If no HTTP listener is named, the redirect is
skipped (with a warning). Set `httpsRedirect.enabled: false` to turn it off.

> **Warning — `networkPolicy.enabled` + `httpRoute.enabled`:** the chart's
> NetworkPolicy restricts pod ingress to the configured pod/namespace selectors.
> Cilium delivers Gateway API traffic through its Envoy proxy (the special
> `ingress` entity), which plain NetworkPolicy selectors cannot match — so
> Gateway-routed requests may be **silently dropped**. Use a
> CiliumNetworkPolicy with `fromEntities: [ingress]` instead, or disable
> `networkPolicy` when routing through the Gateway.

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
      sectionName: https        # app traffic: HTTPS listener
  hostnames:
    - bookstack.example.local
  httpsRedirect:
    enabled: true
    sectionName: http           # HTTP (:80) listener -> 301 to HTTPS
```

## BookStack hacks

[BookStack hacks](https://www.bookstackapp.com/hacks/) are enabled through the
`hacks` value, with no template changes per hack. Each `hacks` entry becomes a
[theme system module](https://www.bookstackapp.com/hacks/applying/#theme-system-modules).
Modules require BookStack v26.03+; the chart default is v26.09.

- Files are rendered into ConfigMap `<fullname>-hacks` and mounted read-only at
  `/var/www/bookstack/themes/helm-hacks/modules/<name>/`. `bookstack-module.json`
  is generated from the entry name, `description` and a content hash; do not
  supply it in `files`.
- The chart sets `APP_THEME=helm-hacks`; do not also set `APP_THEME` via
  `env`/`extraEnv`, or mount your own theme alongside `hacks`.
- Changing hack files rolls the Deployment (`checksum/hacks` pod annotation).
- Disable a hack with `enabled: false`; remove it by deleting the entry.
- Hacks are unsupported upstream customizations: re-test them after BookStack
  upgrades. If `image.tag` is pinned below v26.03, modules are mounted but ignored.
- The total ConfigMap size limit is 1 MiB. For larger modules use
  [`modules`](#external-modules).

Map each code block on the hack page to a `files` key:

|Hack page code block|`files` key|
|---|---|
|Head HTML (`head.html`)|`head/<any-name>.html`|
|Logical Theme System (`functions.php`)|`functions.php`|
|Visual Theme System (`<path>`)|`views/<path>`|
|`lang/…`, `icons/…`, `public/…`|same path|

Example: [WYSIWYG Docx Import](https://www.bookstackapp.com/hacks/wysiwyg-docx-import/)
(drag and drop `.docx` files into the WYSIWYG page editor):

```yaml
hacks:
  wysiwyg-docx-import:
    description: Import .docx files into the WYSIWYG editor via drag and drop (bookstackapp.com/hacks)
    files:
      head/content.html: |
        <script src="https://cdn.jsdelivr.net/npm/mammoth@1.13.0/mammoth.browser.min.js"
                integrity="sha256-kpFKNwjP3x5iy1U9GFan/tqyHag9jugoRd4viXs2jKs="
                crossorigin="anonymous"
                defer></script>

        <script type="module">
            // Convert the given "file" instance to HTML, providing it back via the given callback
            function convertAndInsertDocx(file, callback) {
                // Use a FileReader to handle conversion via an ArrayBuffer
                const reader = new FileReader();
                reader.onload = async function(loadEvent) {
                    // Get and convert the ArrayBuffer version of the file
                    const arrayBuffer = loadEvent.target.result;
                    const {value: html, messages} = await window.mammoth.convertToHtml({arrayBuffer});
                    // If warnings exist from conversion, log them to the browser console then
                    // show a warning alert via BookStack's event system.
                    if (messages.length > 0) {
                        console.error(messages);
                        window.$events.emit('warning', `${messages.length} warnings logged to browser console during conversion`);
                    }
                    // Once we have our converted HTML, provide it to the callback function
                    callback(html);
                }
                reader.readAsArrayBuffer(file);
            }

            // For each of the files in the drop event, pass them, alongside the editor instance
            // to our "convertAndInsertDocx" function above before providing the results to the given callback.
            function runCallbackForEachDocFileInEvent(event, callback) {
                const files = event?.dataTransfer?.files || [];
                let handledDocxFiles = false;
                for (const file of files) {
                    if (file.type === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' && window.mammoth) {
                        convertAndInsertDocx(file, html => callback(html));
                        handledDocxFiles = true;
                    }
                }
                return handledDocxFiles;
            }

            // Listen to BookStack emitted WYSIWYG (TinyMCE) editor setup event
            window.addEventListener('editor-tinymce::setup', event => {
                // Get a reference to the editor and listen to file "drop" events
                const editor = event.detail.editor;
                editor.on('drop', event => {
                    // For any docx files, insert the resulting HTML content into the editor
                    runCallbackForEachDocFileInEvent(event, html => editor.insertContent(html));
                });
            });

            // Listen to BookStack emitted new-WYSIWYG editor setup event
            window.addEventListener('editor-wysiwyg::post-init', event => {
                const {usage, api} = event.detail;
                // Check that it's the page editor which is being loaded
                if (usage !== 'page-editor') {
                    return;
                }

                // Add a custom drop listener for the editor area
                const editorArea = document.querySelector('.editor-content-area');
                if (!editorArea) {
                    return;
                }

                editorArea.addEventListener('drop', event => {
                    const htmlWasInserted = runCallbackForEachDocFileInEvent(event, html => api.content.insertHtml(html));
                    if (htmlWasInserted) {
                        event.preventDefault();
                        event.stopPropagation();
                    }
                });
            });
        </script>
```

## External modules

Released theme modules that are too large for the `hacks` ConfigMap are
installed from their ZIP URL through the `modules` value. An init container
(`install-modules`, same image as BookStack) downloads each ZIP with `curl`,
verifies its SHA-256, extracts it into an `emptyDir` and the module is mounted
read-only at `/var/www/bookstack/themes/helm-hacks/modules/<name>/`, next to the
hacks. The ZIP may hold `bookstack-module.json` at its root or inside a single
top-level folder; the size limit is 50 MB (same as BookStack).

Example: [File Attachment Preview](https://github.com/pronomix-gmbh/bookstack_file_attachment_preview)
(in-browser preview of file attachments):

```yaml
modules:
  file-attachment-preview:
    url: https://github.com/pronomix-gmbh/bookstack_file_attachment_preview/releases/download/v1.3.0/file-attachment-preview.zip
    sha256: de0a97f1767f6082a059b597d1d4bd61c7dbb0df817e2fc0eb79161fa566a284
```

- `url` and `sha256` are required. Get the checksum from the release asset's
  `digest` field in the GitHub API
  (`https://api.github.com/repos/<owner>/<repo>/releases/tags/<tag>`), or with
  `curl -sL <url> | sha256sum`. A mismatch keeps the pod in
  `Init:Error`/`Init:CrashLoopBackOff`; see
  `kubectl logs <pod> -c install-modules`.
- Modules run arbitrary PHP inside BookStack; only install modules you trust.
- The ZIP is downloaded on every pod start, so the pod needs HTTPS egress to the
  download host, including GitHub's redirect targets
  (`release-assets.githubusercontent.com` / `objects.githubusercontent.com`).
  With `networkPolicy.enabled: true` add an egress rule, for example:

  ```yaml
  networkPolicy:
    egress:
      extraRules:
        - to:
            - ipBlock:
                cidr: 0.0.0.0/0
          ports:
            - protocol: TCP
              port: 443
  ```

- Air-gapped or proxied clusters: point `url` at an internal HTTP(S) mirror;
  the init container does not receive `extraEnv` (no proxy variables).
- Module names must not collide with `hacks` keys (rendering fails). The chart
  sets `APP_THEME=helm-hacks` when either `hacks` or `modules` is used.
- Changing a module entry rolls the Deployment (the init container arguments
  change). Disable a module with `enabled: false`.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod assignment |
| app.existingSecret | string | `""` | Name of existing secret containing APP_KEY (key: app-key) If set, app.key is ignored |
| app.key | string | "" (must be provided) | Laravel APP_KEY (required). Generate with `php artisan key:generate`, adding the `--show` flag to print it |
| app.url | string | `""` | Application URL (required). Must match ingress host or service URL |
| containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsGroup":33,"runAsNonRoot":true,"runAsUser":33,"seccompProfile":{"type":"RuntimeDefault"}}` | Container-level security context |
| deploymentAnnotations | object | `{}` | Annotations to add to the deployment |
| deploymentStrategy | object | `{}` (defaults to RollingUpdate) | Deployment strategy configuration |
| env | object | `{}` | Additional environment variables (deprecated, use extraEnv instead) |
| externalDatabase.database | string | `"bookstack"` | External database name |
| externalDatabase.existingSecret | string | `""` | Name of existing secret containing database password (key: db-password) If set, externalDatabase.password is ignored |
| externalDatabase.existingTlsSecret | string | `""` | Name of existing secret containing TLS certificate (key: mysql.cert) If set, externalDatabase.tlsCert is ignored |
| externalDatabase.host | string | `""` | External database host |
| externalDatabase.password | string | `""` | External database password |
| externalDatabase.port | int | `3306` | External database port |
| externalDatabase.tlsCert | string | `""` | TLS certificate content for secure database connection |
| externalDatabase.user | string | `"bookstack"` | External database user |
| externalValkey.auth.existingSecret | string | `""` | Name of an existing Secret containing the external Valkey/Redis password. When set, REDIS_PASSWORD is injected into the BookStack container from this Secret. |
| externalValkey.auth.existingSecretPasswordKey | string | `"redis-password"` | Key inside the Secret that holds the password. |
| externalValkey.database | int | `0` | Redis database index |
| externalValkey.existingSecret | string | `""` | Name of an existing Secret whose "redis-servers" key contains the full BookStack REDIS_SERVERS connection string (host:port:database). When set, host/port/database above are ignored for the connection string. |
| externalValkey.host | string | `""` | External Valkey/Redis host |
| externalValkey.port | int | `6379` | External Valkey/Redis port |
| extraEnv | list | `[]` | Extra environment variables to add to the container (list format) |
| extraEnvFrom | list | `[]` | Extra environment variables from ConfigMaps or Secrets |
| extraVolumeMounts | list | `[{"mountPath":"/tmp","name":"tmp"},{"mountPath":"/run","name":"run"},{"mountPath":"/var/www/bookstack/bootstrap/cache","name":"bootstrap-cache"},{"mountPath":"/var/www/bookstack/storage/logs","name":"storage-logs"},{"mountPath":"/var/www/bookstack/storage/framework/views","name":"storage-framework-views"}]` | Extra volume mounts appended to the BookStack container |
| extraVolumes | list | `[{"emptyDir":{},"name":"tmp"},{"emptyDir":{},"name":"run"},{"emptyDir":{},"name":"bootstrap-cache"},{"emptyDir":{},"name":"storage-logs"},{"emptyDir":{},"name":"storage-framework-views"}]` | Extra volumes appended to the pod spec |
| fullnameOverride | string | `""` | Override the full name of the release |
| hacks | object | `{}` (no hacks; APP_THEME is not set) | BookStack hacks to install, keyed by module folder name (`[A-Za-z0-9][A-Za-z0-9._-]*`). Each entry: `files` (required map of module-relative path -> file content), `description` (optional string), `enabled` (optional, default true) |
| httpRoute.annotations | object | `{}` | Extra annotations on the HTTPRoute object |
| httpRoute.enabled | bool | `false` | Enable Gateway API HTTPRoute |
| httpRoute.hostnames | list | `[]` | Hostnames this route answers for (route-level, not per-path) |
| httpRoute.httpsRedirect.enabled | bool | `true` | Enable the HTTP -> HTTPS redirect: a secondary HTTPRoute on the HTTP (:80) listener carrying a RequestRedirect filter. Only acts when httpRoute.enabled AND an HTTP listener is identified via sectionName |
| httpRoute.httpsRedirect.sectionName | string | `""` | The HTTP (:80) listener on the same Gateway |
| httpRoute.httpsRedirect.statusCode | int | `301` | Redirect status code (301, 302, 303, 307 or 308) |
| httpRoute.parentRefs | list | `[{"name":""}]` | The existing Gateway(s) this route attaches to. name is REQUIRED when enabled; sectionName (the HTTPS listener) is REQUIRED when httpsRedirect is enabled (an unpinned route binds all listeners incl. :80 and would loop) |
| httpRoute.paths | list | `[{"type":"PathPrefix","value":"/"}]` | Path matches; the backendRef to the app service is implicit |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.repository | string | `"solidnerd/bookstack"` | BookStack image repository |
| image.tag | string | `""` | Overrides the image tag (defaults to chart appVersion) |
| imagePullSecrets | list | `[]` | Image pull secrets for private registries |
| ingress.annotations | object | `{}` | Ingress annotations |
| ingress.className | string | `""` | Ingress class name (e.g., "nginx") |
| ingress.enabled | bool | `false` | Enable ingress |
| ingress.hosts | list | `["bookstack.example.local"]` | Ingress hostnames |
| ingress.path | string | `"/"` | Ingress path |
| ingress.pathType | string | `"ImplementationSpecific"` | Ingress path type |
| ingress.tls | list | `[]` | Ingress TLS configuration |
| ldap.base_dn | string | `""` | LDAP base DN (e.g., "dc=example,dc=com") |
| ldap.dn | string | `""` | LDAP bind DN (e.g., "cn=admin,dc=example,dc=com") |
| ldap.enabled | bool | `false` | Enable LDAP authentication |
| ldap.pass | string | `""` | LDAP bind password (stored in Kubernetes Secret) |
| ldap.server | string | `""` | LDAP server address (e.g., "ldap://ldap.example.com:389") |
| ldap.userFilter | string | `""` | LDAP user filter (e.g., "(&(uid=${user}))") |
| ldap.version | string | `""` | LDAP protocol version (usually "3") |
| livenessProbe | object | `{"failureThreshold":6,"httpGet":{"path":"/status","port":"http"},"initialDelaySeconds":30,"periodSeconds":10,"timeoutSeconds":5}` | Liveness probe configuration |
| mariadb.architecture | string | `"standalone"` | MariaDB architecture (standalone or replication) |
| mariadb.auth.database | string | `"bookstack"` | MariaDB database name |
| mariadb.auth.password | string | `""` | MariaDB user password (auto-generated if not specified) |
| mariadb.auth.rootPassword | string | `""` | MariaDB root password (auto-generated if not specified) |
| mariadb.auth.username | string | `"bookstack"` | MariaDB database user |
| mariadb.enabled | bool | `true` | Enable MariaDB subchart. Set to false to use externalDatabase |
| mariadb.primary.persistence.accessModes | list | `["ReadWriteOnce"]` | Access mode for MariaDB PVC |
| mariadb.primary.persistence.enabled | bool | `false` | Enable persistence for MariaDB |
| mariadb.primary.persistence.size | string | `"8Gi"` | Size of MariaDB PVC |
| mariadb.primary.persistence.storageClass | string | `""` (use cluster default) | Storage class for MariaDB PVC |
| modules | object | `{}` (no modules) | External theme modules to install, keyed by module folder name (`[A-Za-z0-9][A-Za-z0-9._-]*`, must not match a `hacks` key). Each entry: `url` (required, http(s) URL of the module ZIP), `sha256` (required, hex SHA-256 of the ZIP), `enabled` (optional, default true) |
| nameOverride | string | `""` | Override the name of the chart |
| networkPolicy.egress.extraRules | list | `[]` | Additional egress rules |
| networkPolicy.enabled | bool | `false` | Enable NetworkPolicy |
| networkPolicy.ingress.namespaceSelector | object | `{}` | Namespace selector for ingress traffic |
| networkPolicy.ingress.podSelector | object | `{}` | Pod selector for ingress traffic |
| nodeSelector | object | `{}` | Node selector for pod assignment |
| oidc.additionalScopes | string | `""` | Additional OAuth scopes to request (comma-separated) Note: 'openid', 'profile', and 'email' are always included Example: "groups" or "groups,roles" |
| oidc.authEndpoint | string | `""` | Authorization endpoint URL (only if issuerDiscover is false) |
| oidc.autoInitiate | string | "false" | Automatically initiate OIDC login if it's the only auth method |
| oidc.clientId | string | `""` | OIDC client ID (required unless using existingSecret) |
| oidc.clientSecret | string | `""` | OIDC client secret (required unless using existingSecret) |
| oidc.displayNameClaims | string | "name" | Claim(s) to use for user display names. Use '\|' to concatenate multiple claims Examples: "name", "given_name\|family_name", "preferred_username" |
| oidc.dumpUserDetails | string | "false" | Dump user claim details for troubleshooting (blocks login) WARNING: May expose private details - only for debugging |
| oidc.enabled | bool | `false` | Enable OIDC authentication. Note: When enabled, AUTH_METHOD will be set to 'oidc' |
| oidc.endSessionEndpoint | string | "false" | RP-initiated logout endpoint. Options: "false" (disabled), "true" (auto-discover), or specific URL |
| oidc.existingSecret | string | `""` | Name of existing secret containing OIDC credentials If set, clientId and clientSecret are ignored Secret must contain keys: oidc-client-id, oidc-client-secret |
| oidc.externalIdClaim | string | "sub" (OIDC standard) | Claim to use for unique user identification (advanced use only) WARNING: Changing this with existing users may cause login issues |
| oidc.fetchAvatar | string | "false" | Fetch user avatars from the 'picture' claim on login WARNING: This can be a security risk due to server-side fetching |
| oidc.groupsClaim | string | `"groups"` | Claim containing group names (supports dot-notation for nested properties) Examples: "groups", "resource_access.bookstack.roles" |
| oidc.issuer | string | `""` | OIDC issuer URL (required). Must start with 'https://' Example: "https://accounts.google.com" or "https://login.microsoftonline.com/tenant-id/v2.0" |
| oidc.issuerDiscover | string | "true" | Enable auto-discovery of OIDC endpoints and keys from issuer |
| oidc.name | string | "SSO" | Display name for the SSO button (e.g., "Login with SSO") |
| oidc.publicKey | string | `""` | Public key path for token validation (only if issuerDiscover is false) Format: "file:///path/to/public.key" |
| oidc.removeFromGroups | string | "false" | Remove users from BookStack roles not present in OIDC groups Note: "Default Registration Role" is always treated as matched |
| oidc.tokenEndpoint | string | `""` | Token endpoint URL (only if issuerDiscover is false) |
| oidc.userToGroups | string | "false" | Enable syncing BookStack roles based on OIDC groups |
| oidc.userinfoEndpoint | string | `""` | User info endpoint URL (only if issuerDiscover is false) |
| persistence.storage.accessMode | string | `"ReadWriteOnce"` | Access mode for storage PVC |
| persistence.storage.annotations | object | `{}` | Annotations for storage PVC |
| persistence.storage.enabled | bool | `true` | Enable persistence for storage |
| persistence.storage.existingClaim | string | `""` | Use existing PVC for storage |
| persistence.storage.size | string | `"8Gi"` | Size of storage PVC |
| persistence.storage.storageClass | string | `""` (use cluster default) | Storage class for storage PVC |
| persistence.uploads.accessMode | string | `"ReadWriteOnce"` | Access mode for uploads PVC |
| persistence.uploads.annotations | object | `{}` | Annotations for uploads PVC |
| persistence.uploads.enabled | bool | `true` | Enable persistence for uploads |
| persistence.uploads.existingClaim | string | `""` | Use existing PVC for uploads |
| persistence.uploads.size | string | `"8Gi"` | Size of uploads PVC |
| persistence.uploads.storageClass | string | `""` (use cluster default) | Storage class for uploads PVC |
| podAnnotations | object | `{}` | Annotations to add to the pod |
| podDisruptionBudget.enabled | bool | `false` | Enable PodDisruptionBudget |
| podDisruptionBudget.minAvailable | int | `1` | Minimum available pods during disruption |
| podSecurityContext | object | `{"fsGroup":33,"runAsGroup":33,"runAsNonRoot":true,"runAsUser":33,"seccompProfile":{"type":"RuntimeDefault"}}` | Pod-level security context |
| rbac.create | bool | `true` | Create RBAC resources (Role and RoleBinding) Note: The default RBAC permissions may not be necessary for BookStack. Consider setting this to false unless you have a specific use case. |
| readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/status","port":"http"},"initialDelaySeconds":15,"periodSeconds":5,"timeoutSeconds":3}` | Readiness probe configuration |
| replicaCount | int | `1` | Number of BookStack replicas to deploy. Multiple replicas require: (1) valkey.enabled=true for shared PHP sessions, and (2) persistence PVCs with accessMode ReadWriteMany (or a shared storage class). |
| resources | object | `{}` | Resource limits and requests |
| service.annotations | object | `{}` | Annotations to add to the service |
| service.port | int | `80` | Service port |
| service.type | string | `"ClusterIP"` | Kubernetes service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a ServiceAccount should be created |
| serviceAccount.name | string | `""` | The name of the ServiceAccount to use (auto-generated if not set and create is true) |
| startupProbe | object | `{"failureThreshold":30,"httpGet":{"path":"/status","port":"http"},"initialDelaySeconds":0,"periodSeconds":5,"timeoutSeconds":3}` | Startup probe configuration |
| tolerations | list | `[]` | Tolerations for pod assignment |
| valkey.architecture | string | `"standalone"` | Valkey deployment architecture. Use "standalone" (single pod) for BookStack session storage; "replication" would deploy an unnecessary primary+replica cluster. |
| valkey.auth.enabled | bool | `false` | Enable password authentication for in-cluster Valkey. When true, a VALKEY_PASSWORD env var is injected into the BookStack container from the Secret referenced by auth.existingSecret (or the Bitnami auto-generated Secret when existingSecret is empty). Kubernetes then expands $(VALKEY_PASSWORD) inside REDIS_SERVERS at container start time, so BookStack receives the full host:port:db:password string. This approach requires no Helm lookup() and works with GitOps tools (ArgoCD, Flux) and restricted-RBAC environments. |
| valkey.auth.existingSecret | string | `""` | Name of a pre-existing Secret that contains the Valkey password. When set, the Deployment reads VALKEY_PASSWORD from this Secret. Leave empty to let the Bitnami Valkey subchart auto-generate the Secret (auto-generated secret name: <release>-valkey, key: valkey-password). |
| valkey.auth.existingSecretPasswordKey | string | `"valkey-password"` | Key inside existingSecret that holds the Valkey password. Must match the key used when the Secret was created. |
| valkey.auth.password | string | `""` | Inline Valkey password (alternative to existingSecret). When set, the Bitnami subchart stores it in an auto-generated Secret. Prefer existingSecret for production deployments. |
| valkey.commonConfiguration | string | `"appendonly no\nsave \"\""` | Valkey server configuration overrides (redis.conf directives) |
| valkey.enabled | bool | `true` | Enable the Valkey subchart for PHP session (and optionally cache) storage. When true, SESSION_DRIVER and CACHE_DRIVER are automatically set to "redis". |
| valkey.primary.disableCommands | list | `[]` |  |
| valkey.primary.persistence.enabled | bool | `false` | Persistence is intentionally disabled: session data is ephemeral and does not need to survive cluster restarts. |
| valkey.replica.disableCommands | list | `[]` |  |
| valkey.replica.persistence.enabled | bool | `false` |  |
----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
