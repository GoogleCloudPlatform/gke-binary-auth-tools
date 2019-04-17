# Binary Authorization Tools

## CVE Checker - cve-checker/main.go

A Go program that parses the JSON output of the vulnerabilities for an image in Google
Container Registry (GCR) and errors out if any of the vulnerabilities
are higher than the CVSS threshold.

## Check Vulnerabilities Script - scripts/check_vulnerabilities.sh

Wait for a vulnerability scan to complete for a particular image in GCR then
run the CVE Checker against it to make sure that no vulnerabilites are higher
than the threshold.

## Create Attestation Script - scripts/create_attestation.sh

Pulls down an encrypted PGP from Google Cloud Storage then decrypts it and uses it
to create an attestation for the image that was passed in.