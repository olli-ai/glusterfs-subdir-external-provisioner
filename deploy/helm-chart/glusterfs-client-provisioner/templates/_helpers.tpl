{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "glusterfs-client-provisioner.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "glusterfs-client-provisioner.fullname" -}}
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
{{- define "glusterfs-client-provisioner.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "glusterfs-client-provisioner.provisionerName" -}}
{{- if .Values.storageClass.provisionerName -}}
    {{- .Values.storageClass.provisionerName -}}
{{- else -}}
    cluster.local/{{- template "glusterfs-client-provisioner.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "glusterfs-client-provisioner.serviceAccountName" -}}
{{- if .Values.serviceAccount.name -}}
    {{- .Values.serviceAccount.name -}}
{{- else if .Values.serviceAccount.create -}}
    {{- template "glusterfs-client-provisioner.fullname" . -}}
{{- else -}}
    {{- fail "no serviceAccount name provided" -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the endpoints to use
*/}}
{{- define "glusterfs-client-provisioner.endpointsName" -}}
{{- if .Values.endpoints.name -}}
    {{- .Values.endpoints.name -}}
{{- else if .Values.endpoints.create -}}
    {{- template "glusterfs-client-provisioner.fullname" . -}}
{{- else -}}
    {{- fail "no endpoints name provided" -}}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for podSecurityPolicy.
*/}}
{{- define "podSecurityPolicy.apiVersion" -}}
{{- if semverCompare ">=1.10-0" .Capabilities.KubeVersion.GitVersion -}}
    policy/v1beta1
{{- else -}}
    extensions/v1beta1
{{- end -}}
{{- end -}}

{{/*
Create the GlusterFS path to use
*/}}
{{- define "glusterfs-client-provisioner.path" -}}
{{- if not .Values.glusterfs.volume -}}
    {{- fail "no glusterfs volume provided" -}}
{{- end -}}
{{- .Values.glusterfs.volume -}}
{{- if trimAll "/" .Values.glusterfs.path -}}
    /{{- trimAll "/" .Values.glusterfs.path -}}
{{- end -}}
{{- end -}}
