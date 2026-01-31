#!/bin/bash

echo $'timestamp_offset\tclient_id\thttp_method\tpath\tuseragent'
yq -r -o=tsv '
  .requests[0].unix_time as $mod |
  [.requests[] | . + {"_offset": (.unix_time % $mod)}] |
  group_by(._offset) |
  map(to_entries | map(.value + {"_seq": .key})) |
  flatten |
  sort_by(.unix_time) |
  .[] |
  [._offset, (.host + "." + .useragent_id + "." + (._offset | tostring) + "." + (._seq | tostring)), .http_method, .path, .useragent]
'
#yq -r -o=tsv '.requests[0].unix_time as $mod | .requests[] | [.unix_time % $mod, .host + "." + .useragent_id, .http_method, .path, .useragent]'
