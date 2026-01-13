{{/*
Expand the name of the chart.
*/}}
{{- define "deploy-apps.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "deploy-apps.fullname" -}}
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
{{- define "deploy-apps.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "deploy-apps.labels" -}}
helm.sh/chart: {{ include "deploy-apps.chart" . }}
{{ include "deploy-apps.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "deploy-apps.selectorLabels" -}}
app.kubernetes.io/name: {{ include "deploy-apps.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the global service account to use
*/}}
{{- define "deploy-apps.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "deploy-apps.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create app-specific fullname
Usage: {{ include "deploy-apps.app.fullname" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.fullname" -}}
{{- $fullname := include "deploy-apps.fullname" .root -}}
{{- printf "%s-%s" $fullname .app.name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create app-specific labels (for all resources)
Usage: {{ include "deploy-apps.app.labels" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.labels" -}}
{{ include "deploy-apps.labels" .root }}
app.kubernetes.io/component: {{ .app.name }}
deploy-apps/app-name: {{ .app.name }}
deploy-apps/workload-type: {{ .app.type }}
{{- with .app.labels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Create app-specific selector labels
Usage: {{ include "deploy-apps.app.selectorLabels" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.selectorLabels" -}}
{{ include "deploy-apps.selectorLabels" .root }}
app.kubernetes.io/component: {{ .app.name }}
{{- end }}

{{/*
Create app-specific pod labels (includes both app labels and podLabels)
Usage: {{ include "deploy-apps.app.podLabels" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.podLabels" -}}
{{ include "deploy-apps.app.selectorLabels" (dict "root" .root "app" .app) }}
{{- with .app.labels }}
{{ toYaml . }}
{{- end }}
{{- with .app.podLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use for an app
Usage: {{ include "deploy-apps.app.serviceAccountName" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.serviceAccountName" -}}
{{- if .app.serviceAccount }}
{{- if .app.serviceAccount.create }}
{{- default (include "deploy-apps.app.fullname" (dict "root" .root "app" .app)) .app.serviceAccount.name }}
{{- else if .root.Values.serviceAccount.create }}
{{- include "deploy-apps.serviceAccountName" .root }}
{{- else }}
{{- default "default" .app.serviceAccount.name }}
{{- end }}
{{- else if .root.Values.serviceAccount.create }}
{{- include "deploy-apps.serviceAccountName" .root }}
{{- else }}
{{- "default" }}
{{- end }}
{{- end }}

{{/*
Get image for an app (with fallback to global)
Usage: {{ include "deploy-apps.app.image" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.image" -}}
{{- $image := .app.image | default dict -}}
{{- $repository := $image.repository | default .root.Values.image.repository -}}
{{- $tag := $image.tag | default .root.Values.image.tag | default .root.Chart.AppVersion -}}
{{- printf "%s:%s" $repository $tag -}}
{{- end }}

{{/*
Get image pull policy for an app (with fallback to global)
Usage: {{ include "deploy-apps.app.imagePullPolicy" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.imagePullPolicy" -}}
{{- $image := .app.image | default dict -}}
{{- $image.pullPolicy | default .root.Values.image.pullPolicy -}}
{{- end }}

{{/*
Get resources for an app (with fallback to global)
Usage: {{ include "deploy-apps.app.resources" (dict "root" $ "app" $app) }}
Returns: YAML formatted resources block
*/}}
{{- define "deploy-apps.app.resources" -}}
{{- $resources := .app.resources | default .root.Values.global.resources -}}
{{- if $resources }}
{{- toYaml $resources -}}
{{- else }}
{}
{{- end }}
{{- end }}

{{/*
Get podSecurityContext for an app (with fallback to global)
Usage: {{ include "deploy-apps.app.podSecurityContext" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.podSecurityContext" -}}
{{- $psc := .app.podSecurityContext | default .root.Values.global.podSecurityContext -}}
{{- if $psc }}
{{- toYaml $psc -}}
{{- else }}
{}
{{- end }}
{{- end }}

{{/*
Get securityContext for an app (with fallback to global)
Usage: {{ include "deploy-apps.app.securityContext" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.securityContext" -}}
{{- $sc := .app.securityContext | default .root.Values.global.securityContext -}}
{{- if $sc }}
{{- toYaml $sc -}}
{{- else }}
{}
{{- end }}
{{- end }}

{{/*
Get nodeSelector for an app (with fallback to global)
Usage: {{ include "deploy-apps.app.nodeSelector" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.nodeSelector" -}}
{{- $ns := .app.nodeSelector | default .root.Values.global.nodeSelector -}}
{{- if $ns }}
{{- toYaml $ns -}}
{{- end }}
{{- end }}

{{/*
Get affinity for an app (with fallback to global)
Usage: {{ include "deploy-apps.app.affinity" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.affinity" -}}
{{- $aff := .app.affinity | default .root.Values.global.affinity -}}
{{- if $aff }}
{{- toYaml $aff -}}
{{- end }}
{{- end }}

{{/*
Get tolerations for an app (merging global and app-specific)
Usage: {{ include "deploy-apps.app.tolerations" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.tolerations" -}}
{{- $globalTolerations := .root.Values.global.tolerations | default list -}}
{{- $appTolerations := .app.tolerations | default list -}}
{{- $merged := concat $globalTolerations $appTolerations -}}
{{- if $merged }}
{{- toYaml $merged -}}
{{- end }}
{{- end }}

{{/*
Get imagePullSecrets for an app (merging global and app-specific)
Usage: {{ include "deploy-apps.app.imagePullSecrets" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.imagePullSecrets" -}}
{{- $globalSecrets := .root.Values.imagePullSecrets | default list -}}
{{- $appSecrets := .app.imagePullSecrets | default list -}}
{{- $merged := concat $globalSecrets $appSecrets -}}
{{- if $merged }}
{{- toYaml $merged -}}
{{- end }}
{{- end }}

{{/*
Get podAnnotations for an app (merging global and app-specific)
Usage: {{ include "deploy-apps.app.podAnnotations" (dict "root" $ "app" $app) }}
*/}}
{{- define "deploy-apps.app.podAnnotations" -}}
{{- $globalAnnotations := .root.Values.global.podAnnotations | default dict -}}
{{- $appAnnotations := .app.podAnnotations | default dict -}}
{{- $merged := merge $appAnnotations $globalAnnotations -}}
{{- if $merged }}
{{- toYaml $merged -}}
{{- end }}
{{- end }}

{{/*
Check if app should have a service
Usage: {{ include "deploy-apps.app.shouldHaveService" (dict "app" $app) }}
Returns: "true" or "false" as string
*/}}
{{- define "deploy-apps.app.shouldHaveService" -}}
{{- $shouldHave := false -}}
{{- if or (eq .app.type "deployment") (eq .app.type "statefulset") -}}
{{- $shouldHave = true -}}
{{- end -}}
{{- if .app.service -}}
{{- if hasKey .app.service "enabled" -}}
{{- $shouldHave = .app.service.enabled -}}
{{- end -}}
{{- end -}}
{{- $shouldHave -}}
{{- end }}

{{/*
Get restart policy for workload type
Usage: {{ include "deploy-apps.app.restartPolicy" (dict "app" $app) }}
*/}}
{{- define "deploy-apps.app.restartPolicy" -}}
{{- if or (eq .app.type "cronjob") (eq .app.type "job") -}}
{{- .app.restartPolicy | default "Never" -}}
{{- else -}}
Always
{{- end -}}
{{- end }}

{{/*
Create ExternalSecret name
Usage: {{ include "deploy-apps.app.externalSecretName" (dict "root" $ "app" $app "secret" $secret) }}
*/}}
{{- define "deploy-apps.app.externalSecretName" -}}
{{- $appFullname := include "deploy-apps.app.fullname" (dict "root" .root "app" .app) -}}
{{- printf "%s-%s" $appFullname .secret.name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create native Secret name
Usage: {{ include "deploy-apps.app.secretName" (dict "root" $ "app" $app "secret" $secret) }}
*/}}
{{- define "deploy-apps.app.secretName" -}}
{{- $appFullname := include "deploy-apps.app.fullname" (dict "root" .root "app" .app) -}}
{{- printf "%s-%s" $appFullname .secret.name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create ConfigMap name
Usage: {{ include "deploy-apps.app.configMapName" (dict "root" $ "app" $app "cm" $configMap) }}
*/}}
{{- define "deploy-apps.app.configMapName" -}}
{{- $appFullname := include "deploy-apps.app.fullname" (dict "root" .root "app" .app) -}}
{{- printf "%s-%s" $appFullname .cm.name | trunc 63 | trimSuffix "-" -}}
{{- end }}

{{/*
Create PVC name
Usage: {{ include "deploy-apps.app.pvcName" (dict "root" $ "app" $app "pvc" $pvcItem) }}
*/}}
{{- define "deploy-apps.app.pvcName" -}}
{{- if .pvc.existingClaim -}}
{{- .pvc.existingClaim -}}
{{- else -}}
{{- $appFullname := include "deploy-apps.app.fullname" (dict "root" .root "app" .app) -}}
{{- printf "%s-%s" $appFullname .pvc.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end }}
