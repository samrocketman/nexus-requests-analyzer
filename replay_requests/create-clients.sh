#!/bin/bash
if [ ! -x requests-to-tsv.sh ]; then
  echo 'ERROR: Executed from wrong dir.' >&2
  exit 1
fi
rm -rf clients
nexus-requests-analyzer.sh -f http_method=GET | \
  ./requests-to-tsv.sh | \
  ./split-by-client.sh
