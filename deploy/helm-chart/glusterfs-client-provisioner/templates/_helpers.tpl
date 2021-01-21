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
cluster.local/{{ template "glusterfs-client-provisioner.fullname" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "glusterfs-client-provisioner.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "glusterfs-client-provisioner.fullname" .) .Values.serviceAccount.name }}
{{- else if .Values.serviceAccount.name -}}
    {{ .Values.serviceAccount.name }}
{{- else -}}
	{{ fail "no serviceAccount name provided" }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "glusterfs-client-provisioner.endpoints" -}}
{{- if kindIs "slice" .Values.glusterfs.endpoints -}}
    {{- if eq 0 (len .Values.glusterfs.endpoints) -}}
    	{{ fail "no glusterfs endpoints provided" }}
    {{- end -}}
    {{ .Values.glusterfs.endpoints | join "," | quote }}
{{- else -}}
    {{- if not .Values.glusterfs.endpoints -}}
    	{{ fail "no glusterfs endpoints provided" }}
    {{- end -}}
    {{ .Values.glusterfs.endpoints | quote }}
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for podSecurityPolicy.
*/}}
{{- define "podSecurityPolicy.apiVersion" -}}
{{- if semverCompare ">=1.10-0" .Capabilities.KubeVersion.GitVersion -}}
{{- print "policy/v1beta1" -}}
{{- else -}}
{{- print "extensions/v1beta1" -}}
{{- end -}}
{{- end -}}
