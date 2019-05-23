#!/bin/bash -e

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

die() {
  echo "${0##*/}: error: $*" >&2
  exit 1
}

usage() {
  echo "Usage: check_vulnerabilities.sh [options] [args]

Check if an image has CRITICAL vulnerabilities.

Options:
  -p <project ID>      Project ID
  -i <image path>      Full image path including sha (gcr.io/my-project/image-name@sha256:....)
  -t <CVSS Threshold>  Maximum CVSS score allowed in discovered CVEs
  -h                   This help screen"
}

while getopts 'hp:i:t:' flag; do
  case ${flag} in
    h) usage ;;
    p) PROJECT_ID="${OPTARG}" ;;
    i) IMAGE_PATH="${OPTARG}" ;;
    t) THRESHOLD="${OPTARG}" ;;
    *) die "invalid option found" ;;
  esac
done

if [ -z "${IMAGE_PATH}" ]
then
   usage
   die "Image must be set"
fi

if [ -z "${PROJECT_ID}" ]
then
   usage
   die "Project must be set"
fi

if [ -z "${THRESHOLD}" ]
then
   usage
   die "CVSS threshold must be set"
fi

gcloud config set project ${PROJECT_ID}

# Periodic checking loop variables
SLEEP_WAIT_FOR_SCAN=30
NUM_WAITS=0
MAX_WAITS=6

# Wait for scan to begin
until gcloud beta container images describe ${IMAGE_PATH} --format 'value(discovery_summary.discovery.discovered.analysisStatus)' --show-package-vulnerability || [ ${NUM_WAITS} -eq ${MAX_WAITS} ]; do
  sleep ${SLEEP_WAIT_FOR_SCAN}
  ((NUM_WAITS++))
done

if [ ${NUM_WAITS} -eq ${MAX_WAITS} ];then
  die "Timed out waiting for vulnerability scan to start"
fi

NUM_WAITS=0
# Wait for scan to complete
SCAN_RESULTS=$(gcloud beta container images describe ${IMAGE_PATH} --show-package-vulnerability --format json)
until echo $SCAN_RESULTS | jq '.discovery_summary.discovery[0].discovered.analysisStatus' | grep FINISHED_SUCCESS || [ ${NUM_WAITS} -eq ${MAX_WAITS} ]; do
    NUM_WAITS=$((NUM_WAITS + 1))
    echo "Waiting ${SLEEP_WAIT_FOR_SCAN}s for scan to complete"
    sleep ${SLEEP_WAIT_FOR_SCAN}
    SCAN_RESULTS=$(gcloud beta container images describe ${IMAGE_PATH} --show-package-vulnerability --format json)
done

if [ ${NUM_WAITS} -eq ${MAX_WAITS} ];then
  die "Timed out waiting for vulnerability scan to complete"
fi

IMAGE_NAME=$(echo ${IMAGE_PATH} | awk -F/ '{print $3}')
echo "Check vulnerability scan results here:"
echo "https://console.cloud.google.com/gcr/images/${PROJECT_ID}/GLOBAL/${IMAGE_NAME}/details?tab=vulnz"

# Check for CRITICAL vulnerabilities over our CVSS Score
cat > vuln.json <<EOF
${SCAN_RESULTS}
EOF
if cve-checker -threshold ${THRESHOLD} -file vuln.json;then
    echo "No CRITICAL Vulnerabilities found in ${IMAGE_PATH}"
    exit 0
else
    echo "Scan returned CRITICAL Vulnerabilities for ${IMAGE_PATH}"
    exit 1
fi

