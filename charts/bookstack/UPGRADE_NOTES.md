# BookStack Helm Chart v2.0.0 - Upgrade Notes

## Major Changes

This is a major version upgrade with significant improvements to security, maintainability, and best practices. Please review these changes before upgrading.

## Breaking Changes

### 1. Dependency Management
- **BREAKING**: `requirements.yaml` removed in favor of Chart.yaml dependencies (Helm 3 standard)
- **Action Required**: Run `helm dependency update` after upgrading
- MariaDB dependency updated from 19.x to 20.x

### 2. Labels Modernization
- **BREAKING**: Labels have been modernized to use Kubernetes recommended labels
- Old labels: `app`, `chart`, `release`, `heritage`
- New labels: `app.kubernetes.io/name`, `app.kubernetes.io/instance`, `helm.sh/chart`, etc.
- **Impact**: Existing deployments will recreate pods due to label changes

### 3. Security Contexts
- **NEW**: Container-level security context added with restrictive defaults
- Runs as non-root user (UID 33)
- Drops all capabilities
- **Impact**: May affect deployments that previously relied on root access

### 4. Health Probes
- **BREAKING**: Health probes are now fully configurable in values.yaml
- Added startup probe for better initialization handling
- **Action Required**: Review and adjust probe settings if needed

## New Features

### Security Enhancements
- LDAP passwords now stored in Kubernetes Secrets (previously plain text environment variables)
- Container security context with principle of least privilege
- Pod security context improvements
- Network Policy support for network segmentation

### Operational Improvements
- PodDisruptionBudget support for high availability
- Configurable health probes (liveness, readiness, startup)
- Support for pod and deployment annotations
- Service annotations support
- Image pull secrets properly applied

### Configuration Improvements
- Ingress className is now optional (better backward compatibility)
- Enhanced environment variable injection with `extraEnv` and `extraEnvFrom`
- Image tag properly defaults to Chart appVersion
- PVC annotations support
- Existing PVC support for both uploads and storage volumes

### Documentation
- Complete README.md generated with helm-docs
- Enhanced NOTES.txt with detailed post-installation instructions
- Comprehensive value documentation with helm-docs comments
- Better .helmignore patterns

## Upgrade Path

### From 1.x to 2.0.0

1. **Backup your data** before upgrading (uploads, storage, database)

2. **Review new values.yaml structure**:
   ```bash
   helm show values dlake/bookstack --version 2.0.0 > new-values.yaml
   ```

3. **Update your custom values** with new options:
   - Review security contexts
   - Configure health probes if needed
   - Consider enabling PodDisruptionBudget for production
   - Review NetworkPolicy settings

4. **Plan for pod recreation** due to label changes:
   ```yaml
   # Consider using Recreate strategy during upgrade
   deploymentStrategy:
     type: Recreate
   ```

5. **Perform the upgrade**:
   ```bash
   helm dependency update charts/bookstack
   helm upgrade bookstack dlake/bookstack --version 2.0.0 -f your-values.yaml
   ```

6. **Verify the deployment**:
   ```bash
   kubectl get pods -l app.kubernetes.io/name=bookstack
   kubectl logs -l app.kubernetes.io/name=bookstack
   ```

## Configuration Changes

### Security Context (New)
```yaml
podSecurityContext:
  fsGroup: 33
  runAsNonRoot: true
  runAsUser: 33

containerSecurityContext:
  allowPrivilegeEscalation: false
  runAsNonRoot: true
  runAsUser: 33
  capabilities:
    drop:
      - ALL
  readOnlyRootFilesystem: false
```

### Health Probes (Now Configurable)
```yaml
livenessProbe:
  httpGet:
    path: /status
    port: http
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 6

readinessProbe:
  httpGet:
    path: /status
    port: http
  initialDelaySeconds: 15
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 3

startupProbe:
  httpGet:
    path: /status
    port: http
  initialDelaySeconds: 0
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 30
```

### LDAP Configuration (Security Improvement)
LDAP passwords are now stored in Kubernetes Secrets automatically. No changes needed to your values.yaml, but the implementation is more secure.

### Network Policy (Optional New Feature)
```yaml
networkPolicy:
  enabled: true
  ingress:
    podSelector: {}
  egress:
    extraRules: []
```

### Pod Disruption Budget (Optional New Feature)
```yaml
podDisruptionBudget:
  enabled: true
  minAvailable: 1
```

## Rollback

If you need to rollback:

```bash
helm rollback bookstack
```

Note: Due to label changes, rollback may not be seamless. Consider keeping a backup of your 1.x deployment.

## Support

For issues or questions:
- GitHub Issues: https://github.com/dlake-io/helm-charts/issues
- BookStack Documentation: https://www.bookstackapp.com/docs/
