#!/bin/bash
# Created by Sam Gleske
# MIT Licensed - Copyright 2026 Sam Gleske - https://github.com/samrocketman/nexus-requests-analyzer
# Pop!_OS 24.04 LTS
# Linux 6.17.9-76061709-generic x86_64
# GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)
if [ ! -x requests-to-tsv.sh ]; then
  echo 'ERROR: Executed from wrong dir.' >&2
  exit 1
fi
rm -rf clients
nexus-requests-analyzer.sh -f http_method=GET | \
  ./requests-to-tsv.sh | \
  ./split-by-client.sh
