{{/*
───────────────────────────────────────────────────────────────────────────────
  YOUR_INFRA Services Helm Chart — Template Helpers
───────────────────────────────────────────────────────────────────────────────
*/}}

{{/*
Expand the name of the chart.
*/}}
{{- define "YOUR_INFRA-services.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "YOUR_INFRA-services.fullname" -}}
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
Common labels
*/}}
{{- define "YOUR_INFRA-services.labels" -}}
helm.sh/chart: {{ include "YOUR_INFRA-services.name" . }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{/*
Selector labels for a specific service
Usage: {{ include "YOUR_INFRA-services.selectorLabels" (dict "name" .name "root" $) }}
*/}}
{{- define "YOUR_INFRA-services.selectorLabels" -}}
app.kubernetes.io/name: {{ .name }}
app.kubernetes.io/instance: {{ .root.Release.Name }}
{{- end }}
