{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "bookstack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "bookstack.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "bookstack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "bookstack.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "bookstack.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "bookstack.mariadb.fullname" -}}
{{- printf "%s-%s" .Release.Name "mariadb" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fully qualified name for the Valkey subchart.
The Bitnami Valkey chart exposes its primary service as <fullname>-primary.
*/}}
{{- define "bookstack.valkey.fullname" -}}
{{- printf "%s-%s" .Release.Name "valkey" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
REDIS_SERVERS connection string for BookStack (format: host:port:database).
Returns the internal Valkey primary service when valkey.enabled, otherwise
falls back to externalValkey settings.
*/}}
{{- define "bookstack.redisServers" -}}
{{- if .Values.valkey.enabled -}}
{{- printf "%s-primary:6379:0" (include "bookstack.valkey.fullname" .) -}}
{{- else -}}
{{- printf "%s:%d:%d" .Values.externalValkey.host (int .Values.externalValkey.port) (int .Values.externalValkey.database) -}}
{{- end -}}
{{- end -}}

{{/*
Returns a non-empty string when a Redis-compatible session/cache backend is
configured (either the bundled Valkey subchart or an external host).
Use as: {{- if include "bookstack.redis.enabled" . }}
*/}}
{{- define "bookstack.redis.enabled" -}}
{{- if or .Values.valkey.enabled .Values.externalValkey.host -}}true{{- end -}}
{{- end -}}

{{/*
Returns the Valkey authentication password for embedding in REDIS_SERVERS.
Sources (in priority order):
  1. Helm lookup from operator-supplied existingSecret (must pre-exist in the cluster)
  2. Inline valkey.auth.password value
Returns an empty string when neither is configured.
Note: lookup returns nil during `helm template` (no cluster) — the generated
Secret will contain a placeholder; re-run helm upgrade once the Secret exists.
*/}}
{{- define "bookstack.valkeyPassword" -}}
{{- if .Values.valkey.auth.existingSecret -}}
{{- $s := lookup "v1" "Secret" .Release.Namespace .Values.valkey.auth.existingSecret -}}
{{- if $s -}}
{{- index $s.data .Values.valkey.auth.existingSecretPasswordKey | b64dec -}}
{{- end -}}
{{- else if .Values.valkey.auth.password -}}
{{- .Values.valkey.auth.password -}}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "bookstack.labels" -}}
helm.sh/chart: {{ include "bookstack.chart" . }}
{{ include "bookstack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "bookstack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "bookstack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
