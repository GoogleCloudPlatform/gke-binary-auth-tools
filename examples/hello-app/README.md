# Hello App

This code supports [Implementing Binary Authorization with GKE and Cloud Build](https://cloud.google.com/solutions/binary-auth-with-cloud-build-and-gke)
published on cloud.google.com.

In this example the simple Go app is built using Cloud Build and deployed to Google
Kubernetes Engine (GKE). Attestations are made after the vulnerability scan completes.
The manifest templete in env demonstrates the break-glass process.