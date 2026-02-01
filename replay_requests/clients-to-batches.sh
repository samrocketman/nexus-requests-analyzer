#!/bin/bash
# Create batches of 50 by default.

batches="${1:-50}"
if ! grep '[0-9]\+' <<< "$batches" &> /dev/null; then
  echo 'ERROR: batches must be a number.' >&2
  exit 1
fi

# create directory structure
seq 1 "$batches" | xargs -I{} mkdir -p 'batches/{}'

total_clients="$(find clients -maxdepth 1 -type f -name '*.tsv' | wc -l | xargs)"
batch_num=0
thread=0
{
  while read client_num; do
    batch_num="$(( (batch_num % batches) + 1 ))"
    if [ "$batch_num" -eq 1 ]; then
      thread="$((thread + 1))"
      if [ "$(( thread % 15 ))" -eq 0 ]; then
        echo "Processed $((batches * thread))/${total_clients} (${thread} threads across ${batches} hosts)" >&2
      fi
    fi
    echo "clients/${client_num}.tsv" "batches/${batch_num}/${thread}.tsv"
  done <<< "$(seq 1 "$total_clients")"
  echo "Finished: ${total_clients} clients split across ${thread} threads on ${batches} hosts" >&2
} | xargs -P100 -n2 -- mv
