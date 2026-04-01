{{/*
Expand the name of the chart.
*/}}
{{- define "celery.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "celery.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "celery.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "celery.labels" -}}
helm.sh/chart: {{ include "celery.chart" . }}
{{ include "celery.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels (base — used for ServiceAccount, etc.)
*/}}
{{- define "celery.selectorLabels" -}}
app.kubernetes.io/name: {{ include "celery.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Worker selector labels — includes component to distinguish from beat/flower pods
*/}}
{{- define "celery.worker.selectorLabels" -}}
{{ include "celery.selectorLabels" . }}
app.kubernetes.io/component: worker
{{- end }}

{{/*
Beat selector labels
*/}}
{{- define "celery.beat.selectorLabels" -}}
{{ include "celery.selectorLabels" . }}
app.kubernetes.io/component: beat
{{- end }}

{{/*
Flower selector labels
*/}}
{{- define "celery.flower.selectorLabels" -}}
{{ include "celery.selectorLabels" . }}
app.kubernetes.io/component: flower
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "celery.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "celery.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Fully qualified name of the bundled Valkey service.
The official Valkey chart names its service as <release>-valkey.
*/}}
{{- define "celery.valkey.serviceName" -}}
{{- printf "%s-valkey" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Broker environment variables — injected into worker, beat, AND flower containers.
Precedence: existingSecret > valkey.enabled (auto-construct URL) > brokerUrl/resultBackend.
*/}}
{{- define "celery.brokerEnv" -}}
{{- if .Values.celery.existingSecret }}
- name: CELERY_BROKER_URL
  valueFrom:
    secretKeyRef:
      name: {{ .Values.celery.existingSecret }}
      key: {{ .Values.celery.existingSecretBrokerKey }}
- name: CELERY_RESULT_BACKEND
  valueFrom:
    secretKeyRef:
      name: {{ .Values.celery.existingSecret }}
      key: {{ .Values.celery.existingSecretBackendKey }}
{{- else if .Values.valkey.enabled }}
- name: CELERY_BROKER_URL
  value: {{ printf "redis://%s:6379/0" (include "celery.valkey.serviceName" .) | quote }}
- name: CELERY_RESULT_BACKEND
  value: {{ printf "redis://%s:6379/1" (include "celery.valkey.serviceName" .) | quote }}
{{- else }}
- name: CELERY_BROKER_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "celery.fullname" . }}-broker
      key: broker-url
- name: CELERY_RESULT_BACKEND
  valueFrom:
    secretKeyRef:
      name: {{ include "celery.fullname" . }}-broker
      key: result-backend
{{- end }}
{{- end }}
