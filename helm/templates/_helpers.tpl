{{/* vim: set filetype=mustache: */}}
{{/*
Define aerospike.name
*/}}
{{- define "aerospike.name" -}}
{{- default .Chart.Name -}}
{{- end -}}

{{/*
Define aerospike.fullname
*/}}
{{- define "aerospike.fullname" -}}
{{- $name := default .Chart.Name -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Define aerospike.chart
*/}}
{{- define "aerospike.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Define aerospike.labels
*/}}
{{- define "aerospike.labels" -}}
app.kubernetes.io/name: {{ include "aerospike.name" . }}
helm.sh/chart: {{ include "aerospike.chart" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
