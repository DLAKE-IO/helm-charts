# cryptgeon

![Version: 2.11.0](https://img.shields.io/badge/Version-2.11.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 2.8.2](https://img.shields.io/badge/AppVersion-2.8.2-informational?style=flat-square)

A Helm chart to install cryptgeon

## TL;DR;

```bash
helm repo add dlake https://dlake-io.github.io/helm-charts/
helm install cryptgeon dlake/cryptgeon -n cryptgeon --create-namespace
```

## Introduction

This chart bootstraps a [cryptgeon](https://github.com/cupcakearmy/cryptgeon) Deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

## Installing the Chart

To install the chart with the release name `cryptgeon`:

```bash
helm install cryptgeon dlake/cryptgeon
```

## Uninstalling the Chart

To uninstall the `cryptgeon` deployment:

```bash
helm uninstall cryptgeon
```

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Drustan | <5606292+drustan@users.noreply.github.com> |  |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.bitnami.com/bitnami | redis | 20.x.x |

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

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
      sectionName: https        # app traffic: HTTPS listener
  hostnames:
    - notes.example.com
  httpsRedirect:
    enabled: true
    sectionName: http           # HTTP (:80) listener -> 301 to HTTPS
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| affinity | object | `{}` |  |
| autoscaling.enabled | bool | `false` |  |
| autoscaling.maxReplicas | int | `100` |  |
| autoscaling.minReplicas | int | `1` |  |
| autoscaling.targetCPUUtilizationPercentage | int | `80` |  |
| cryptgeon.allow_advanced | string | `"true"` |  |
| cryptgeon.max_expiration | int | `360` |  |
| cryptgeon.max_views | int | `100` |  |
| cryptgeon.size_limit | string | `"1 KiB"` |  |
| cryptgeon.theme_favicon | string | `""` |  |
| cryptgeon.theme_image | string | `""` |  |
| cryptgeon.theme_page_title | string | `""` |  |
| cryptgeon.theme_text | string | `""` |  |
| cryptgeon.verbosity | string | `"warn"` |  |
| externalRedis.existingSecretKey | string | `"redis-connection"` |  |
| externalRedis.existingSecretName | string | `""` |  |
| extraVolumeMounts | list | `[]` |  |
| extraVolumes | list | `[]` |  |
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
| image.repository | string | `"cupcakearmy/cryptgeon"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext.fsGroup | int | `2000` |  |
| redis.auth.enabled | bool | `false` |  |
| redis.enabled | bool | `true` |  |
| redis.master.persistence.enabled | bool | `false` |  |
| redis.replica.persistence.enabled | bool | `false` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| securityContext.readOnlyRootFilesystem | bool | `true` |  |
| securityContext.runAsNonRoot | bool | `true` |  |
| securityContext.runAsUser | int | `1000` |  |
| securityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| service.port | int | `8000` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
