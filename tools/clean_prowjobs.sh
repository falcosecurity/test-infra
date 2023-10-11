# SPDX-License-Identifier: Apache-2.0
#
# Copyright (C) 2023 The Falco Authors.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#     http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#Useful Deubgging commands

#Get logs from microservices

kubectl logs -l app=hook --tail 100 > hook.log
kubectl logs -l app=deck --tail 100 > deck.log
kubectl logs -l app=crier --tail 100 > crier.log
kubectl logs -l app=prow-controller-manager --tail 100 > prow-controller-manager.log
kubectl logs -l app=ghproxy --tail 100 > ghproxy.log
kubectl logs -l app=horologium --tail 100 > horologium.log
kubectl logs -l app=sinker --tail 100 > sinker.log
kubectl logs -l app=statusreconciler --tail 100 > statusreconciler.log
kubectl logs -l app=tide --tail 100 > tide.log




kubectl get prowjobs --sort-by=.metadata.creationTimestamp --namespace default |  grep -i "pending" | awk -F ' ' '{print $1}' | xargs kubectl delete pod --force

kubectl get prowjobs --sort-by=.metadata.creationTimestamp |  grep -i "pending" | awk -F ' ' '{print $1}' | xargs kubectl delete pod --namespace test-pods --force  
