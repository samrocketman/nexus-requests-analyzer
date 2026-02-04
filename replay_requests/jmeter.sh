#!/bin/bash
# Created by Sam Gleske
# MIT Licensed - Copyright 2026 Sam Gleske - https://github.com/samrocketman/nexus-requests-analyzer
# Pop!_OS 24.04 LTS
# Linux 6.17.9-76061709-generic x86_64
# GNU bash, version 5.2.21(1)-release (x86_64-pc-linux-gnu)
set -euo pipefail
if ! type -P jmeter &> /dev/null; then
  jmeter_path="$(find . -maxdepth 3 -type f -name jmeter)"
  if [ -n "${jmeter_path:-}" ]; then
    export PATH="${jmeter_path%/*}:$PATH"
  else
    echo 'ERROR: jmeter not found in path.' >&2
    exit 1
  fi
fi
if [ ! -d clients ]; then
  echo 'ERROR: clients directory does not exist.' >&2
  exit 1
fi
if [ "$#" -lt 1 ]; then
  echo 'ERROR: Hostname is the minimum script argument.' >&2
  exit 1
fi

# temporary space
export TMP_DIR
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "${TMP_DIR}"' EXIT

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

  -t JMETER_PLAN, --test-plan JMETER_PLAN
    JMeter test plan to execute.  Available options:
      - replay_traffic.jmx (default) - Replay traffic without verification
      - record_traffic_body.jmx - Record MD5 checksums of response bodies
      - verify_traffic_body.jmx - Verify response bodies match recorded checksums
    Default: replay_traffic.jmx

  -j RESULTS_FILE, --junit-results RESULTS_FILE
    Save JUnit XML report to RESULTS_FILE.  Only applicable when using
    verify_traffic_body.jmx test plan.

Optional environment variables.
  HTTP_USER
    Username for HTTP basic authentication.  If not set, no authentication is
    used.

  HTTP_PASSWORD
    Password for HTTP basic authentication.  Only used if HTTP_USER is set.

  HTTP_CONNECT_TIMEOUT
    HTTP connection timeout in milliseconds.
    Default: 5000

  HTTP_RESPONSE_TIMEOUT
    HTTP response timeout in milliseconds.
    Default: 30000
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

# Convert JMeter JTL CSV to JUnit XML format
# Reads JTL from stdin, outputs JUnit XML to stdout
convert_jtl_to_junit() {
  awk -F',' '
    BEGIN {
      tests = 0
      failures = 0
      time = 0
    }
    NR == 1 {
      # Parse header to find column indices
      for (i = 1; i <= NF; i++) {
        gsub(/"/, "", $i)
        if ($i == "elapsed") elapsed_col = i
        if ($i == "label") label_col = i
        if ($i == "success") success_col = i
        if ($i == "failureMessage") failure_col = i
        if ($i == "responseCode") code_col = i
      }
      next
    }
    {
      tests++
      # Remove quotes from fields
      for (i = 1; i <= NF; i++) {
        gsub(/^"/, "", $i)
        gsub(/"$/, "", $i)
      }
      elapsed_ms = $elapsed_col
      time += elapsed_ms / 1000
      label = $label_col
      success = $success_col
      failure_msg = $failure_col
      response_code = $code_col

      # Escape XML special characters in label
      gsub(/&/, "\\&amp;", label)
      gsub(/</, "\\&lt;", label)
      gsub(/>/, "\\&gt;", label)
      gsub(/"/, "\\&quot;", label)

      # Build testcase XML
      testcase = sprintf("  <testcase name=\"%s\" time=\"%.3f\"", label, elapsed_ms/1000)

      if (success == "false") {
        failures++
        # Escape XML special characters in failure message
        gsub(/&/, "\\&amp;", failure_msg)
        gsub(/</, "\\&lt;", failure_msg)
        gsub(/>/, "\\&gt;", failure_msg)
        gsub(/"/, "\\&quot;", failure_msg)
        testcase = testcase ">\n"
        testcase = testcase sprintf("    <failure message=\"%s\" type=\"AssertionFailure\">%s</failure>\n", failure_msg, failure_msg)
        testcase = testcase "  </testcase>"
      } else {
        testcase = testcase "/>"
      }
      testcases = testcases testcase "\n"
    }
    END {
      print "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
      printf "<testsuite name=\"JMeter Traffic Verification\" tests=\"%d\" failures=\"%d\" errors=\"0\" time=\"%.3f\">\n", tests, failures, time
      printf "%s", testcases
      print "</testsuite>"
    }
  '
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
    -t|--test-plan)
      error_on_arg '--test-plan' "${2:-}"
      test_plan="$2"
      ;;
    -j|--junit-results)
      error_on_arg '--junit-results' "${2:-}"
      junit_results="$2"
      ;;
    *)
      echo 'ERROR: unknown option.' >&2
      exit 1
  esac
  shift 2
done

client_dir="${client_dir:-./clients}"
test_plan="${test_plan:-replay_traffic.jmx}"

if [ ! -d "${client_dir:-}" ]; then
  echo "ERROR: clients_dir '${client_dir:-}' does not exist." >&2
  exit 1
fi
if [ -z "${host:-}" ]; then
  echo 'ERROR: host must be defined.  --host argument required.' >&2
  exit 1
fi
if [ ! -f "${test_plan}" ]; then
  echo "ERROR: test plan '${test_plan}' does not exist." >&2
  exit 1
fi
if [ -n "${junit_results:-}" ] && [ "${test_plan}" != "verify_traffic_body.jmx" ]; then
  echo "ERROR: --junit-results is only supported with verify_traffic_body.jmx test plan." >&2
  exit 1
fi

# Create checksums directory for record_traffic_body.jmx
if [ "${test_plan}" = "record_traffic_body.jmx" ]; then
  mkdir -p checksums
fi

client_count="$(find "${client_dir}" -maxdepth 1 -type f -name '*.tsv' | wc -l | xargs)"
if [ "$client_count" -eq 0 ]; then
  echo "ERROR: no clients found in directory '${client_dir}'." >&2
  echo 'Perhaps you split the traffic into batches or did not process request.log?' >&2
  exit 1
fi
max_time="$(find "$client_dir" -type f -print0 | xargs -P1 -0 -n100 -- tail -n1 | grep -F $'\t' | cut -d$'\t' -f1 | sort -nru | head -n1)"
echo "Highest offset second (offset to start a request): ${max_time} seconds" >&2

# Count max lines across all CSV files (excluding header) for loop count
max_loops=1
for f in "${client_dir}"/*.tsv; do
  if [ -f "$f" ]; then
    lines=$(($(wc -l < "$f") - 1))
    if [ "$lines" -gt "$max_loops" ]; then
      max_loops="$lines"
    fi
  fi
done
echo "Max CSV lines (loop count): ${max_loops}" >&2

# Configure results file based on test plan and options
extra_props=(
  -Jjmeter.save.saveservice.response_data=false
  -Jjmeter.save.saveservice.samplerData=false
)
if [ -n "${junit_results:-}" ]; then
  # Use temp file for JTL results, will convert to JUnit XML
  results_file="${TMP_DIR}/results.jtl"
  # Enable assertion results in output for JUnit conversion
  extra_props+=(
    -Jjmeter.save.saveservice.assertion_results=all
    -Jjmeter.save.saveservice.assertion_results_failure_message=true
  )
else
  results_file="/dev/null"
fi

set -x
JVM_ARGS="${JVM_ARGS:--Djava.awt.headless=true}"
HEAP="${HEAP:--Xms1g -Xmx1g -XX:MaxMetaspaceSize=256m}"
export HEAP JVM_ARGS
time jmeter \
  -n -t "${test_plan}" \
  -Jprotocol="${protocol:-https}" \
  -Jhost="${host}" \
  -Jport="${port:-443}" \
  -Jclient_dir="${client_dir}" \
  -Jthreads="${client_count}" \
  -Jmax_loops="${max_loops}" \
  -Jhttp_user="${HTTP_USER:-}" \
  -Jhttp_password="${HTTP_PASSWORD:-}" \
  -Jhttp_connect_timeout="${HTTP_CONNECT_TIMEOUT:-5000}" \
  -Jhttp_response_timeout="${HTTP_RESPONSE_TIMEOUT:-30000}" \
  "${extra_props[@]}" \
  -l "${results_file}"
jmeter_exit=$?
set +x

# Sort checksum files by counter after recording (handles out-of-order responses)
if [ "${test_plan}" = "record_traffic_body.jmx" ] && [ -d checksums ]; then
  echo "Sorting checksum files by counter..." >&2
  for f in checksums/*.tsv; do
    if [ -f "$f" ]; then
      # Extract header, sort data by first column (counter), reassemble
      head -1 "$f" > "${TMP_DIR}/header.tsv"
      tail -n +2 "$f" | sort -t$'\t' -k1,1n > "${TMP_DIR}/data.tsv"
      cat "${TMP_DIR}/header.tsv" "${TMP_DIR}/data.tsv" > "$f"
    fi
  done
  echo "Checksum files sorted." >&2
fi

# Convert JTL to JUnit XML if requested
if [ -n "${junit_results:-}" ]; then
  echo "Converting JTL results to JUnit XML: ${junit_results}" >&2
  convert_jtl_to_junit < "${results_file}" > "${junit_results}"
  echo "JUnit XML report saved to: ${junit_results}" >&2
fi

exit ${jmeter_exit}

# Notes:
# - -n is for non-GUI execution
# - jmeter.save.saveservice.response_data=false Disables response body written
#   to results file.
# - jmeter.save.saveservice.samplerData=false Disables request data written to
#   results file.
# - -l /dev/null discards results (e.g. normally -l results.jtl)
