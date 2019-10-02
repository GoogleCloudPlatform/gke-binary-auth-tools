# Binary Authorization Tools

*Disclaimer: This is not an official Google product.*

This project contains a set of tools to help with the implementation of Binary Authorization in Google
Cloud.

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

Creates an attestation for the given artifact using Cloud KMS.

```
Global options:
  -p <project>
      ID of the Google Cloud project (e.g. "my-project")
  -i <image>
      Full image including SHA (e.g. "gcr.io/my-project/my-image@sha245:...")

Attestor options:
  -a <attestor>
      ID of the attestor (e.g. "my-attestor")
  -A <attestor project>
      ID of the project where the attestor exists. Defaults to the global
      project ID.

KMS options:
  -v <kms key version>
      Version of the KMS key to use for signing (e.g. "1")
  -k <kms key>
      Name of the KMS get (e.g. "my-key")
  -l <kms location>
      Location of the KMS key (e.g. "global")
  -r <kms key ring>
      Name of the KMS keyring (e.g. "my-keyring")
  -V <kms project>
      ID of the project where the KMS key exists. Defaults to the global
      project ID.
```

## Contributing

See [CONTRIBUTING](https://github.com/GoogleCloudPlatform/binauthz-tools/blob/master/CONTRIBUTING)

## License

Copyright 2019, Google, Inc.
Licensed under the Apache License, Version 2.0

See [LICENSE](https://github.com/GoogleCloudPlatform/binauthz-tools/blob/master/LICENSE).
