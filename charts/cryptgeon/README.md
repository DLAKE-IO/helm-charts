# Cryptgeon

[Cryptgeon](https://github.com/cupcakearmy/cryptgeon) is a secure, open source sharing note or file service.

## TL;DR;

```bash
helm repo add dlake https://dlake-io.github.io/helm-charts/
helm install cryptgeon dlake/cryptgeon -n cryptgeon
```

## Introduction

This chart bootstraps a [Cryptgeon](https://github.com/cupcakearmy/cryptgeon) Deployment on a [Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

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

## Configuration

The following table lists the configurable parameters of the Cryptgeon chart and their default values.

| Key | Default Value | Description |
| --- | --- | --- |
| replicaCount | 1 | The number of replicas for the deployment. |
| image.repository | cupcakearmy/cryptgeon | The repository of the container image. |
| image.pullPolicy | IfNotPresent | The pull policy for the container image. |
| image.tag | "" | Overrides the image tag whose default is the chart appVersion. |
| imagePullSecrets | [] | Secrets needed to pull the container image. |
| nameOverride | "" | Overrides the name template used for resources. |
| fullnameOverride | "" | Overrides the full name template used for resources. |
| cryptgeon.size_limit | "1 KiB" | The maximum size for the body. |
| cryptgeon.max_views | 100 | The maximal number of views. |
| cryptgeon.max_expiration | 360 | The maximal expiration in minutes. |
| cryptgeon.allow_advanced | "true" | Allow custom configuration for notes. |
| cryptgeon.verbosity | "warn" | The verbosity level for the backend. |
| cryptgeon.theme_image | "" | The custom image for replacing the logo. |
| cryptgeon.theme_text | "" | The custom text for replacing the description below the logo. |
| cryptgeon.theme_page_title | "" | The custom text for the page title. |
| cryptgeon.theme_favicon | "" | The custom URL for the favicon. |
| extraVolumes | [] | Optionally specify extra list of additional volumes for cryptgeon pods. |
| extraVolumeMounts | [] | Optionally specify extra list of additional volumeMounts for cryptgeon container(s). |
| serviceAccount.create | true | Specifies whether a service account should be created. |
| serviceAccount.annotations | {} | Annotations to add to the service account. |
| serviceAccount.name | "" | The name of the service account to use. |
| podAnnotations | {} | Annotations to add to the pod. |
| podSecurityContext | {"fsGroup":2000} | The security context for the pod. |
| securityContext | {"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"readOnlyRootFilesystem":true,"runAsNonRoot":true,"runAsUser":1000,"seccompProfile":{"type":"RuntimeDefault"}} | The security context for the container. |
| redis.enabled | true | Deploy Redis using bundled chart. |
| redis.auth.enabled | false | Specifies whether Redis authentication is enabled. |
| redis.master.persistence.enabled | false | Specifies whether persistence is enabled for the Redis master. |
| redis.replica.persistence.enabled | false | Specifies whether persistence is enabled for Redis replicas. |
| externalRedis.existingSecretName | "" | The name of the existing secret for external Redis. |
| externalRedis.existingSecretKey | redis-connection | The key in the existing secret for the Redis connection. |
| service.type | ClusterIP | The type of the service. |
| service.port | 8000 | The port for the service. |
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
helm install cryptgeon dlake/cryptgeon -n cryptgeon --set replicas=1
```

Alternatively, a YAML file that specifies the values for the parameters can be provided while
installing the chart. For example:

```bash
helm install cryptgeon dlake/cryptgeon -n cryptgeon --values values.yaml
```

### Database Setup

By default, the Redis chart will be used with authentifacation and data persistence turned off for testing purpose. It is highly recommended to deploy your own Redis cluster for production use. 

Please refer to the Bitnami [Redis](https://github.com/bitnami/charts/tree/main/bitnami/redis) chart for additional configuration options.

#### Using an External Database

An external Redis database can be used via an existing secret:

```yaml
externalRedis:
  # Used only when redis.enabled is false.
  # Existing secret's content must be of the following form : https://docs.rs/redis/latest/redis/#connection-parameters
  existingSecretName: ""
  existingSecretKey: redis-connection
```

## Bad Gateway and Proxy Buffer Size in Nginx

A common issue with Cryptgeon and nginx is that the proxy buffer may be too small for what Cryptgeon is trying to send. This will result in a Bad Gateway (502) error. The solution is to increase the buffer size of nginx. This can be done by creating an annotation in the ingress specification:

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: "512m"
```
