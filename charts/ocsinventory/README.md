# ocsinventory

![Version: 1.4.0](https://img.shields.io/badge/Version-1.4.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.12.3](https://img.shields.io/badge/AppVersion-2.12.3-informational?style=flat-square)

Open Computers and Software Inventory Next Generation is an assets management and deployment solution.

**Homepage:** <https://ocsinventory-ng.org/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Drustan | <5606292+drustan@users.noreply.github.com> |  |
## Source Code

* <http://wiki.ocsinventory-ng.org>
* <https://github.com/OCSInventory-NG/OCSInventory-Docker-Image>

## TL;DR;

```bash
helm repo add dlake https://dlake-io.github.io/helm-charts/
helm install ocsinventory dlake/ocsinventory -n ocsinventory --create-namespace
```

> **Note:** An external database is required. Configure `externalDatabase` or enable the bundled `mariadb` subchart.

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://registry-1.docker.io/bitnamicharts | mariadb | 20.x.x |

## Networking: Ingress or Gateway API

This chart exposes OCS Inventory through a Kubernetes `Ingress` (enabled by
default) and/or a Gateway API `HTTPRoute`. They toggle independently via
`ingress.enabled` and `httpRoute.enabled`; set `ingress.enabled: false` to
expose the app through the Gateway only.

Gateway API support creates only an `HTTPRoute` (`gateway.networking.k8s.io/v1`)
that attaches to a **pre-existing** Gateway via `httpRoute.parentRefs`; the chart
does not create the Gateway. TLS is terminated at the Gateway listener, so
`httpRoute` has no TLS block. Prerequisites:

- Gateway API CRDs installed in the cluster.
- A Gateway owned by the cluster admin (e.g. `gatewayClassName: cilium` for
  Cilium 1.15+), whose listener `allowedRoutes.namespaces` permits the release
  namespace.

`httpRoute.httpsRedirect` (on by default) additionally creates a second HTTPRoute
`<fullname>-http-redirect` on the Gateway's HTTP (`:80`) listener that redirects to
HTTPS with a `RequestRedirect` filter (status 301). Name the HTTP listener via
`httpsRedirect.sectionName` and pin the app route's HTTPS listener via
`parentRefs[].sectionName` — the two must differ or the chart refuses to render
(a shared listener would loop). If no HTTP listener is named, the redirect is
skipped (with a warning). Set `httpsRedirect.enabled: false` to turn it off.
With the redirect active, point OCS agents at `https://<host>/ocsinventory`;
agents that post to `http://` may not follow the redirect.

> **Warning — `ingress.basicauth` + `httpRoute.enabled`:** basic auth is
> implemented with ingress-nginx annotations on a dedicated Ingress and is not
> applied to the HTTPRoute, so `/ocsapi` and `/ocsinventory` are reachable
> through the Gateway without authentication. Enforce authentication at the
> Gateway (implementation-specific policy) if required.

```yaml
ingress:
  enabled: false
httpRoute:
  enabled: true
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
      sectionName: https        # app traffic: HTTPS listener
  hostnames:
    - ocs.example.com
  httpsRedirect:
    enabled: true
    sectionName: http           # HTTP (:80) listener -> 301 to HTTPS
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| Labels | object | `{}` |  |
| database.create | bool | `false` |  |
| database.database | string | `""` |  |
| database.hostname | string | `""` |  |
| database.jobName | string | `"createdb"` |  |
| database.password | string | `""` |  |
| database.root_password | string | `""` |  |
| database.username | string | `""` |  |
| deploymentAnnotations | object | `{}` |  |
| existingSecret | string | `""` |  |
| externalDatabase.database | string | `""` |  |
| externalDatabase.enabled | bool | `true` |  |
| externalDatabase.hostname | string | `""` |  |
| externalDatabase.password | string | `""` |  |
| externalDatabase.username | string | `""` |  |
| fullnameOverride | string | `""` |  |
| httpRoute.annotations | object | `{}` |  |
| httpRoute.enabled | bool | `false` |  |
| httpRoute.hostnames | list | `[]` |  |
| httpRoute.httpsRedirect.enabled | bool | `true` |  |
| httpRoute.httpsRedirect.sectionName | string | `""` |  |
| httpRoute.httpsRedirect.statusCode | int | `301` |  |
| httpRoute.parentRefs[0].name | string | `""` |  |
| httpRoute.paths[0].type | string | `"PathPrefix"` |  |
| httpRoute.paths[0].value | string | `"/"` |  |
| image.pullPolicy | string | `"IfNotPresent"` |  |
| image.repository | string | `"ocsinventory/ocsinventory-docker-image"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.basicauth.authRealm | string | `"Authentication Required"` |  |
| ingress.basicauth.enabled | bool | `false` |  |
| ingress.basicauth.password | string | `""` |  |
| ingress.basicauth.paths[0] | string | `"/ocsapi"` |  |
| ingress.basicauth.paths[1] | string | `"/ocsinventory"` |  |
| ingress.basicauth.username | string | `""` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `true` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.labels | object | `{}` |  |
| ingress.tls | list | `[]` |  |
| mariadb.auth.database | string | `""` |  |
| mariadb.auth.password | string | `""` |  |
| mariadb.auth.rootPassword | string | `""` |  |
| mariadb.auth.username | string | `""` |  |
| mariadb.enabled | bool | `false` |  |
| mariadb.jobName | string | `"createmariadbserver"` |  |
| metrics.enabled | bool | `false` |  |
| metrics.image.pullPolicy | string | `"IfNotPresent"` |  |
| metrics.image.repository | string | `"docker.io/bitnami/apache-exporter"` |  |
| metrics.image.tag | string | `"1.0.9-debian-12-r5"` |  |
| metrics.resources.limits.cpu | string | `"200m"` |  |
| metrics.resources.limits.memory | string | `"256Mi"` |  |
| metrics.resources.requests.cpu | string | `"100m"` |  |
| metrics.resources.requests.memory | string | `"100Mi"` |  |
| metrics.serviceMonitor.enabled | bool | `false` |  |
| metrics.serviceMonitor.labels.prometheus | string | `"prometheus"` |  |
| metrics.serviceMonitor.labels.release | string | `"tobedefined"` |  |
| nameOverride | string | `""` |  |
| persistence.accessMode | string | `"ReadWriteOnce"` |  |
| persistence.annotations | object | `{}` |  |
| persistence.enabled | bool | `true` |  |
| persistence.size | string | `"10Gi"` |  |
| persistence.storageClass | string | `""` |  |
| phpconfig.ocsinventory | string | `"upload_max_filesize = 200M\npost_max_size = 201M\nmax_execution_time = -1\nmax_input_time = -1\n"` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext | object | `{}` |  |
| replicaCount | int | `1` |  |
| resources.limits.cpu | string | `"200m"` |  |
| resources.limits.memory | string | `"512Mi"` |  |
| resources.requests.cpu | string | `"100m"` |  |
| resources.requests.memory | string | `"256Mi"` |  |
| securityContext | object | `{}` |  |
----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
