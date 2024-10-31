#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2024 The Falco Authors.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset
set -o pipefail

# Cluster variables
CLUSTER="falco-prow"
ZONE="eu-west-1"

# ArgoCD variables
NAMESPACE="argocd"
CHART_VERSION="7.6.12"  # Set desired ArgoCD chart version here

# Get the kubeconfig
aws eks --region ${ZONE} update-kubeconfig --name ${CLUSTER}-test-infra

# Add ArgoCD Helm repo and update
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

# Install or upgrade ArgoCD with Helm in specified namespace, using version
helm upgrade --install argocd argo/argo-cd \
  --create-namespace \
  --namespace $NAMESPACE \
  --version $CHART_VERSION \
  --set redis-ha.enabled=true \
  --set controller.replicas=1 \
  --set server.replicas=2 \
  --set repoServer.replicas=2 \
  --set applicationSet.replicas=2

echo "ArgoCD deployment completed with Helm."

echo

echo "Configuring app of apps:"
# Install the application that installs all the other applications.
cat <<EOF | kubectl apply -f -
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: applications
  namespace: argocd
spec:
  destination:
    namespace: argocd
    server: https://kubernetes.default.svc
  project: default
  source:
    path: config/applications
    repoURL: https://github.com/falcosecurity/test-infra.git
    targetRevision: HEAD
  syncPolicy:
    automated: {}
EOF
