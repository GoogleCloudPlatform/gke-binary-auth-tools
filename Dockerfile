FROM gcr.io/cloud-builders/gcloud
RUN apt-get update && apt-get install -y gnupg2 jq golang
COPY cve-checker /root/go/src/cve-checker
RUN cd /root/go/src/cve-checker && \
    go build -o /usr/bin/cve-checker
COPY scripts/* /scripts/
