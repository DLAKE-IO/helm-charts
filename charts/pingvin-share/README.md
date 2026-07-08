A Helm chart to install Pingvin Share

![Version: 1.8.0](https://img.shields.io/badge/Version-1.8.0-informational?style=flat-square)
![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)
![AppVersion: v1.6.1](https://img.shields.io/badge/AppVersion-v1.6.1-informational?style=flat-square)

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Drustan | <5606292+drustan@users.noreply.github.com> |  |

## TL;DR;

```bash
helm repo add dlake https://dlake-io.github.io/helm-charts/
helm install pingvin-share dlake/pingvin-share -n pingvin-share
```

## Introduction

This chart bootstraps a [pingvin-share](https://github.com/stonith404/pingvin-share) Deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

> :warning: Currently, this serves as a proof of concept since the application's architecture restricts it from having more than one replica.

## Installing the Chart

To install the chart with the release name `pingvin-share`:

```bash
helm install pingvin-share dlake/pingvin-share
```

## Uninstalling the Chart

To uninstall the `pingvin-share` deployment:

```bash
helm uninstall pingvin-share
```
## Requirements

| Repository | Name | Version |
|------------|------|---------|
| oci://registry-1.docker.io/bitnamicharts | common | 2.x.x |

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

```yaml
httpRoute:
  enabled: true
  parentRefs:
    - name: my-gateway
      namespace: gateway-system
      sectionName: https
  hostnames:
    - share.example.com
```

### HTTP→HTTPS redirect

`httpRoute.httpsRedirect` (on by default) creates a second HTTPRoute
`<release>-http-redirect` on the Gateway's HTTP (`:80`) listener that redirects
to HTTPS with a `RequestRedirect` filter (status 301). Name the HTTP listener via
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
    - share.example.com
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
| image.repository | string | `"stonith404/pingvin-share"` |  |
| image.tag | string | `""` |  |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.className | string | `""` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` |  |
| ingress.tls | list | `[]` |  |
| livenessProbe.enabled | bool | `true` |  |
| livenessProbe.failureThreshold | int | `3` |  |
| livenessProbe.httpGet.httpHeaders | list | `[]` |  |
| livenessProbe.httpGet.path | string | `"/api/health"` |  |
| livenessProbe.httpGet.port | int | `3000` |  |
| livenessProbe.httpGet.scheme | string | `"HTTP"` |  |
| livenessProbe.initialDelaySeconds | int | `30` |  |
| livenessProbe.periodSeconds | int | `10` |  |
| livenessProbe.successThreshold | int | `1` |  |
| livenessProbe.timeoutSeconds | int | `5` |  |
| nameOverride | string | `""` |  |
| nodeSelector | object | `{}` |  |
| persistence.accessMode | string | `"ReadWriteOnce"` |  |
| persistence.enabled | bool | `true` |  |
| persistence.existingClaim | string | `""` |  |
| persistence.size | string | `"10Gi"` |  |
| persistence.storageClass | string | `""` |  |
| persistence.subPath | string | `""` |  |
| pingvin-share.backend.clamavHost | string | `"127.0.0.1"` |  |
| pingvin-share.backend.clamavPort | string | `"3310"` |  |
| pingvin-share.backend.dataDirectory | string | `"./data"` |  |
| pingvin-share.backend.databaseUrl | string | `"file:../data/pingvin-share.db?connection_limit=1"` |  |
| pingvin-share.frontend.apiUrl | string | `"http://localhost:8080"` |  |
| podAnnotations | object | `{}` |  |
| podSecurityContext.fsGroup | int | `2000` |  |
| readinessProbe.enabled | bool | `true` |  |
| readinessProbe.failureThreshold | int | `3` |  |
| readinessProbe.httpGet.httpHeaders | list | `[]` |  |
| readinessProbe.httpGet.path | string | `"/api/health"` |  |
| readinessProbe.httpGet.port | int | `3000` |  |
| readinessProbe.httpGet.scheme | string | `"HTTP"` |  |
| readinessProbe.initialDelaySeconds | int | `30` |  |
| readinessProbe.periodSeconds | int | `10` |  |
| readinessProbe.successThreshold | int | `1` |  |
| readinessProbe.timeoutSeconds | int | `5` |  |
| replicaCount | int | `1` |  |
| resources | object | `{}` |  |
| securityContext.allowPrivilegeEscalation | bool | `false` |  |
| securityContext.capabilities.drop[0] | string | `"ALL"` |  |
| securityContext.readOnlyRootFilesystem | bool | `true` |  |
| securityContext.runAsNonRoot | bool | `true` |  |
| securityContext.runAsUser | int | `1000` |  |
| securityContext.seccompProfile.type | string | `"RuntimeDefault"` |  |
| service.port | int | `3000` |  |
| service.type | string | `"ClusterIP"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
| tolerations | list | `[]` |  |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
