# wazuh

![Version: 2.7.4](https://img.shields.io/badge/Version-2.7.4-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 4.14.7](https://img.shields.io/badge/AppVersion-4.14.7-informational?style=flat-square)

Wazuh is a free and open source security platform that unifies XDR and SIEM protection for endpoints and cloud workloads.

> **Upstream:** This chart is maintained at [clyso-dr/wazuh-helm](https://github.com/clyso-dr/wazuh-helm),
> forked from [morgoved/wazuh-helm](https://github.com/morgoved/wazuh-helm).
> The dlake distribution tracks upstream and may include additional configuration.

**Homepage:** <https://wazuh.com/>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Morgoved | <morgyes@gmail.com> | <https://github.com/morgoved> |
| Kaslie | <jinyi_lie@yahoo.com> | <https://github.com/Kaslie> |
| Dani | <andre.gomes@promptlyhealth.com> | <https://github.com/Ca-moes> |
| TrueDru |  | <https://github.com/TrueDru> |
| 71g3pf4c3 |  | <https://github.com/71g3pf4c3> |
| ShorMario |  | <https://github.com/ShorMario> |
| dlake |  | <https://github.com/dlake-io> |
## Source Code

* <https://github.com/clyso-dr/wazuh-helm>
* <https://github.com/morgoved/wazuh-helm>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://charts.jetstack.io | cert-manager | 1.19.3 |

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
    smtpServer: "relay.example.net"
    emailFrom: "wazuh@example.net"
    emailTo:
      - "foo@example.net"
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

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| agent.affinity | object | `{}` |  |
| agent.annotations | object | `{}` |  |
| agent.apiCred.existingSecret | string | `""` |  |
| agent.apiCred.password | string | `"MyS3cr37P450r.*-"` |  |
| agent.apiCred.username | string | `"wazuh-wui"` |  |
| agent.debug.enabled | bool | `false` |  |
| agent.debug.level | int | `1` |  |
| agent.debug.modules[0] | string | `"agent"` |  |
| agent.debug.modules[1] | string | `"wazuh_modules"` |  |
| agent.dnsConfig | object | `{}` |  |
| agent.dnsPolicy | string | `""` |  |
| agent.enabled | bool | `true` |  |
| agent.extraContainers | list | `[]` |  |
| agent.extraPodLabels | object | `{}` |  |
| agent.extraSpec.container | object | `{}` |  |
| agent.extraSpec.daemonSet | object | `{}` |  |
| agent.extraSpec.pod | object | `{}` |  |
| agent.images.pullPolicy | string | `"IfNotPresent"` |  |
| agent.images.repository | string | `"kinseii/wazuh-agent"` |  |
| agent.images.tag | string | `"4.14.7"` |  |
| agent.joinManager.agentsEvents | string | `"1514"` |  |
| agent.joinManager.apiPort | string | `"55000"` |  |
| agent.joinManager.managerHost | string | `""` |  |
| agent.joinManager.scheme | string | `"https"` |  |
| agent.joinManager.wazuh.group | string | `"default"` |  |
| agent.joinManager.workerHost | string | `""` |  |
| agent.labels | object | `{}` |  |
| agent.livenessProbe | object | `{}` |  |
| agent.namePrefix | string | `""` |  |
| agent.nodeSelector | object | `{}` |  |
| agent.podAnnotations | object | `{}` |  |
| agent.podSecurityContext | object | `{}` |  |
| agent.resources.limits.cpu | string | `"100m"` |  |
| agent.resources.limits.memory | string | `"128Mi"` |  |
| agent.resources.requests.cpu | string | `"50m"` |  |
| agent.resources.requests.memory | string | `"64Mi"` |  |
| agent.securityContext.privileged | bool | `true` |  |
| agent.service.annotations | object | `{}` |  |
| agent.service.port | int | `5000` |  |
| agent.service.type | string | `"ClusterIP"` |  |
| agent.serviceAccount.annotations | object | `{}` |  |
| agent.serviceAccount.create | bool | `false` |  |
| agent.serviceAccount.name | string | `"wazuh-agent"` |  |
| agent.tolerations | list | `[]` |  |
| agent.volumeMounts[0].mountPath | string | `"/var/run"` |  |
| agent.volumeMounts[0].name | string | `"var-run"` |  |
| agent.volumeMounts[1].mountPath | string | `"/host/dev"` |  |
| agent.volumeMounts[1].name | string | `"dev"` |  |
| agent.volumeMounts[2].mountPath | string | `"/host/sys"` |  |
| agent.volumeMounts[2].name | string | `"sys"` |  |
| agent.volumeMounts[2].readOnly | bool | `true` |  |
| agent.volumeMounts[3].mountPath | string | `"/host/proc"` |  |
| agent.volumeMounts[3].name | string | `"proc"` |  |
| agent.volumeMounts[3].readOnly | bool | `true` |  |
| agent.volumeMounts[4].mountPath | string | `"/host/etc"` |  |
| agent.volumeMounts[4].name | string | `"etc"` |  |
| agent.volumeMounts[4].readOnly | bool | `true` |  |
| agent.volumeMounts[5].mountPath | string | `"/host/boot"` |  |
| agent.volumeMounts[5].name | string | `"boot"` |  |
| agent.volumeMounts[5].readOnly | bool | `true` |  |
| agent.volumeMounts[6].mountPath | string | `"/host/usr"` |  |
| agent.volumeMounts[6].name | string | `"usr"` |  |
| agent.volumeMounts[6].readOnly | bool | `true` |  |
| agent.volumeMounts[7].mountPath | string | `"/host/lib/modules"` |  |
| agent.volumeMounts[7].name | string | `"modules"` |  |
| agent.volumeMounts[7].readOnly | bool | `true` |  |
| agent.volumeMounts[8].mountPath | string | `"/host/var/log"` |  |
| agent.volumeMounts[8].name | string | `"log"` |  |
| agent.volumeMounts[8].readOnly | bool | `true` |  |
| agent.volumes[0].hostPath.path | string | `"/var/run"` |  |
| agent.volumes[0].name | string | `"var-run"` |  |
| agent.volumes[1].hostPath.path | string | `"/dev"` |  |
| agent.volumes[1].name | string | `"dev"` |  |
| agent.volumes[2].hostPath.path | string | `"/sys"` |  |
| agent.volumes[2].name | string | `"sys"` |  |
| agent.volumes[3].hostPath.path | string | `"/proc"` |  |
| agent.volumes[3].name | string | `"proc"` |  |
| agent.volumes[4].hostPath.path | string | `"/etc"` |  |
| agent.volumes[4].name | string | `"etc"` |  |
| agent.volumes[5].hostPath.path | string | `"/boot"` |  |
| agent.volumes[5].name | string | `"boot"` |  |
| agent.volumes[6].hostPath.path | string | `"/usr"` |  |
| agent.volumes[6].name | string | `"usr"` |  |
| agent.volumes[7].hostPath.path | string | `"/lib/modules"` |  |
| agent.volumes[7].name | string | `"modules"` |  |
| agent.volumes[8].hostPath.path | string | `"/var/log"` |  |
| agent.volumes[8].name | string | `"log"` |  |
| autoreload.enabled | bool | `false` |  |
| cert-manager.enabled | bool | `false` |  |
| certificates.duration | string | `"2160h"` |  |
| certificates.enabled | bool | `true` |  |
| certificates.issuer.name | string | `nil` |  |
| certificates.issuer.type | string | `"issuer"` |  |
| certificates.renewBefore | string | `"360h"` |  |
| certificates.requestPolicy.enabled | bool | `false` |  |
| certificates.subject.country | string | `"US"` |  |
| certificates.subject.locality | string | `"California"` |  |
| certificates.subject.organization | string | `"Company"` |  |
| dashboard.additionalEnv | list | `[]` |  |
| dashboard.affinity | object | `{}` |  |
| dashboard.annotations | object | `{}` |  |
| dashboard.basicAuth.challenge | bool | `true` |  |
| dashboard.basicAuth.enabled | bool | `true` |  |
| dashboard.basicAuth.order | int | `4` |  |
| dashboard.ciliumNetworkPolicy.enabled | bool | `false` |  |
| dashboard.ciliumNetworkPolicy.extraEgresses | list | `[]` |  |
| dashboard.ciliumNetworkPolicy.extraIngresses | list | `[]` |  |
| dashboard.config | string | `"{{ include \"wazuh.dashboard.config\" . }}\n"` |  |
| dashboard.cred.existingSecret | string | `""` |  |
| dashboard.cred.password | string | `"kibanaserver"` |  |
| dashboard.cred.passwordHash | string | `"$2a$12$7NCZ.l9ntPhou5zNjZIU4uqXNNWMF7SyF6Y6mcjhHTB6Z1eQubHC."` |  |
| dashboard.cred.username | string | `"kibanaserver"` |  |
| dashboard.dnsConfig | object | `{}` |  |
| dashboard.dnsPolicy | string | `""` |  |
| dashboard.enable_ssl | bool | `false` |  |
| dashboard.enabled | bool | `true` |  |
| dashboard.extraPodLabels | object | `{}` |  |
| dashboard.extraSpec.container | object | `{}` |  |
| dashboard.extraSpec.deployment | object | `{}` |  |
| dashboard.extraSpec.pod | object | `{}` |  |
| dashboard.images.pullPolicy | string | `"IfNotPresent"` |  |
| dashboard.images.repository | string | `"wazuh/wazuh-dashboard"` |  |
| dashboard.images.tag | string | `"4.14.7"` |  |
| dashboard.images.updateStrategy | string | `"OnDelete"` |  |
| dashboard.ingress.annotations | object | `{}` |  |
| dashboard.ingress.className | string | `""` |  |
| dashboard.ingress.enabled | bool | `false` |  |
| dashboard.ingress.host | string | `"wazuh.example.com"` |  |
| dashboard.ingress.tls | list | `[]` |  |
| dashboard.livenessProbe.failureThreshold | int | `10` |  |
| dashboard.livenessProbe.httpGet.path | string | `"/api/status"` |  |
| dashboard.livenessProbe.httpGet.port | int | `5601` |  |
| dashboard.livenessProbe.initialDelaySeconds | int | `10` |  |
| dashboard.livenessProbe.periodSeconds | int | `20` |  |
| dashboard.livenessProbe.successThreshold | int | `1` |  |
| dashboard.livenessProbe.timeoutSeconds | int | `5` |  |
| dashboard.networkPolicy.enabled | bool | `true` |  |
| dashboard.networkPolicy.extraEgresses | list | `[]` |  |
| dashboard.networkPolicy.extraIngresses | list | `[]` |  |
| dashboard.nodeSelector | object | `{}` |  |
| dashboard.pdb.enabled | bool | `false` |  |
| dashboard.pdb.maxUnavailable | int | `1` |  |
| dashboard.readinessProbe.failureThreshold | int | `10` |  |
| dashboard.readinessProbe.httpGet.path | string | `"/api/status"` |  |
| dashboard.readinessProbe.httpGet.port | int | `5601` |  |
| dashboard.readinessProbe.initialDelaySeconds | int | `10` |  |
| dashboard.readinessProbe.periodSeconds | int | `20` |  |
| dashboard.readinessProbe.successThreshold | int | `1` |  |
| dashboard.readinessProbe.timeoutSeconds | int | `5` |  |
| dashboard.replicas | int | `1` |  |
| dashboard.resources.limits.cpu | string | `"1000m"` |  |
| dashboard.resources.limits.memory | string | `"1Gi"` |  |
| dashboard.resources.requests.cpu | string | `"500m"` |  |
| dashboard.resources.requests.memory | string | `"512Mi"` |  |
| dashboard.securityContext | object | `{}` |  |
| dashboard.server.extraConf | object | `{}` |  |
| dashboard.service.annotations | object | `{}` |  |
| dashboard.service.httpPort | int | `5601` |  |
| dashboard.service.type | string | `"ClusterIP"` |  |
| dashboard.serviceAccount.annotations | object | `{}` |  |
| dashboard.serviceAccount.create | bool | `false` |  |
| dashboard.serviceAccount.name | string | `"wazuh-dashboard"` |  |
| dashboard.sso.oidc.baseRedirectUrl | string | `""` |  |
| dashboard.sso.oidc.clientIdKey | string | `"OPENSEARCH_OIDC_CLIENT_ID"` |  |
| dashboard.sso.oidc.clientSecretKey | string | `"OPENSEARCH_OIDC_CLIENT_SECRET"` |  |
| dashboard.sso.oidc.config.rolesKey | string | `"roles"` |  |
| dashboard.sso.oidc.config.subjectKey | string | `"preferred_username"` |  |
| dashboard.sso.oidc.customizeLoginButton.enabled | bool | `false` |  |
| dashboard.sso.oidc.customizeLoginButton.imageUrl | string | `""` |  |
| dashboard.sso.oidc.customizeLoginButton.showImage | bool | `false` |  |
| dashboard.sso.oidc.customizeLoginButton.text | string | `"Log In with Single sign-on (OIDC)"` |  |
| dashboard.sso.oidc.enabled | bool | `false` |  |
| dashboard.sso.oidc.existingSecret | string | `""` |  |
| dashboard.sso.oidc.extraRoleMappings | object | `{}` |  |
| dashboard.sso.oidc.idp.enableSSL | bool | `false` |  |
| dashboard.sso.oidc.idp.pemtrustedcasContent | string | `"-----BEGIN CERTIFICATE-----\n-----END CERTIFICATE-----"` |  |
| dashboard.sso.oidc.idp.pemtrustedcasFilePath | string | `""` |  |
| dashboard.sso.oidc.issuer | string | `""` |  |
| dashboard.sso.oidc.logoutUrl | string | `""` |  |
| dashboard.sso.oidc.order | int | `1` |  |
| dashboard.sso.oidc.primary | bool | `false` |  |
| dashboard.sso.oidc.roleMappings.allAccess.backendRoles | list | `[]` |  |
| dashboard.sso.oidc.roleMappings.kibanaServer.backendRoles | list | `[]` |  |
| dashboard.sso.oidc.roleMappings.kibanaUser.backendRoles | list | `[]` |  |
| dashboard.sso.oidc.scope | string | `"openid profile email address phone"` |  |
| dashboard.sso.oidc.url | string | `""` |  |
| dashboard.sso.saml.config.rolesKey | string | `"Roles"` |  |
| dashboard.sso.saml.enableSSL | bool | `false` |  |
| dashboard.sso.saml.enabled | bool | `false` |  |
| dashboard.sso.saml.exchangeKey | string | `""` |  |
| dashboard.sso.saml.extraRoleMappings | object | `{}` |  |
| dashboard.sso.saml.idpEntityId | string | `""` |  |
| dashboard.sso.saml.kibanaUrl | string | `""` |  |
| dashboard.sso.saml.metadataUrl | string | `""` |  |
| dashboard.sso.saml.order | int | `1` |  |
| dashboard.sso.saml.pemtrustedcasContent | string | `"-----BEGIN CERTIFICATE-----\n-----END CERTIFICATE-----"` |  |
| dashboard.sso.saml.pemtrustedcasFilePath | string | `""` |  |
| dashboard.sso.saml.primary | bool | `false` |  |
| dashboard.sso.saml.roleMappings.allAccess.backendRoles | list | `[]` |  |
| dashboard.sso.saml.roleMappings.kibanaServer.backendRoles | list | `[]` |  |
| dashboard.sso.saml.roleMappings.kibanaUser.backendRoles | list | `[]` |  |
| dashboard.sso.saml.spEntityId | string | `"wazuh-saml"` |  |
| dashboard.tolerations | list | `[]` |  |
| externalIndexer.enabled | bool | `false` |  |
| externalIndexer.host | string | `"https://wazuh-indexer.example.com"` |  |
| externalIndexer.port | int | `9200` |  |
| fullnameOverride | string | `nil` |  |
| global.dualStack.enabled | bool | `false` |  |
| global.dualStack.ipFamilies | list | `[]` |  |
| global.dualStack.ipFamilyPolicy | string | `""` |  |
| indexer.additionalConfigs | object | `{}` |  |
| indexer.additionalEnv | list | `[]` |  |
| indexer.additionalVolumeMounts | list | `[]` |  |
| indexer.additionalVolumes | list | `[]` |  |
| indexer.affinity | object | `{}` |  |
| indexer.annotations | object | `{}` |  |
| indexer.ciliumNetworkPolicy.enabled | bool | `false` |  |
| indexer.ciliumNetworkPolicy.extraEgresses | list | `[]` |  |
| indexer.ciliumNetworkPolicy.extraIngresses | list | `[]` |  |
| indexer.config.internalUsers | string | `"{{ include \"wazuh.indexer.internalUsers\" . }}"` |  |
| indexer.config.nodesDn | string | `"{{ include \"wazuh.indexer.nodes_dn\" . }}"` |  |
| indexer.config.opensearch | string | `"{{ include \"wazuh.indexer.opensearchConfig\" . }}"` |  |
| indexer.config.roles | string | `"{{ include \"wazuh.indexer.roles\" . }}"` |  |
| indexer.config.rolesMapping | string | `"{{ include \"wazuh.indexer.rolesMapping\" . }}"` |  |
| indexer.config.securityConfig | string | `"{{ include \"wazuh.indexer.securityConfig\" . }}"` |  |
| indexer.config.tenants | string | `"{{ include \"wazuh.indexer.tenants\" . }}"` |  |
| indexer.config.whitelist | string | `"{{ include \"wazuh.indexer.whitelist\" . }}"` |  |
| indexer.cred.existingSecret | string | `""` |  |
| indexer.cred.password | string | `"WazuhSecretPassword"` |  |
| indexer.cred.passwordHash | string | `"$2a$12$zGWIT7wkPKT/zww3bmMyp.KuWXH4RzgxiB91Q8NGFcqpyPy.R2Rcq"` |  |
| indexer.dnsConfig | object | `{}` |  |
| indexer.dnsPolicy | string | `""` |  |
| indexer.enabled | bool | `true` |  |
| indexer.env.CLUSTER_NAME | string | `"wazuh"` |  |
| indexer.env.DISABLE_INSTALL_DEMO_CONFIG | string | `"true"` |  |
| indexer.env.NETWORK_HOST | string | `"0.0.0.0"` |  |
| indexer.env.OPENSEARCH_JAVA_OPTS | string | `"-Xms1g -Xmx1g -Dlog4j2.formatMsgNoLookups=true"` |  |
| indexer.extraPodLabels | object | `{}` |  |
| indexer.extraSpec.container | object | `{}` |  |
| indexer.extraSpec.pod | object | `{}` |  |
| indexer.extraSpec.statefulSet | object | `{}` |  |
| indexer.images.imagePullSecrets.enabled | bool | `false` |  |
| indexer.images.imagePullSecrets.secret | object | `{}` |  |
| indexer.images.pullPolicy | string | `"IfNotPresent"` |  |
| indexer.images.repository | string | `"wazuh/wazuh-indexer"` |  |
| indexer.images.tag | string | `"4.14.7"` |  |
| indexer.initContainers | list | `[]` |  |
| indexer.job.annotations | object | `{}` |  |
| indexer.job.resources | object | `{}` |  |
| indexer.ldap.authz.bindDn | string | `nil` |  |
| indexer.ldap.authz.bindPasswordKey | string | `"password"` |  |
| indexer.ldap.authz.enabled | bool | `false` |  |
| indexer.ldap.authz.existingSecret | string | `""` |  |
| indexer.ldap.authz.hosts | list | `[]` |  |
| indexer.ldap.authz.resolveNestedRoles | bool | `true` |  |
| indexer.ldap.authz.rolebase | string | `"ou=groups,dc=example,dc=com"` |  |
| indexer.ldap.authz.rolename | string | `"cn"` |  |
| indexer.ldap.authz.rolesearch | string | `"(member={0})"` |  |
| indexer.ldap.authz.userbase | string | `"ou=people,dc=example,dc=com"` |  |
| indexer.ldap.authz.userroleattribute | string | `nil` |  |
| indexer.ldap.authz.userrolename | string | `"disabled"` |  |
| indexer.ldap.authz.usersearch | string | `"(uid={0})"` |  |
| indexer.ldap.bindDn | string | `nil` |  |
| indexer.ldap.bindPasswordKey | string | `"password"` |  |
| indexer.ldap.enableSSL | bool | `false` |  |
| indexer.ldap.enableSSLClientAuth | bool | `false` |  |
| indexer.ldap.enableStartTLS | bool | `false` |  |
| indexer.ldap.enabled | bool | `false` |  |
| indexer.ldap.existingSecret | string | `""` |  |
| indexer.ldap.extraRoleMappings | object | `{}` |  |
| indexer.ldap.hosts[0] | string | `"localhost:389"` |  |
| indexer.ldap.order | int | `5` |  |
| indexer.ldap.roleMappings.allAccess.backendRoles | list | `[]` |  |
| indexer.ldap.roleMappings.kibanaServer.backendRoles | list | `[]` |  |
| indexer.ldap.roleMappings.kibanaUser.backendRoles | list | `[]` |  |
| indexer.ldap.roleMappings.manageSnapshots.backendRoles | list | `[]` |  |
| indexer.ldap.roleMappings.manageWazuhIndex.backendRoles | list | `[]` |  |
| indexer.ldap.roleMappings.readall.backendRoles | list | `[]` |  |
| indexer.ldap.userbase | string | `"ou=people,dc=example,dc=com"` |  |
| indexer.ldap.usernameAttribute | string | `nil` |  |
| indexer.ldap.usersearch | string | `"(sAMAccountName={0})"` |  |
| indexer.ldap.verifyHostnames | bool | `true` |  |
| indexer.livenessProbe.failureThreshold | int | `10` |  |
| indexer.livenessProbe.initialDelaySeconds | int | `10` |  |
| indexer.livenessProbe.periodSeconds | int | `20` |  |
| indexer.livenessProbe.successThreshold | int | `1` |  |
| indexer.livenessProbe.tcpSocket.port | int | `9200` |  |
| indexer.livenessProbe.timeoutSeconds | int | `5` |  |
| indexer.networkPolicy.enabled | bool | `true` |  |
| indexer.networkPolicy.extraEgresses | list | `[]` |  |
| indexer.networkPolicy.extraIngresses | list | `[]` |  |
| indexer.nodeSelector | object | `{}` |  |
| indexer.pdb.enabled | bool | `true` |  |
| indexer.pdb.maxUnavailable | int | `1` |  |
| indexer.pvc.extraLabels | object | `{}` |  |
| indexer.readinessProbe.failureThreshold | int | `10` |  |
| indexer.readinessProbe.initialDelaySeconds | int | `10` |  |
| indexer.readinessProbe.periodSeconds | int | `20` |  |
| indexer.readinessProbe.successThreshold | int | `1` |  |
| indexer.readinessProbe.tcpSocket.port | int | `9200` |  |
| indexer.readinessProbe.timeoutSeconds | int | `5` |  |
| indexer.replicas | int | `3` |  |
| indexer.resources.limits.cpu | string | `"1000m"` |  |
| indexer.resources.limits.memory | string | `"2Gi"` |  |
| indexer.resources.requests.cpu | string | `"500m"` |  |
| indexer.resources.requests.memory | string | `"1Gi"` |  |
| indexer.securityContext.fsGroup | int | `1000` |  |
| indexer.service.annotations | object | `{}` |  |
| indexer.service.httpPort | int | `9200` |  |
| indexer.service.metrics | int | `9600` |  |
| indexer.service.nodes | int | `9300` |  |
| indexer.service.type | string | `"ClusterIP"` |  |
| indexer.serviceAccount.annotations | object | `{}` |  |
| indexer.serviceAccount.create | bool | `false` |  |
| indexer.serviceAccount.name | string | `"wazuh-indexer"` |  |
| indexer.snapshot.enabled | bool | `false` |  |
| indexer.snapshot.fs.accessModes[0] | string | `"ReadWriteMany"` |  |
| indexer.snapshot.fs.existingClaim | string | `""` |  |
| indexer.snapshot.fs.path | string | `"/mnt/snapshots"` |  |
| indexer.snapshot.fs.storageClass | string | `""` |  |
| indexer.snapshot.fs.storageSize | string | `"50Gi"` |  |
| indexer.storageClass | string | `nil` |  |
| indexer.storageSize | string | `"50Gi"` |  |
| indexer.sysctlImage.enabled | bool | `false` |  |
| indexer.sysctlImage.images.repository | string | `"bitnamilegacy/os-shell"` |  |
| indexer.sysctlImage.images.tag | string | `"12-debian-12-r43"` |  |
| indexer.tolerations | list | `[]` |  |
| indexer.updateStrategy | string | `"RollingUpdate"` |  |
| nameOverride | string | `nil` |  |
| wazuh.agentGroupConf[0].agent | string | `"<agent_config>\n  <localfile>\n    <location>journald</location>\n    <log_format>journald</log_format>\n  </localfile>\n  <localfile>\n    <location>/var/log/falco.log</location>\n    <log_format>json</log_format>\n  </localfile>\n  <wodle name=\"docker-listener\">\n    <interval>10m</interval>\n    <attempts>5</attempts>\n    <run_on_start>no</run_on_start>\n    <disabled>no</disabled>\n  </wodle>\n</agent_config>\n"` |  |
| wazuh.agentGroupConf[0].name | string | `"example"` |  |
| wazuh.apiCred.existingSecret | string | `""` |  |
| wazuh.apiCred.password | string | `"MyS3cr37P450r.*-"` |  |
| wazuh.apiCred.username | string | `"wazuh-wui"` |  |
| wazuh.authd.enabled | bool | `true` |  |
| wazuh.authd.existingSecret | string | `""` |  |
| wazuh.authd.pass | string | `"password"` |  |
| wazuh.emailNotification.alertLevel | int | `12` |  |
| wazuh.emailNotification.emailFrom | string | `"ossecm@example.wazuh.com"` |  |
| wazuh.emailNotification.emailTo[0] | string | `"recipient@example.wazuh.com"` |  |
| wazuh.emailNotification.enabled | bool | `false` |  |
| wazuh.emailNotification.logSource | string | `"alerts.log"` |  |
| wazuh.emailNotification.maxPerHour | int | `12` |  |
| wazuh.emailNotification.smtpServer | string | `"smtp.example.wazuh.com"` |  |
| wazuh.enabled | bool | `true` |  |
| wazuh.env.FILEBEAT_SSL_VERIFICATION_MODE | string | `"full"` |  |
| wazuh.extraInitContainers | list | `[]` |  |
| wazuh.fixPermissions.enabled | bool | `true` |  |
| wazuh.fixPermissions.gid | int | `999` |  |
| wazuh.fixPermissions.image | string | `"alpine:3"` |  |
| wazuh.fixPermissions.uid | int | `999` |  |
| wazuh.images.imagePullSecrets.enabled | bool | `false` |  |
| wazuh.images.imagePullSecrets.secret | object | `{}` |  |
| wazuh.images.pullPolicy | string | `"IfNotPresent"` |  |
| wazuh.images.repository | string | `"wazuh/wazuh-manager"` |  |
| wazuh.images.tag | string | `"4.14.7"` |  |
| wazuh.initContainer.image | string | `"alpine"` |  |
| wazuh.initContainer.resources.limits.cpu | string | `"1000m"` |  |
| wazuh.initContainer.resources.limits.memory | string | `"1Gi"` |  |
| wazuh.initContainer.resources.requests.cpu | string | `"250m"` |  |
| wazuh.initContainer.resources.requests.memory | string | `"512Mi"` |  |
| wazuh.internalOptions | string | `"{{ include \"wazuh.internalOptions\" . }}\n"` |  |
| wazuh.key | string | `"c98b62a9b6169ac5f67dae55ae4a9088"` |  |
| wazuh.loadBalancer.annotations | object | `{}` |  |
| wazuh.loadBalancer.enabled | bool | `false` |  |
| wazuh.loadBalancer.sourceCIDRs[0] | string | `"0.0.0.0/0"` |  |
| wazuh.localDecoder | string | `"{{ include \"wazuh.localDecoder\" . }}\n"` |  |
| wazuh.localRules | string | `"<!-- Local rules -->\n<!-- Copyright (C) 2015, Wazuh Inc. -->\n<group name=\"local,\">\n</group>\n"` |  |
| wazuh.master.additionalEnv | list | `[]` |  |
| wazuh.master.additionalVolumeMounts | list | `[]` |  |
| wazuh.master.additionalVolumes | list | `[]` |  |
| wazuh.master.affinity | object | `{}` |  |
| wazuh.master.annotations | object | `{}` |  |
| wazuh.master.ciliumNetworkPolicy.enabled | bool | `false` |  |
| wazuh.master.ciliumNetworkPolicy.extraEgresses | list | `[]` |  |
| wazuh.master.ciliumNetworkPolicy.extraIngresses | list | `[]` |  |
| wazuh.master.conf | string | `"{{ include \"wazuh.master.conf\" . }}\n"` |  |
| wazuh.master.dnsConfig | object | `{}` |  |
| wazuh.master.dnsPolicy | string | `""` |  |
| wazuh.master.enabled | bool | `true` |  |
| wazuh.master.extraConf | string | `""` |  |
| wazuh.master.extraPodLabels | object | `{}` |  |
| wazuh.master.extraSpec.container | object | `{}` |  |
| wazuh.master.extraSpec.pod | object | `{}` |  |
| wazuh.master.extraSpec.statefulSet | object | `{}` |  |
| wazuh.master.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| wazuh.master.livenessProbe | object | `{}` |  |
| wazuh.master.networkPolicy.enabled | bool | `true` |  |
| wazuh.master.networkPolicy.extraEgresses | list | `[]` |  |
| wazuh.master.networkPolicy.extraIngresses | list | `[]` |  |
| wazuh.master.pvc.extraLabels | object | `{}` |  |
| wazuh.master.readinessProbe | object | `{}` |  |
| wazuh.master.resources.limits.cpu | string | `"1000m"` |  |
| wazuh.master.resources.limits.memory | string | `"1Gi"` |  |
| wazuh.master.resources.requests.cpu | string | `"500m"` |  |
| wazuh.master.resources.requests.memory | string | `"512Mi"` |  |
| wazuh.master.securityContext.capabilities.add[0] | string | `"SYS_CHROOT"` |  |
| wazuh.master.service.annotations | object | `{}` |  |
| wazuh.master.service.ports[0].name | string | `"registration"` |  |
| wazuh.master.service.ports[0].port | int | `1515` |  |
| wazuh.master.service.ports[0].protocol | string | `"TCP"` |  |
| wazuh.master.service.ports[0].targetPort | int | `1515` |  |
| wazuh.master.service.ports[1].name | string | `"api"` |  |
| wazuh.master.service.ports[1].port | int | `55000` |  |
| wazuh.master.service.ports[1].protocol | string | `"TCP"` |  |
| wazuh.master.service.ports[1].targetPort | int | `55000` |  |
| wazuh.master.service.type | string | `"ClusterIP"` |  |
| wazuh.master.storageClass | string | `nil` |  |
| wazuh.master.storageSize | string | `"50Gi"` |  |
| wazuh.master.tolerations | list | `[]` |  |
| wazuh.nodeSelector | object | `{}` |  |
| wazuh.service.annotations | object | `{}` |  |
| wazuh.service.port | int | `1516` |  |
| wazuh.serviceAccount.annotations | object | `{}` |  |
| wazuh.serviceAccount.create | bool | `false` |  |
| wazuh.serviceAccount.name | string | `"wazuh-manager"` |  |
| wazuh.syslog_enable | bool | `true` |  |
| wazuh.worker.additionalEnv | list | `[]` |  |
| wazuh.worker.additionalVolumeMounts | list | `[]` |  |
| wazuh.worker.additionalVolumes | list | `[]` |  |
| wazuh.worker.affinity | object | `{}` |  |
| wazuh.worker.annotations | object | `{}` |  |
| wazuh.worker.ciliumNetworkPolicy.enabled | bool | `false` |  |
| wazuh.worker.ciliumNetworkPolicy.extraEgresses | list | `[]` |  |
| wazuh.worker.ciliumNetworkPolicy.extraIngresses | list | `[]` |  |
| wazuh.worker.conf | string | `"{{ include \"wazuh.worker.conf\" . }}\n"` |  |
| wazuh.worker.dnsConfig | object | `{}` |  |
| wazuh.worker.dnsPolicy | string | `""` |  |
| wazuh.worker.enabled | bool | `true` |  |
| wazuh.worker.extraConf | string | `""` |  |
| wazuh.worker.extraPodLabels | object | `{}` |  |
| wazuh.worker.extraSpec.container | object | `{}` |  |
| wazuh.worker.extraSpec.pod | object | `{}` |  |
| wazuh.worker.extraSpec.statefulSet | object | `{}` |  |
| wazuh.worker.fsGroupChangePolicy | string | `"OnRootMismatch"` |  |
| wazuh.worker.livenessProbe | object | `{}` |  |
| wazuh.worker.networkPolicy.enabled | bool | `true` |  |
| wazuh.worker.networkPolicy.extraEgresses | list | `[]` |  |
| wazuh.worker.networkPolicy.extraIngresses | list | `[]` |  |
| wazuh.worker.pdb.enabled | bool | `true` |  |
| wazuh.worker.pdb.maxUnavailable | int | `1` |  |
| wazuh.worker.podAntiAffinity | string | `"soft"` |  |
| wazuh.worker.podAntiAffinityTopologyKey | string | `"kubernetes.io/hostname"` |  |
| wazuh.worker.pvc.extraLabels | object | `{}` |  |
| wazuh.worker.readinessProbe | object | `{}` |  |
| wazuh.worker.replicas | int | `2` |  |
| wazuh.worker.resources.limits.cpu | string | `"1000m"` |  |
| wazuh.worker.resources.limits.memory | string | `"1Gi"` |  |
| wazuh.worker.resources.requests.cpu | string | `"500m"` |  |
| wazuh.worker.resources.requests.memory | string | `"512Mi"` |  |
| wazuh.worker.securityContext.capabilities.add[0] | string | `"SYS_CHROOT"` |  |
| wazuh.worker.service.annotations | object | `{}` |  |
| wazuh.worker.service.ports[0].name | string | `"agents-events"` |  |
| wazuh.worker.service.ports[0].port | int | `1514` |  |
| wazuh.worker.service.ports[0].protocol | string | `"TCP"` |  |
| wazuh.worker.service.ports[0].targetPort | int | `1514` |  |
| wazuh.worker.service.type | string | `"ClusterIP"` |  |
| wazuh.worker.storageClass | string | `nil` |  |
| wazuh.worker.storageSize | string | `"50Gi"` |  |
| wazuh.worker.tolerations | list | `[]` |  |
| webhookListener.auditPolicy.enabled | bool | `false` |  |
| webhookListener.enabled | bool | `false` |  |
| webhookListener.extraEnvVars | list | `[]` |  |
| webhookListener.livenessProbe | object | `{}` |  |
| webhookListener.podAnnotations | object | `{}` |  |
| webhookListener.readinessProbe | object | `{}` |  |
| webhookListener.resources.limits.cpu | string | `"500m"` |  |
| webhookListener.resources.limits.memory | string | `"256Mi"` |  |
| webhookListener.resources.requests.cpu | string | `"100m"` |  |
| webhookListener.resources.requests.memory | string | `"128Mi"` |  |
| webhookListener.service.annotations | object | `{}` |  |
| webhookListener.service.containerPort | int | `8080` |  |
| webhookListener.service.loadBalancerSourceRanges | list | `[]` |  |
| webhookListener.service.port | int | `443` |  |
| webhookListener.service.type | string | `"ClusterIP"` |  |
| webhookListener.sourceCIDRs | list | `[]` |  |
| webhookListener.tls.existingSecret | string | `""` |  |
----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
