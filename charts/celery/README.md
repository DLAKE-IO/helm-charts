# celery

![Version: 0.1.0](https://img.shields.io/badge/Version-0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 5.4.0](https://img.shields.io/badge/AppVersion-5.4.0-informational?style=flat-square)

A Helm chart to deploy Celery distributed task queue (worker, beat scheduler, flower dashboard)

## TL;DR

```bash
helm repo add dlake https://dlake-io.github.io/helm-charts/
helm repo add valkey https://valkey.io/valkey-helm/
helm install my-celery dlake/celery \
  --set image.repository=myregistry/myapp \
  --set image.tag=latest \
  --set celery.app=myproject.celery
```

> **Note:** The default `library/celery` image is deprecated (unmaintained since 2017).
> You must provide your own image built from the
> [official Celery Dockerfile](https://github.com/celery/celery/blob/main/docker/Dockerfile).

## Introduction

This chart bootstraps a [Celery](https://docs.celeryq.dev/) distributed task queue on a
[Kubernetes](https://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

Three independent Deployments are managed:

| Component | Default | Purpose |
|-----------|---------|---------|
| **Worker** | Enabled (1 replica) | Executes tasks. Horizontally scalable. |
| **Beat** | Disabled | Periodic task scheduler. Hard singleton (Recreate strategy). |
| **Flower** | Enabled | Web monitoring dashboard at port 5555. |

Valkey (Redis-compatible) is bundled as an optional subchart using the
[official Valkey Helm chart](https://github.com/valkey-io/valkey-helm) for the broker and result backend.

## Prerequisites

- Kubernetes 1.20+
- Helm 3.5+
- Add the Valkey chart repository (required for dependency update):

```bash
helm repo add valkey https://valkey.io/valkey-helm/
```

## Installing the Chart

```bash
helm install my-celery dlake/celery \
  --set image.repository=myregistry/myapp \
  --set image.tag=latest \
  --set celery.app=myproject.celery
```

## Uninstalling the Chart

```bash
helm uninstall my-celery
```

## Configuration

### Required values

| Parameter | Description | Example |
|-----------|-------------|---------|
| `image.repository` | Your Celery application image | `myregistry/myapp` |
| `celery.app` | Celery application module | `myproject.celery` |

`celery.app` is not required when `worker.command` and `beat.command` are both set explicitly.

### Workers

Workers are stateless and horizontally scalable. Enable autoscaling:

```yaml
worker:
  autoscaling:
    enabled: true
    minReplicas: 1
    maxReplicas: 10
    targetCPUUtilizationPercentage: 80
```

### Beat scheduler

Enable the beat scheduler:

```yaml
beat:
  enabled: true
```

**Important:** Beat is a singleton. Two beat processes cause duplicate task scheduling.
The chart enforces this with `replicas: 1` and `strategy: type: Recreate`.

#### File-based scheduler (default)

The default scheduler writes the schedule to `/data/celerybeat-schedule`.
By default an `emptyDir` is used — the schedule is lost on pod restart.

For production, use a PVC:

```yaml
beat:
  enabled: true
  persistence:
    enabled: true
    storageClass: my-networked-storage-class   # use a networked class, not local
    size: 1Gi
```

#### Redis-backed scheduler (RedBeat)

RedBeat stores the schedule in Valkey/Redis, survives restarts, and requires no PVC.

**Requires `celery-redbeat` installed in your image:** `pip install celery-redbeat`

```yaml
beat:
  enabled: true
  scheduler: redbeat
```

### Flower dashboard

Flower is enabled by default. Expose via Ingress:

```yaml
flower:
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: flower.example.com
        paths:
          - path: /
            pathType: Prefix
```

Add basic auth:

```yaml
flower:
  extraArgs:
    - --basic_auth=admin:secret
```

### External broker

To use your own Redis/Valkey instead of the bundled subchart:

```yaml
valkey:
  enabled: false

celery:
  brokerUrl: "redis://my-redis:6379/0"
  resultBackend: "redis://my-redis:6379/1"
```

Or reference an existing Secret:

```yaml
valkey:
  enabled: false

celery:
  existingSecret: my-celery-secret      # must contain keys: broker-url, result-backend
```

### Workers have no Service

Celery workers pull tasks from the broker — they do not receive inbound connections.
No Kubernetes Service is created for workers. Only Flower has a Service.

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Tristan | <tristan@dlake.io> | <https://dlake.io> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://valkey.io/valkey-helm/ | valkey | 0.9.x |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| beat.command | list | `[]` | Override the full beat command. When set, celery.app is not required. |
| beat.enabled | bool | `false` | Enable the Celery beat scheduler |
| beat.extraArgs | list | `[]` | Extra arguments appended to the default beat command |
| beat.persistence.accessMode | string | `"ReadWriteOnce"` | |
| beat.persistence.enabled | bool | `false` | Enable PVC for the beat schedule file (only used when scheduler=default) |
| beat.persistence.size | string | `"1Gi"` | |
| beat.persistence.storageClass | string | `""` | |
| beat.scheduler | string | `"default"` | Scheduler backend: "default" (file-based) or "redbeat" (Redis-backed, requires celery-redbeat) |
| celery.app | string | `""` | Celery application module (e.g. "myproject.celery"). Required when worker.command/beat.command are empty. |
| celery.brokerUrl | string | `""` | Broker URL — used when valkey.enabled=false and existingSecret is not set |
| celery.existingSecret | string | `""` | Reference an existing Secret with broker-url and result-backend keys |
| celery.existingSecretBackendKey | string | `"result-backend"` | |
| celery.existingSecretBrokerKey | string | `"broker-url"` | |
| celery.extraEnv | list | `[]` | Extra environment variables injected into worker, beat, and flower containers |
| celery.resultBackend | string | `""` | Result backend URL — used when valkey.enabled=false and existingSecret is not set |
| extraVolumeMounts | list | `[]` | Extra volume mounts for all containers |
| extraVolumes | list | `[]` | Extra volumes for all pods |
| flower.enabled | bool | `true` | Enable the Flower monitoring dashboard |
| flower.extraArgs | list | `[]` | Extra arguments passed to flower (e.g. ["--basic_auth=user:pass"]) |
| flower.image.pullPolicy | string | `"IfNotPresent"` | |
| flower.image.repository | string | `"mher/flower"` | |
| flower.image.tag | string | `"2.0"` | |
| flower.ingress.annotations | object | `{}` | |
| flower.ingress.className | string | `""` | |
| flower.ingress.enabled | bool | `false` | |
| flower.ingress.hosts[0].host | string | `"celery-flower.example.com"` | |
| flower.ingress.hosts[0].paths[0].path | string | `"/"` | |
| flower.ingress.hosts[0].paths[0].pathType | string | `"ImplementationSpecific"` | |
| flower.ingress.tls | list | `[]` | |
| flower.replicaCount | int | `1` | Number of Flower replicas |
| flower.service.port | int | `5555` | |
| flower.service.type | string | `"ClusterIP"` | |
| fullnameOverride | string | `""` | |
| image.pullPolicy | string | `"IfNotPresent"` | |
| image.repository | string | `"celery"` | Worker/beat image. **Deprecated placeholder** — replace with your own Celery application image. |
| image.tag | string | `""` | Overrides the image tag (default: chart appVersion) |
| imagePullSecrets | list | `[]` | |
| nameOverride | string | `""` | |
| podAnnotations | object | `{}` | |
| podSecurityContext.fsGroup | int | `2000` | |
| securityContext.capabilities.drop[0] | string | `"ALL"` | |
| securityContext.readOnlyRootFilesystem | bool | `true` | |
| securityContext.runAsNonRoot | bool | `true` | |
| securityContext.runAsUser | int | `1000` | |
| securityContext.seccompProfile.type | string | `"RuntimeDefault"` | |
| serviceAccount.annotations | object | `{}` | |
| serviceAccount.create | bool | `true` | |
| serviceAccount.name | string | `""` | |
| valkey.enabled | bool | `true` | Deploy Valkey using the bundled official chart (standalone mode) |
| valkey.replica.enabled | bool | `false` | Standalone mode — single pod, no replicas |
| worker.affinity | object | `{}` | |
| worker.autoscaling.enabled | bool | `false` | |
| worker.autoscaling.maxReplicas | int | `10` | |
| worker.autoscaling.minReplicas | int | `1` | |
| worker.autoscaling.targetCPUUtilizationPercentage | int | `80` | |
| worker.command | list | `[]` | Override the full worker command. When set, celery.app is not required and default probes are omitted. |
| worker.extraArgs | list | `[]` | Extra arguments appended to the default worker command |
| worker.livenessProbe | object | `{}` | Custom liveness probe — used when worker.command is set |
| worker.readinessProbe | object | `{}` | Custom readiness probe — used when worker.command is set |
| worker.replicaCount | int | `1` | Number of worker replicas |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/tag/v1.14.2)
