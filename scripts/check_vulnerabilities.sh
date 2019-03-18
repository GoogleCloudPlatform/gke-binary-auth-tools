#!/bin/bash -e
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
until gcloud beta container images describe gcr.io/vic-cd-demo/binauthz-tools@sha256:c4c7a459dd45f35c0c7dbe84ddcffd7ab9cd1161d43b8ef3fbeaf41e037a3ed5 --format 'value(discovery_summary.discovery.discovered.analysisStatus)' --show-package-vulnerability || [ ${NUM_WAITS} -eq ${MAX_WAITS} ]; do
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

