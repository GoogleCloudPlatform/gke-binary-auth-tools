# Binary Authorization Tools

## CVE Checker - cve-checker/main.go

A Go program that parses the JSON output of the vulnerabilities for an image in Google
Container Registry (GCR).  If any of the vulnerabilities are higher than the CVSS
threshold, it exits with an error.

## Check Vulnerabilities Script - scripts/check_vulnerabilities.sh

Wait for a vulnerability scan to complete for a particular image in GCR then
run the CVE Checker against it to make sure that no vulnerabilites are higher
than the threshold.

```
Options:
  -p <project ID>      Project ID
  -i <image path>      Full image path including sha (gcr.io/my-project/image-name@sha256:....)
  -t <CVSS Threshold>  Maximum CVSS score allowed in discovered CVEs
```

## Create Attestation Script - scripts/create_attestation.sh

Pulls down an encrypted PGP private key from Google Cloud Storage then decrypts it and 
uses it to create an attestation for the image that was passed in.

```
Options:
  -n <attestor name>   Name to use for attestor
  -p <project ID>      Project ID
  -i <image path>      Full image path including sha (gcr.io/my-project/image-name@sha256:....)
  -b <bucket name>     Name of the GCS Bucket with KMS decryption keys
  -r <keyring name>    Name of the KMS keyring decryption key
  -k <key name>        Name of the KMS decryption key
```