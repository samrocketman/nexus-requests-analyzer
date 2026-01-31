#!/bin/bash

yq -o=tsv '.requests[0].unix_time as $mod | .requests[] | [.unix_time % $mod, .host + "." + .useragent_id, .http_method, .path, .useragent]' input.yaml
