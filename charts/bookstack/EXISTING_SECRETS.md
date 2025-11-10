# Using Existing Secrets with BookStack Helm Chart

The BookStack Helm chart supports using existing Kubernetes secrets instead of creating new ones. This is useful when you want to manage secrets externally using tools like:

- Sealed Secrets
- External Secrets Operator
- HashiCorp Vault
- SOPS
- Manual secret creation

## Supported Existing Secrets

### 1. Application Key Secret (`app.existingSecret`)

Instead of providing `app.key` in values.yaml, you can reference an existing secret.

**Secret Requirements:**
- Key name: `app-key`
- Value: Base64-encoded Laravel APP_KEY

**Example Secret:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bookstack-app-key
type: Opaque
data:
  app-key: YmFzZTY0OnRlc3RrZXkxMjM=  # base64:testkey123
```

**Usage in values.yaml:**
```yaml
app:
  existingSecret: "bookstack-app-key"
  url: "https://bookstack.example.com"
  # key is ignored when existingSecret is set
```

### 2. External Database Password Secret (`externalDatabase.existingSecret`)

When using an external database, you can provide the password via an existing secret.

**Secret Requirements:**
- Key name: `db-password`
- Value: Base64-encoded database password

**Example Secret:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bookstack-db-credentials
type: Opaque
data:
  db-password: bXlwYXNzd29yZA==  # mypassword
```

**Usage in values.yaml:**
```yaml
mariadb:
  enabled: false

externalDatabase:
  host: "mysql.example.com"
  user: "bookstack"
  database: "bookstack"
  existingSecret: "bookstack-db-credentials"
  # password is ignored when existingSecret is set
```

### 3. External Database TLS Certificate Secret (`externalDatabase.existingTlsSecret`)

For secure database connections using TLS, you can provide the CA certificate via an existing secret.

**Secret Requirements:**
- Key name: `mysql.cert`
- Value: Base64-encoded CA certificate content

**Example Secret:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: bookstack-db-tls
type: Opaque
data:
  mysql.cert: LS0tLS1CRUdJTi...  # Base64-encoded certificate
```

**Usage in values.yaml:**
```yaml
externalDatabase:
  host: "mysql.example.com"
  existingTlsSecret: "bookstack-db-tls"
  # tlsCert is ignored when existingTlsSecret is set
```

## Complete Example with All Existing Secrets

```yaml
# values.yaml
app:
  existingSecret: "bookstack-app-key"
  url: "https://bookstack.example.com"

mariadb:
  enabled: false

externalDatabase:
  host: "mysql.example.com"
  port: 3306
  user: "bookstack"
  database: "bookstack"
  existingSecret: "bookstack-db-credentials"
  existingTlsSecret: "bookstack-db-tls"

ingress:
  enabled: true
  className: nginx
  hosts:
    - bookstack.example.com
```

## Creating Secrets Manually

### Using kubectl

```bash
# Create app key secret
kubectl create secret generic bookstack-app-key \
  --from-literal=app-key='base64:your-generated-key-here'

# Create database password secret
kubectl create secret generic bookstack-db-credentials \
  --from-literal=db-password='your-db-password'

# Create TLS certificate secret from file
kubectl create secret generic bookstack-db-tls \
  --from-file=mysql.cert=/path/to/ca-cert.pem
```

### Using Sealed Secrets

```yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: bookstack-app-key
spec:
  encryptedData:
    app-key: AgBQ7...encrypted...
  template:
    type: Opaque
```

### Using External Secrets Operator

```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: bookstack-app-key
spec:
  secretStoreRef:
    name: vault-backend
    kind: SecretStore
  target:
    name: bookstack-app-key
    creationPolicy: Owner
  data:
    - secretKey: app-key
      remoteRef:
        key: bookstack/app-key
```

## Migration from Inline Secrets

If you're currently using inline secrets in values.yaml, here's how to migrate:

### Step 1: Create the secrets

```bash
# Extract current values
APP_KEY=$(helm get values bookstack -o json | jq -r '.app.key')
DB_PASS=$(helm get values bookstack -o json | jq -r '.externalDatabase.password')

# Create new secrets
kubectl create secret generic bookstack-app-key --from-literal=app-key="$APP_KEY"
kubectl create secret generic bookstack-db-credentials --from-literal=db-password="$DB_PASS"
```

### Step 2: Update values.yaml

```yaml
# Before
app:
  key: "base64:longrandomstring"

externalDatabase:
  password: "mypassword"

# After
app:
  existingSecret: "bookstack-app-key"

externalDatabase:
  existingSecret: "bookstack-db-credentials"
```

### Step 3: Upgrade the release

```bash
helm upgrade bookstack dlake/bookstack -f values.yaml
```

## Troubleshooting

### Secret not found error

```
Error: secrets "bookstack-app-key" not found
```

**Solution:** Ensure the secret exists in the same namespace as the BookStack deployment:

```bash
kubectl get secrets -n <namespace>
kubectl describe secret bookstack-app-key -n <namespace>
```

### Wrong secret key name

If the pod fails to start with environment variable errors, verify the key names:

```bash
kubectl get secret bookstack-app-key -o jsonpath='{.data}' | jq
```

Expected keys:
- `app-key` for app secret
- `db-password` for database secret
- `mysql.cert` for TLS certificate secret

### Secret values not base64 encoded correctly

The secret data must be base64 encoded. Use:

```bash
echo -n "your-secret-value" | base64
```

Note: The `-n` flag prevents adding a newline character.

## Security Best Practices

1. **Never commit secrets to version control**
   - Add `values-secrets.yaml` to `.gitignore`
   - Use tools like git-secrets or gitleaks

2. **Use RBAC to restrict secret access**
   ```yaml
   apiVersion: rbac.authorization.k8s.io/v1
   kind: Role
   rules:
     - apiGroups: [""]
       resources: ["secrets"]
       resourceNames: ["bookstack-app-key", "bookstack-db-credentials"]
       verbs: ["get"]
   ```

3. **Enable encryption at rest**
   - Configure etcd encryption for your Kubernetes cluster

4. **Rotate secrets regularly**
   ```bash
   # Generate new APP_KEY
   docker run --rm solidnerd/bookstack php artisan key:generate --show
   
   # Update secret
   kubectl create secret generic bookstack-app-key \
     --from-literal=app-key='base64:new-key' \
     --dry-run=client -o yaml | kubectl apply -f -
   
   # Restart deployment to pick up new secret
   kubectl rollout restart deployment/bookstack
   ```

5. **Use External Secrets Operator for secret management**
   - Centralize secrets in Vault, AWS Secrets Manager, etc.
   - Automatic rotation and synchronization
   - Audit logging

## Additional Resources

- [Kubernetes Secrets Documentation](https://kubernetes.io/docs/concepts/configuration/secret/)
- [External Secrets Operator](https://external-secrets.io/)
- [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
- [SOPS](https://github.com/mozilla/sops)
