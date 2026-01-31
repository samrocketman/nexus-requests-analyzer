#!/bin/bash
# split_by_client.sh - Split TSV into per-client files

TSV_FILE="${1:?Usage: $0 <tsv_file> <output_dir>}"
OUTPUT_DIR="${2:-.}/clients"

mkdir -p "$OUTPUT_DIR"

# Get header
HEADER=$(head -1 "$TSV_FILE")

# Split by client_id (column 2), preserving header in each file
tail -n +2 "$TSV_FILE" | sort -t$'\t' -k2,2 -k1,1n | \
awk -F'\t' -v dir="$OUTPUT_DIR" -v header="$HEADER" '
{
    client = $2
    gsub(/[^a-zA-Z0-9._-]/, "_", client)  # sanitize filename
    file = dir "/" client ".tsv"
    if (!(client in seen)) {
        print header > file
        seen[client] = 1
    }
    print >> file
}'

# Count clients
CLIENT_COUNT=$(ls -1 "$OUTPUT_DIR"/*.tsv 2>/dev/null | wc -l)
echo "Split into $CLIENT_COUNT client files in $OUTPUT_DIR/"
echo "client_count=$CLIENT_COUNT"
