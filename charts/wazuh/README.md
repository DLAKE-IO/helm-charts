# wazuh

![Version: 2.5.1](https://img.shields.io/badge/Version-2.5.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.14.4](https://img.shields.io/badge/AppVersion-4.14.4-informational?style=flat-square)

Wazuh is a free and open source security platform that unifies XDR and SIEM protection for endpoints and cloud workloads.

> **Upstream:** This chart is maintained at [clyso-dr/wazuh-helm](https://github.com/clyso-dr/wazuh-helm),
> forked from [morgoved/wazuh-helm](https://github.com/morgoved/wazuh-helm).
> The dlake distribution tracks upstream and may include additional configuration.

## Kubernetes Audit Webhook Listener

Set `webhookListener.enabled: true` to inject a sidecar into the wazuh-master pod
that collects Kubernetes API server audit logs via the audit webhook mechanism and
forwards them to Wazuh for analysis.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `webhookListener.enabled` | Enable the webhook listener sidecar | `false` |
| `webhookListener.service.port` | Service port exposed to the K8s API server | `443` |
| `webhookListener.service.containerPort` | Port the sidecar listens on (non-privileged) | `8080` |
| `webhookListener.service.type` | Kubernetes Service type (`ClusterIP` or `LoadBalancer`) | `ClusterIP` |
| `webhookListener.service.annotations` | Extra annotations for the Service | `{}` |
| `webhookListener.service.loadBalancerSourceRanges` | Restrict LoadBalancer ingress to these source CIDRs (type=LoadBalancer only) | `[]` |
| `webhookListener.sourceCIDRs` | Source CIDRs of external K8s API servers; adds `fromCIDR` CiliumNetworkPolicy rule | `[]` |
| `webhookListener.tls.existingSecret` | Pre-existing TLS Secret name (skips cert-manager Certificate) | `""` |
| `webhookListener.auditPolicy.enabled` | Render reference audit policy ConfigMap | `false` |
| `webhookListener.resources` | Resource requests/limits for the sidecar | see values.yaml |
| `webhookListener.livenessProbe` | Liveness probe config | `{}` |
| `webhookListener.readinessProbe` | Readiness probe config | `{}` |
| `webhookListener.extraEnvVars` | Extra environment variables for the sidecar | `[]` |
| `webhookListener.podAnnotations` | Extra annotations for the master pod | `{}` |

**TLS requirement:** The K8s API server requires HTTPS. You must either set
`certificates.enabled: true` (uses chart cert-manager issuer) or provide a
pre-existing Secret via `webhookListener.tls.existingSecret`.

**API server configuration:** After deploying, configure the API server with
`--audit-webhook-config-file` pointing to a kubeconfig whose server URL is
`https://<release>-webhook-listener.<namespace>.svc.cluster.local`. See NOTES.txt
output after `helm install` for the exact setup steps.

**Multi-cluster setup:** To receive audit events from external clusters, set
`webhookListener.service.type: LoadBalancer` and list the source CIDRs of their
API servers under `webhookListener.sourceCIDRs`. This adds a `fromCIDR`
CiliumNetworkPolicy ingress rule alongside the default `fromEntities: [host, remote-node]`
rule for the local cluster. Point each external cluster's `--audit-webhook-config-file`
at the LoadBalancer's external IP/hostname on port 443.

