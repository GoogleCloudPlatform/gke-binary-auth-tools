#!/bin/bash -xe

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
  echo "Usage: create_attestor.sh [options] [args]

Create an attestor in the current project.

Options:
  -n <attestor name>   Name to use for attestor
  -p <project ID>      Project ID
  -i <image path>      Full image path including sha (gcr.io/my-project/image-name@sha256:....)
  -h                   This help screen"
}

while getopts 'hn:p:i:' flag; do
  case ${flag} in
    h) usage ;;
    p) PROJECT_ID="${OPTARG}" ;;
    i) IMAGE_PATH="${OPTARG}" ;;
    n) NAME="${OPTARG}" ;;
    *) die "invalid option found" ;;
  esac
done

if [ -z "$NAME" ]
then
   usage
   die "Name must be set"
fi

if [ -z "$IMAGE_PATH" ]
then
   usage
   die "Image must be set"
fi

if [ -z "$PROJECT_ID" ]
then
   usage
   die "Project must be set"
fi

if gcloud beta container binauthz attestations list --artifact-url $IMAGE_PATH --attestor $NAME --format json | jq '.[0].kind' | grep ATTESTATION; then
echo "Image has already been attested."
exit 0
fi

# Get signing keys
gsutil cp gs://$PROJECT_ID-${NAME}/${NAME}.fpr gs://$PROJECT_ID-${NAME}/${NAME}_sec.gpg.enc gs://$PROJECT_ID-${NAME}/${NAME}.pass.enc .
gcloud kms decrypt --ciphertext-file=${NAME}_sec.gpg.enc \
                --plaintext-file=${NAME}_sec.gpg \
                --location=global \
                --keyring=attestors \
                --key=attestors
gcloud kms decrypt --ciphertext-file=${NAME}.pass.enc \
                --plaintext-file=${NAME}.pass \
                --location=global \
                --keyring=attestors \
                --key=attestors
gcloud beta container binauthz create-signature-payload \
    --artifact-url=${IMAGE_PATH} > generated_payload.json

# Sign attestation
mkdir -p ~/.gnupg
echo allow-loopback-pinentry > ~/.gnupg/gpg-agent.conf
COMMON_FLAGS="--no-tty --pinentry-mode loopback  --passphrase-file ${NAME}.pass"
gpg2 $COMMON_FLAGS --import ${NAME}_sec.gpg
gpg2 $COMMON_FLAGS --output generated_signature.pgp --local-user $(cat ${NAME}.fpr) --armor --sign generated_payload.json

# Upload attestation
gcloud beta container binauthz attestations create \
    --artifact-url="${IMAGE_PATH}" \
    --attestor="projects/${PROJECT_ID}/attestors/${NAME}" \
    --signature-file=generated_signature.pgp \
    --pgp-key-fingerprint="$(cat ${NAME}.fpr)"
