#!/bin/bash

echo $'timestamp_offset\tclient_id\thttp_method\tpath\tuseragent'
yq -r -o=tsv '.requests[0].unix_time as $mod | .requests[] | [.unix_time % $mod, .host + "." + .useragent_id, .http_method, .path, .useragent]'
