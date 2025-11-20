# bookstack

![Version: 2.1.0](https://img.shields.io/badge/Version-2.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 25.11](https://img.shields.io/badge/AppVersion-25.11-informational?style=flat-square)

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
| https://charts.bitnami.com/bitnami | mariadb | 20.x.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` | Affinity rules for pod assignment |
| app.existingSecret | string | `""` | Name of existing secret containing APP_KEY (key: app-key) If set, app.key is ignored |
| app.key | string | `""` |  |
| app.url | string | `""` | Application URL (required). Must match ingress host or service URL |
| containerSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":false,"runAsNonRoot":true,"runAsUser":33}` | Container-level security context |
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
| extraEnv | list | `[]` | Extra environment variables to add to the container (list format) |
| extraEnvFrom | list | `[]` | Extra environment variables from ConfigMaps or Secrets |
| fullnameOverride | string | `""` | Override the full name of the release |
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
| oidc.displayNameClaims | string | "name" | Claim(s) to use for user display names. Use '|' to concatenate multiple claims Examples: "name", "given_name|family_name", "preferred_username" |
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
| podSecurityContext | object | `{"fsGroup":33,"runAsNonRoot":true,"runAsUser":33}` | Pod-level security context |
| rbac.create | bool | `true` | Create RBAC resources (Role and RoleBinding) Note: The default RBAC permissions may not be necessary for BookStack. Consider setting this to false unless you have a specific use case. |
| readinessProbe | object | `{"failureThreshold":3,"httpGet":{"path":"/status","port":"http"},"initialDelaySeconds":15,"periodSeconds":5,"timeoutSeconds":3}` | Readiness probe configuration |
| replicaCount | int | `1` | Number of BookStack replicas to deploy (currently only 1 is supported without shared storage) |
| resources | object | `{}` | Resource limits and requests |
| service.annotations | object | `{}` | Annotations to add to the service |
| service.port | int | `80` | Service port |
| service.type | string | `"ClusterIP"` | Kubernetes service type |
| serviceAccount.annotations | object | `{}` | Annotations to add to the service account |
| serviceAccount.create | bool | `true` | Specifies whether a ServiceAccount should be created |
| serviceAccount.name | string | `""` | The name of the ServiceAccount to use (auto-generated if not set and create is true) |
| startupProbe | object | `{"failureThreshold":30,"httpGet":{"path":"/status","port":"http"},"initialDelaySeconds":0,"periodSeconds":5,"timeoutSeconds":3}` | Startup probe configuration |
| tolerations | list | `[]` | Tolerations for pod assignment |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
