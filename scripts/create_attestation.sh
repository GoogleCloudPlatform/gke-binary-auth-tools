#!/bin/bash
set -eEuo pipefail

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

SCRIPT_NAME="${0##*/}"

die() {
  echo "${SCRIPT_NAME}: $*" >&2
  exit 1
}

usage() {
  echo -n "Usage: ${SCRIPT_NAME} [options]

Create an attestor.

Global options:
  -p <project>
      ID of the Google Cloud project (e.g. \"my-project\")
  -i <image>
      Full image including SHA (e.g. \"gcr.io/my-project/my-image@sha245:...\")

Attestor options:
  -a <attestor>
      ID of the attestor (e.g. \"my-attestor\")
  -A <attestor project>
      ID of the project where the attestor exists. Defaults to the global
      project ID.

KMS options:
  -v <kms key version>
      Version of the KMS key to use for signing (e.g. \"1\")
  -k <kms key>
      Name of the KMS get (e.g. \"my-key\")
  -l <kms location>
      Location of the KMS key (e.g. \"global\")
  -r <kms key ring>
      Name of the KMS keyring (e.g. \"my-keyring\")
  -V <kms project>
      ID of the project where the KMS key exists. Defaults to the global
      project ID.
"
}

while getopts 'p:i:a:A:v:k:l:r:V:h' flag; do
  case ${flag} in
    p) PROJECT_ID="${OPTARG}" ;;
    i) IMAGE_PATH="${OPTARG}" ;;

    a) ATTESTOR="${OPTARG}" ;;
    A) ATTESTOR_PROJECT="${OPTARG}" ;;


    v) KMS_KEY_VERSION="${OPTARG}" ;;
    k) KMS_KEY="${OPTARG}" ;;
    l) KMS_LOCATION="${OPTARG}" ;;
    r) KMS_KEYRING="${OPTARG}" ;;
    V) KMS_PROJECT="${OPTARG}" ;;

    h) usage; exit 0 ;;
    *) die "invalid option found" ;;
  esac
done

if [ -z "${PROJECT_ID:-}" ]; then
  die '$PROJECT_ID or -p must be set'
fi

if [ -z "${IMAGE_PATH:-}" ]; then
  die '$IMAGE_PATH or -i must be set'
fi

if [ -z "${ATTESTOR:-}" ]; then
  die '$ATTESTOR or -a must be set'
fi

if [ -z "${KMS_KEY_VERSION:-}" ]; then
  die '$KMS_KEY_VERSION or -v must be set'
fi

if [ -z "${KMS_KEY:-}" ]; then
  die '$KMS_KEY or -k must be set'
fi

if [ -z "${KMS_LOCATION:-}" ]; then
  die '$KMS_LOCATION or -l must be set'
fi

if [ -z "${KMS_KEYRING:-}" ]; then
  die '$KMS_KEYRING or -r must be set'
fi

# Default parent properties
ATTESTOR_PROJECT="${ATTESTOR_PROJECT:-${PROJECT_ID}}"
KMS_PROJECT="${KMS_PROJECT:-${PROJECT_ID}}"

# Verify that the image wasn't already attested.
if gcloud container binauthz attestations list \
      --artifact-url "${IMAGE_PATH}" \
      --attestor "${ATTESTOR}" \
      --attestor-project "${ATTESTOR_PROJECT}" \
      --format json \
      | jq '.[0].kind' \
      | grep 'ATTESTATION'
then
  echo "Image has already been attested."
  exit 0
fi

# Sign and create the attestation.
gcloud beta container binauthz attestations sign-and-create \
  --project "${PROJECT_ID}" \
  --artifact-url "${IMAGE_PATH}" \
  --attestor "${ATTESTOR}" \
  --attestor-project "${ATTESTOR_PROJECT}" \
  --keyversion "${KMS_KEY_VERSION}" \
  --keyversion-key "${KMS_KEY}" \
  --keyversion-location "${KMS_LOCATION}" \
  --keyversion-keyring "${KMS_KEYRING}" \
  --keyversion-project "${KMS_PROJECT}"
