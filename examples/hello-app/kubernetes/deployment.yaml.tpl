# Copyright 2019 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

apiVersion: apps/v1
kind: Deployment
metadata:
  name: hello-app
  labels:
    app: hello-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hello-app
  template:
    metadata:
      labels:
        app: hello-app
      annotations:
#        alpha.image-policy.k8s.io/break-glass: "true"
    spec:
      containers:
      - name: hello-app
        image: REGION-docker.pkg.dev/GOOGLE_CLOUD_PROJECT/applications/hello-app@DIGEST
        readinessProbe:
          initialDelaySeconds: 1
          periodSeconds: 1
          httpGet:
            path: /healthz
            port: 8080
        ports:
        - name: http
          containerPort: 8080