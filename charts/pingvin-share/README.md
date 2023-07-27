# Pingvin Share

[pingvin-share](https://github.com/stonith404/pingvin-share) is self-hosted file sharing platform and an alternative for WeTransfer.

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

## Configuration

The following table lists the configurable parameters of the pingvin-share chart and their default values.

| Key | Default Value | Description |
| --- | --- | --- |
| replicaCount | 1 | The number of replicas for the deployment. |
| image.repository | stonith404/pingvin-share | The repository of the container image. |
| image.pullPolicy | IfNotPresent | The pull policy for the container image. |
| image.tag | "" | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | [] | Secrets needed to pull the container image. |
| nameOverride | "" | Overrides the name template used for resources. |
| fullnameOverride | "" | Overrides the full name template used for resources. |
| pingvin-share.databaseUrl | "file:../data/pingvin-share.db?connection_limit=1" | The URL of the SQLite database. |
| pingvin-share.dataDirectory | "./data" | The directory where data is stored. |
| pingvin-share.clamavHost | "127.0.0.1" | The IP address of the ClamAV server. |
| pingvin-share.clamavPort | "3310" | The port number of the ClamAV server. |
| pingvin-share.apiUrl | "http://localhost:8080" | The URL of the backend for the frontend. |
| extraVolumes | [] | Optionally specify extra list of additional volumes for pingvin-share pods. |
| extraVolumeMounts | [] | Optionally specify extra list of additional volumeMounts for pingvin-share container(s). |
| serviceAccount.create | true | Specifies whether a service account should be created. |
| serviceAccount.annotations | {} | Annotations to add to the service account. |
| serviceAccount.name | "" | The name of the service account to use. |
| podAnnotations | {} | Annotations to add to the pod. |
| podSecurityContext | {"fsGroup":2000} | The security context for the pod. |
| securityContext | {"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}} | The security context for the container. |
| service.type | ClusterIP | The type of the service. |
| service.port | 3000 | The port for the service. |
| ingress.enabled | false | Specifies whether ingress is enabled. |
| ingress.className | "" | The ingress class name. |
| ingress.annotations | {} | Annotations to add to the ingress. |
| ingress.hosts | [{ host: "chart-example.local", paths: [{ path: "/", pathType: "ImplementationSpecific" }] }] | The hosts and paths for the ingress. |
| ingress.tls | [] | TLS configuration for the ingress. |
| resources | {} | Custom resource configuration for the deployment. |
| autoscaling.enabled | false | Specifies whether autoscaling is enabled. |
| autoscaling.minReplicas | 1 | The minimum number of replicas for autoscaling. |
| autoscaling.maxReplicas | 100 | The maximum number of replicas for autoscaling. |
| autoscaling.targetCPUUtilizationPercentage | 80 | The target CPU utilization percentage for autoscaling. |
| nodeSelector | {} | Node selector for pod assignment. |
| tolerations | [] | Tolerations for pod assignment. |
| affinity | {} | Affinity rules for pod assignment. |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example:

```bash
helm install pingvin-share dlake/pingvin-share -n pingvin-share --set image.tag="v0.17.0"
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while
installing the chart. For example:

```bash
helm install pingvin-share dlake/pingvin-share -n pingvin-share --values values.yaml
```
