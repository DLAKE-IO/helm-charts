# bookstack

![Version: 2.0.0](https://img.shields.io/badge/Version-2.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 25.2](https://img.shields.io/badge/AppVersion-25.2-informational?style=flat-square)

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
