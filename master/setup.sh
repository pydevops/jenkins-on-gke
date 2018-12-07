#!/usr/bin/env bash
# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -euo pipefail

gcloud container clusters create jenkins-cd \
--num-nodes 2 --machine-type n1-standard-2 \
--scopes "https://www.googleapis.com/auth/projecthosting,cloud-platform" \
--network dev-vpc

gcloud container clusters get-credentials jenkins-cd

kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)

# install helm
kubectl create serviceaccount tiller --namespace kube-system
kubectl create clusterrolebinding tiller-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
helm init --service-account=tiller
helm update
helm version

# get admin password
printf $(kubectl get secret --namespace default cd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo

export POD_NAME=$(kubectl get pods -l "component=cd-jenkins-master" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 8080:8080 >> /dev/null

# change svc/cd-jenkins from ClustIP to NodePort
kubectl patch svc cd-jenkins --type='json' -p '[{"op":"replace","path":"/spec/type","value":"NodePort"}]'
# ingress
kubectl apply -f jenkins-ingress.yaml
# set up SSL cert
gcloud beta compute ssl-certificates create cd-demo --domains cd-demo.gflocks.com


# upgrade.sh
helm upgrade cd stable/jenkins -f jenkins/values.yaml --version 0.16.0 --wait


# add terraform service account as a secret
kubectl create secret generic terraform --from-file=terraform.json