{{/*
Expand the name of the chart.
*/}}
{{- define "timothy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "timothy.fullname" -}}
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
{{- define "timothy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "timothy.labels" -}}
helm.sh/chart: {{ include "timothy.chart" . }}
{{ include "timothy.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "timothy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "timothy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "timothy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "timothy.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Creates the fully qualified image tag needed
*/}}
{{- define "timothy.image" -}}
{{- $tag :=  coalesce .Values.image.tag "latest"  -}}
{{- $repo := coalesce .Values.global.alternativeRepository .Values.image.repo "" -}}
{{- if $repo -}}
{{- $repo = $repo | trimSuffix "/" -}}
{{- printf "%s/%s:%s" $repo .Values.image.name $tag -}}
{{- else -}}
{{- printf "%s:%s" .Values.image.name $tag -}}
{{- end -}}
{{- end }}

{{/*
Get the proper repository to pull all images from. Used for non-tonic images
that are otherwise pulled from docker hub. This automatically includes the
necessary trailing slash
*/}}
{{- define "timothy.globalImageRepo" -}}
{{- $repo := .Values.global.alternativeRepository -}}
{{- if $repo -}}
{{- $repo | trimSuffix "/"  -}}/
{{- end -}}
{{- end -}}

{{/*
Checks if https is enabled
*/}}
{{- define "timothy.httpsEnabled" -}}
{{- $https := ((.Values).networking).https -}}
{{- if and $https $https.enabled -}}
"1"
{{- end -}}
{{- end -}}

{{/*
Checks if http is enabled
*/}}
{{- define "timothy.httpEnabled" -}}
{{- $http := ((.Values).networking).http -}}
{{- if and $http $http.enabled -}}
"1"
{{- end -}}
{{- end -}}

{{/*
Checks if the bundled certs are being used
*/}}
{{- define "timothy.usingBundledCerts" -}}
{{- $https := ((.Values).networking).https -}}
{{- if and $https $https.enabled $https.useBundledCerts -}}
"1"
{{- end -}}
{{- end -}}

{{/*
Determines which nginx certificate secret we should use
*/}}
{{- define "timothy.nginxCertificateSecretName" -}}
{{- if ( include "timothy.usingBundledCerts" . ) }}
{{- include "timothy.fullname" . -}}-certificates
{{- else -}}
{{- $https := ((.Values).networking).https -}}
{{- required ".Values.networking.https.secretName must be provided if https is enabled but bundled certs is disabled" $https.secretName -}}
{{- end -}}
{{- end -}}

{{/*
Determines which database secret we should use
*/}}
{{- define "timothy.databaseSecretName" -}}
{{- $externalSecret := .Values.configuration.database.secretName -}}
{{- if  $externalSecret -}}
{{ $externalSecret }}
{{- else -}}
{{ include "timothy.fullname" . }}-database
{{- end -}}
{{- end -}}

{{/*
Creates a definition for image pull secrets
*/}}
{{- define "timothy.imagePullSecret" -}}
{{- if .value -}}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .name }}
type: kubernetes.io/dockerconfigjson
data:
  .dockerconfigjson: {{ .value }}
{{- end -}}
{{- end -}}


{{/*
Determines the correct ingress api Version to use
*/}}
{{- define "tonic.ingressApiVersion" -}}
{{- if semverCompare ">=1.19-0" .Capabilities.KubeVersion.GitVersion -}}
networking.k8s.io/v1
{{- else if semverCompare ">=1.14-0" .Capabilities.KubeVersion.GitVersion -}}
networking.k8s.io/v1beta1
{{- else -}}
extensions/v1beta1
{{- end }}
{{- end -}}

{{/*
Determines if this chart should create rbac bindings for Tim
*/}}
{{- define "timothy.createRbac" -}}
{{- if and .Values.global.rbac.create .Values.serviceAccount.create .Values.rbac.create -}}
1
{{- end -}}
{{- end -}}
