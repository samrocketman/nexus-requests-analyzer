# CLI Help Docs

Running

    ./nexus-requests-analyzer.sh -h
    # or
    ./nexus-requests-analyzer.sh --help

Results in the following output.

```
SYNOPSIS:
  nexus-requests-analyzer.sh [-f FIELD=VALUE] [-a TIMESTAMP] [-b TIMESTAMP] [-u FIELD] [-i] [-y] [--] [FILE...]
  nexus-requests-analyzer.sh [-g FIELD=VALUE] [-a TIMESTAMP] [-b TIMESTAMP] [-u FIELD] [-i] [-y] [--] [FILE...]
  nexus-requests-analyzer.sh [-r] [-y] [--] [FILE...]
  nexus-requests-analyzer.sh [-b] [-c] [-l LIMIT] [-s FIELD] [-t COUNT] [-y] [--] [FILE...]
  nexus-requests-analyzer.sh [-h|--help]

DESCRIPTION:
  Processes a Sonatype Nexus request log and attempts to make sense of a large
  volume of requests.  Intended to help track down sources of request load
  spikes (amount and data).

  Converts a Sonatype Nexus request log into YAML.

INPUT OPTIONS:
  Changes input processing behavior.

  -y, --yaml
    Force assuming YAML input.  Skips request log preprocessing to YAML.  This
    option may only be required if you're assembling your own YAML and the
    binary header is not "requests:".

  --
    Stop processing options and treat all remaining arguments as files.

REQUEST OUTPUT OPTIONS:
  Dumps request log as YAML output.  Running this script reading a request log
  already converted to YAML cuts run time by roughly half.  These options
  always result in a YAML dump of requests.

  -a TIMESTAMP, --after TIMESTAMP
    Filter requests occurring after (inclusive) the TIMESTAMP.  TIMESTAMP can
    be either a Common Log Format (CLF) timestamp or a unix_time timestamp.

  -b TIMESTAMP, --before TIMESTAMP
    Filter requests occurring before (inclusive) the TIMESTAMP.  TIMESTAMP can
    be either a Common Log Format (CLF) timestamp or a unix_time timestamp.

  -f FIELD=VALUE, --filter-value FIELD=VALUE
    Filter requests by a literal value in a particular field and exit.

  -g FIELD=VALUE, --filter-regex FIELD=VALUE
    Filter requests by partial or regex in a particular field and exit.

  -i, --invert-filter
    Invert matching when using --filter-regex or --filter-value.

  -r, --requests
    Print raw YAML of requests and exit.  Other options may filter output.

  -u FIELD, --unique FIELD
    Filter requests to only include the first occurrence of each unique value
    in the specified FIELD.  For example, -u path will output only one
    request per unique path value.

SUMMARIZING DATA OPTIONS:
  -s FIELD, --sumarize-by FIELD
    Print a summary grouped by a particular request FIELD.
    Default: repository

  -c, --count-requests
    Count number of requests instead of bytes of requested transfer.

  -t COUNT, --threshold COUNT
    A summarized item must be above a threshold of COUNT in order to be printed
    (e.g. bytes or request count).  --limit-summary LIMIT can be disabled for
    this option to be most effective.
    Default: 0 (Include all)

  -l LIMIT, --limit-summary LIMIT
    Summarized items will print up to LIMIT entries.
    Disable with: --limit-summary 0
    Default: 10 (or 10 entries)

  -n, --bytes-only
    By default, this script will convert bytes to human readable bytes like KB,
    MB, GB, or TB.  If this options is passed only the raw bytes value is
    output in a summary of sent bytes.

EXAMPLES:
  Usage examples which help you make the most of this utility.  It is designed
  to process input from Nexus request logs or its own YAML.

  Convert a large request log to YAML for analyzing further.

    nexus-requests-analyzer.sh -r path/to/requests.log > /tmp/requests.yaml
    # summarize the output (all examples work with requests.yaml)
    nexus-requests-analyzer.sh /tmp/requests.yaml

  Summarize a particular day or hour in a request log.

    grep 'some timestamp' path/to/requests.log | \
      nexus-requests-analyzer.sh

  Get a spread of HTTP methods used by request count.

    nexus-requests-analyzer.sh -s http_method -c path/to/requests.log

  Show all host addresses which transferred more than 1GB without limit.

    nexus-requests-analyzer.sh -s host -t 1000000000 -l 0 path/to/requests.log

  Print largest data transfers requested within same second period.

    nexus-requests-analyzer.sh -s timestamp path/to/requests.log

  Find all host addresses which downloaded or uploaded a particular file.  You
  must first dump all requests filtered by the file path followed by
  summarizing requests by host field.

    nexus-requests-analyzer.sh -r -f path='/repository/example/file' path/to/requests.log | \
      nexus-requests-analyzer.sh -y -s host -l 0

  For a specific repository, get the top 10 bytes transferred by file within
  the given repository.

    nexus-requests-analyzer.sh -r -f repository=example path/to/requests.log | \
      nexus-requests-analyzer.sh -y -s path

  For a specific repository, get the top 20 amount of requests by path.  Use yq
  to pretty print the result.

    nexus-requests-analyzer.sh -r -f repository=example path/to/requests.log | \
      nexus-requests-analyzer.sh -y -c -s path -l 20 | \
      yq -P

AUTHOR:
  Copyright (c) 2026 Sam Gleske
  https://github.com/samrocketman/nexus-requests-analyzer
  MIT Licensed
```
