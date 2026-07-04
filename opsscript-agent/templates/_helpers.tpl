{{/*
Expand the name of the chart.
*/}}
{{- define "opsscript-agent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "opsscript-agent.fullname" -}}
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
{{- define "opsscript-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "opsscript-agent.labels" -}}
helm.sh/chart: {{ include "opsscript-agent.chart" . }}
{{ include "opsscript-agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "opsscript-agent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "opsscript-agent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "opsscript-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "opsscript-agent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name for cluster-scoped RBAC objects. Includes the release namespace so
two releases in different namespaces of the same cluster don't collide.
*/}}
{{- define "opsscript-agent.clusterRoleName" -}}
{{- printf "%s-%s" (include "opsscript-agent.fullname" .) .Release.Namespace | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Name of the Secret holding the agent credentials: the user-provided one,
or the chart-managed Secret when credentials.agentToken is set.
*/}}
{{- define "opsscript-agent.credentialsSecretName" -}}
{{- if .Values.credentials.existingSecret }}
{{- .Values.credentials.existingSecret }}
{{- else }}
{{- printf "%s-credentials" (include "opsscript-agent.fullname" .) }}
{{- end }}
{{- end }}

{{/*
Fail fast when no credential source is configured.
*/}}
{{- define "opsscript-agent.validateCredentials" -}}
{{- if and (not .Values.credentials.existingSecret) (not .Values.credentials.agentToken) }}
{{- fail "opsscript-agent: set credentials.existingSecret (preferred) or credentials.agentToken. Both AGENT_ID and AGENT_TOKEN are generated in OpsScript > Integrations > Kubernetes Agent." }}
{{- end }}
{{- end }}
