# Sonatype Nexus Requests Analyzer

Processes a [Sonatype Nexus request.log][request.log] and attempts to make sense
of a large volume of requests.  Intended to help track down sources of request
load spikes (amount and data).

Converts a Sonatype Nexus request log into YAML.

## Dependencies

Most of these are built into Linux distributions except for maybe jq and yq
which can be downloaded from their GitHub releases.

* GNU bash
* BSD or GNU coreutils
* GNU awk (on MacOS `brew install gawk`)
* Python 2.7+ or Python 3.0+ (core Python only; no libraries necessary).
* jq - [jqlang.org](https://jqlang.org/)
* yq - [mikefarah/yq](https://github.com/mikefarah/yq)
* Apache JMeter [if replaying requests](replay_requests/README.md)

## Examples

Usage examples which help you make the most of this utility.  It is designed to
process input from Nexus request logs or its own YAML.  See [help] for options
documentation.

Convert a large request log to YAML for analyzing further.

```bash
nexus-requests-analyzer.sh -r path/to/requests.log > /tmp/requests.yaml
# summarize the output (all examples work with requests.yaml)
nexus-requests-analyzer.sh /tmp/requests.yaml
```

Summarize a particular day or hour in a request log.

```bash
grep 'some timestamp' path/to/requests.log | \
  nexus-requests-analyzer.sh
```

Get a spread of HTTP methods used by request count.

```bash
nexus-requests-analyzer.sh -s http_method -c path/to/requests.log
```

Show all host addresses which transferred more than 1GB without limit.

```bash
nexus-requests-analyzer.sh -s host -t 1000000000 -l 0 path/to/requests.log
```

Print largest data transfers requested within same second period.

```bash
nexus-requests-analyzer.sh -s timestamp path/to/requests.log
```

Find all host addresses which downloaded or uploaded a particular file.  You
must first dump all requests filtered by the file path followed by summarizing
requests by `host` field.

```bash
nexus-requests-analyzer.sh -r -f path='/repository/example/file' path/to/requests.log | \
  nexus-requests-analyzer.sh -y -s host -l 0
```

For a specific repository, get the top 10 bytes transferred by file within the
given repository.

```bash
nexus-requests-analyzer.sh -r -f repository=example path/to/requests.log | \
  nexus-requests-analyzer.sh -y -s path
```

For a specific repository, get the top 20 amount of requests by path.  Use yq to
pretty print the result.

```bash
nexus-requests-analyzer.sh -r -f repository=example path/to/requests.log | \
  nexus-requests-analyzer.sh -y -c -s path -l 20 | \
  yq -P
```

# Limitations

- Script assumes Nexus is hosted on its own domain.  Workaround is substitute
  the request log path with `sed` so that URL paths appear to be top-level.
- Only `/repository/` URL requests are analyzed.  This script will not process
  all requests because its intent is to analyze download patterns of hosted
  artifacts.

# License and Author

[MIT Licensed] - Copyright 2026 Sam Gleske - https://github.com/samrocketman/nexus-requests-analyzer

[request.log]: https://help.sonatype.com/en/logging.html#UUID-a3b553aa-d022-8659-b218-87e20786f957_bridgehead-idm234815356852628
[help]: help.md
[MIT Licensed]: LICENSE
