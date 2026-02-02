#!/bin/bash
# Created by Sam Gleske
# MIT Licensed - Copyright 2026 Sam Gleske - https://github.com/samrocketman/nexus-requests-analyzer
# Pop!_OS 24.04 LTS
# Linux 6.17.9-76061709-generic x86_64
# GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)
echo $'timestamp_offset\tclient_id\thttp_method\tpath\tuseragent'
yq -r -o=tsv '
  .requests[0].unix_time as $mod |
  [.requests[] | . + {"_offset": (.unix_time % $mod)}] |
  group_by(._offset) |
  map(to_entries | map(.value + {"_seq": .key})) |
  flatten |
  sort_by(.unix_time) |
  .[] |
  [._offset, (.host + "." + .useragent_id + "." + (._seq | tostring)), .http_method, .path, .useragent]
'
#yq -r -o=tsv '.requests[0].unix_time as $mod | .requests[] | [.unix_time % $mod, .host + "." + .useragent_id, .http_method, .path, .useragent]'
