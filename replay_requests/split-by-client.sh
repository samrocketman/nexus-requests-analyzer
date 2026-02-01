#!/bin/bash
# split_by_client.sh - Split TSV into per-client files
#
set -euo pipefail
export TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

OUTPUT_DIR="."

mkdir -p "${OUTPUT_DIR}/clients"
export OUTPUT_DIR

# read from script stdin
(
# up to 100KB is allowed to be the header
header_bytes=102400
dd of="${TMP_DIR}"/tsv_header count="$header_bytes" bs=1 status=none
found_bytes="$(wc -c < "${TMP_DIR}"/tsv_header | xargs)"
export found_bytes header_bytes
head -n1 "${TMP_DIR}"/tsv_header > "${TMP_DIR}"/tsv_header_line
{
if [ "$found_bytes" -lt "$header_bytes" ]; then
  dd if="${TMP_DIR}"/tsv_header count="$header_bytes" bs=1 status=none
else
  dd if="${TMP_DIR}"/tsv_header count="$header_bytes" bs=1 status=none
  cat
fi
} | \
awk -F'\t' -v dir="${OUTPUT_DIR}/clients" -v header="$(<"${TMP_DIR}"/tsv_header_line)" '
BEGIN {
  clients=1
};
$0 == header {
  # skip header line
  next
};
{
    client = $2
    gsub(/[^a-zA-Z0-9._-]/, "_", client)  # sanitize filename
    file=""
    if (!(client in seen)) {
        seen[client] = clients
        file = dir "/" seen[client] ".tsv"
        print header > file
        clients++
    }
    if(file == "") {
      file = dir "/" seen[client] ".tsv"
    }
    print >> file
    close(file)
    file=""
}'
)

# Count clients
CLIENT_COUNT="$(find "${OUTPUT_DIR}/clients" -maxdepth 1 -type f -name '*.tsv' | wc -l | xargs)"
echo "Split into $CLIENT_COUNT client files in $OUTPUT_DIR/clients"
