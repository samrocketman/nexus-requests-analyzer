#!/bin/bash
# Created by Sam Gleske
# MIT Licensed - Copyright 2026 Sam Gleske - https://github.com/samrocketman/nexus-requests-analyzer
# Pop!_OS 24.04 LTS
# Linux 6.17.9-76061709-generic x86_64
# GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)
if ! type -P jmeter &> /dev/null; then
  jmeter_path="$(find . -maxdepth 3 -type f -name jmeter)"
  if [ -n "${jmeter_path:-}" ]; then
    export PATH="${jmeter_path%/*}:$PATH"
  else
    echo 'ERROR: jmeter not found in path.' >&2
    exit 1
  fi
fi
if [ ! -f replay_traffic.jmx ] || [ ! -d clients ]; then
  echo 'ERROR: clients or jmeter test plan do not exist.' >&2
  exit 1
fi
if [ "$#" -lt 1 ]; then
  echo 'ERROR: Hostname is the minimum script argument.' >&2
  exit 1
fi
helptext() {
cat >&2 <<'EOF'
Required arguments.
  -h HOST, --host HOST
    Target HOST to replay requests against.

Optional script arguments.
  -d DIR, --client-dir DIR
    Client directory where a list of client threads contains request replay
    data.  Useful only for batch request loads spread across multiple client
    hosts.
    Default: ./clients

  -p PORT, --port PORT
    Target PORT to replay requests against.
    Default: 443

  --proto PROTOCOL
    Target PROTOCOL to replay requests against.
    Default: https
EOF
  exit 1
}

error_on_arg() {
  if [ -z "${2:-}" ]; then
    echo 'ERROR: expected argument for '"$1"' but found none.' >&2
    echo 'Launch script with --help to learn more.' >&2
    exit 1
  fi
}

while [ "$#" -gt 0 ]; do
  if [ "$1" = '--help' ]; then
    helptext
  fi
  case "$1" in
    -h|--host)
      error_on_arg '--host' "${2:-}"
      host="$2"
      ;;
    -p|--port)
      error_on_arg '--port' "${2:-}"
      port="$2"
      ;;
    --proto)
      error_on_arg '--proto' "${2:-}"
      protocol="$2"
      ;;
    -d|--client-dir)
      error_on_arg '--client-dir' "${2:-}"
      client_dir="$2"
      ;;
    *)
      echo 'ERROR: unknown option.' >&2
      exit 1
  esac
  shift 2
done

client_dir="${client_dir:-./clients}"

if [ ! -d "${client_dir:-}" ]; then
  echo "ERROR: clients_dir '${client_dir:-}' does not exist." >&2
  exit 1
fi
if [ -z "${host:-}" ]; then
  echo 'ERROR: host must be defined.  --host argument required.' >&2
  exit 1
fi

client_count="$(find "${client_dir}" -maxdepth 1 -type f -name '*.tsv' | wc -l | xargs)"
if [ "$client_count" -eq 0 ]; then
  echo "ERROR: no clients found in directory '${client_dir}'." >&2
  echo 'Perhaps you split the traffic into batches or did not process request.log?' >&2
  exit 1
fi
max_time="$(find "$client_dir" -type f -print0 | xargs -P1 -0 -n100 -- tail -n1 | grep -F $'\t' | cut -d$'\t' -f1 | sort -nru | head -n1)"
echo "Highest offset second (offset to start a request): ${max_time} seconds" >&2
set -x
JVM_ARGS="${JVM_ARGS:--Djava.awt.headless=true}"
HEAP="${HEAP:--Xms1g -Xmx1g -XX:MaxMetaspaceSize=256m}"
export HEAP JVM_ARGS
time jmeter \
  -n -t replay_traffic.jmx \
  -Jprotocol="${protocol:-https}" \
  -Jhost="${host}" \
  -Jport="${port:-443}" \
  -Jclient_dir="${client_dir}" \
  -Jthreads="${client_count}" \
  -Jjmeter.save.saveservice.response_data=false \
  -Jjmeter.save.saveservice.samplerData=false \
  -l /dev/null

# This script is meant to replay request loads and so there's no need to
# analyze any results from jmeter.
# - -n is for non-GUI execution
# - jmeter.save.saveservice.response_data=false Disables response body written
#   to results file.
# - jmeter.save.saveservice.samplerData=false Disables request data written to
#   results file.
# - -l /dev/null discards results (e.g. normally -l results.jtl)
