# wazuh

![Version: 2.7.0](https://img.shields.io/badge/Version-2.7.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.14.4](https://img.shields.io/badge/AppVersion-4.14.4-informational?style=flat-square)

Wazuh is a free and open source security platform that unifies XDR and SIEM protection for endpoints and cloud workloads.

> **Upstream:** This chart is maintained at [clyso-dr/wazuh-helm](https://github.com/clyso-dr/wazuh-helm),
> forked from [morgoved/wazuh-helm](https://github.com/morgoved/wazuh-helm).
> The dlake distribution tracks upstream and may include additional configuration.

## PVC Ownership Fix (queue/db permissions)

Set `wazuh.fixPermissions.enabled: true` (default) to inject a `fix-permissions` initContainer
that runs before any Wazuh process and chowns the full PVC tree (`/data/wazuh`) to UID 1000 / GID 101.

This fixes the repeated `wazuh-db: ERROR: Couldn't create SQLite database 'queue/db/global.db'`
caused by kubelet creating subPath directories as `root:root`. Without this fix, wazuh-db cannot
write to `queue/db/` and the manager is effectively blind to agent sync and audit log ingest.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `wazuh.fixPermissions.enabled` | Inject fix-permissions initContainer on every pod start | `true` |
| `wazuh.fixPermissions.image` | Image for the initContainer (needs `sh` and `chown`) | `alpine:3` |
| `wazuh.fixPermissions.uid` | Wazuh process UID — used for `chown` target. Verify with `kubectl exec ... -- id wazuh` | `999` |
| `wazuh.fixPermissions.gid` | Wazuh process GID — used for `chown` target and pod `securityContext.fsGroup` | `999` |
| `wazuh.master.fsGroupChangePolicy` | Pod securityContext fsGroupChangePolicy. Set to `""` on K8s < 1.20 | `OnRootMismatch` |
| `wazuh.worker.fsGroupChangePolicy` | Same for worker pods | `OnRootMismatch` |

**PSA note:** The fix-permissions initContainer runs as `runAsUser: 0` (root). This is incompatible
with PSA `restricted` namespace profiles. Relax the namespace to `baseline` or manage PVC ownership
externally and set `wazuh.fixPermissions.enabled: false`.

**Upgrade note:** Adding an initContainer to an existing StatefulSet triggers a rolling restart
(pods bounce sequentially). Schedule upgrades during a maintenance window for production SIEM deployments.

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

## Email / SMTP Notifications

Configure SMTP email alerts via `wazuh.emailNotification.*`. These values are rendered
directly into the primary `<global>` block in `ossec.conf`, which ensures `wazuh-control`
starts `wazuh-maild` on pod startup.

**Note:** Do not use `wazuh.master.extraConf` for SMTP settings. A second `<global>` block
via `extraConf` is parsed by `analysisd` (alerts get `"mail":true`) but not by `wazuh-control`
(the startup script reads only the first `<email_notification>` tag), so `wazuh-maild` never
starts and no emails are sent.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `wazuh.emailNotification.enabled` | Enable SMTP email alerts (`wazuh-maild` started only when `true`) | `false` |
| `wazuh.emailNotification.smtpServer` | SMTP relay hostname or IP. Must accept unauthenticated connections. | `smtp.example.wazuh.com` |
| `wazuh.emailNotification.emailFrom` | From address in alert emails | `ossecm@example.wazuh.com` |
| `wazuh.emailNotification.emailTo` | List of recipient addresses (supports multiple `<email_to>` entries) | `["recipient@example.wazuh.com"]` |
| `wazuh.emailNotification.maxPerHour` | Maximum emails per hour (rate-limit) | `12` |
| `wazuh.emailNotification.logSource` | Source log file for email alerts | `alerts.log` |
| `wazuh.emailNotification.alertLevel` | Minimum rule level triggering email. Rules with `<options>alert_by_email</options>` bypass this. | `12` |

Example:

```yaml
wazuh:
  emailNotification:
    enabled: true
    smtpServer: "relaycorp.service.consul"
    emailFrom: "wazuh@d-lake.fr"
    emailTo:
      - "tech@d-lake.fr"
    maxPerHour: 12
    logSource: "alerts.log"
    alertLevel: 8
```

After `helm upgrade`, verify `wazuh-maild` is running:

```bash
kubectl exec -n wazuh wazuh-manager-master-0 -- ps aux | grep wazuh-maild
```

## Custom Rules (local_rules.xml)

Set `wazuh.localRules` to inject custom rules into the manager's `local_rules.xml` without
forking the chart. The value is written verbatim to the ConfigMap and mounted at
`/wazuh-config-mount/etc/rules/local_rules.xml` on the master pod.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `wazuh.localRules` | XML content for `local_rules.xml` on the manager | empty `<group>` |

Example — trigger email alert on SSH brute force (requires SMTP configured via `wazuh.master.extraConf`):

```yaml
wazuh:
  localRules: |
    <group name="custom_email_override,">
      <rule id="100200" level="8">
        <if_sid>5758</if_sid>
        <description>SSH brute force detected (email enabled)</description>
        <options>alert_by_email</options>
      </rule>
    </group>
```

Use rule IDs in the `100000–109999` range (reserved for local rules). The `<options>alert_by_email</options>`
directive forces email for this rule regardless of `<email_alert_level>` in the global config.

