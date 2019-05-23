# Copyright 2019 Google LLC
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

FROM gcr.io/cloud-builders/gcloud
RUN apt-get update && apt-get install -y gnupg2 jq golang
COPY cve-checker /root/go/src/cve-checker
RUN cd /root/go/src/cve-checker && \
    go build -o /usr/bin/cve-checker
COPY scripts/* /scripts/
