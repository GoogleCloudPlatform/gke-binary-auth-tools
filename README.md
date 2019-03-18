# Binary Authorization Tools

## CVE Checker

A Go program that parses the JSON output of the vulnerabilities for an image in Google
Container Registry (GCR) and errors out if any of the vulnerabilities
are higher than the CVSS threshold.

## Check Vulnerabilities Script

Whats for the vulnerability scan to complete for a particular image in GCR then
runs the CVE Checker against it to make sure that no vulnerabilites are higher
than the threshold.

## Create Attestation Script

Pulls down an encrypted PGP from Google Cloud Storage then decrypts it and uses it
to create an attestation for the image that was passed in.