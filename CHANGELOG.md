# nexus-requests-analyzer 1.4

- Major new feature: replaying traffic with JMeter.  JMeter can emulate
  production traffic or assert on the contents of traffic replayed.  If
  asserting on the contents of the responses it can create a junit XML file
  displaying test results.  See [replay requests README] for details.
- `nexus-requests-analyzer.sh` can unique requests by FIELD which helps filter a
  real request log for some test cases.

[replay requests README.md]: replay_requests/README.md

# nexus-requests-analyzer 1.3

- Fix first entry cuttoff not showing `useragent_id` in summary log.

# nexus-requests-analyzer 1.2

- Fix platform dependent logic such as script not working on MacOS.
- GNU awk is identified as a required dependency.

# nexus-requests-analyzer 1.1

- Bugfix output YAML format innacurate [#1]
- New YAML fields:
  - `user` (added to request record)
  - `elapsed_time` (added to request record)
  - `max_elapsed_time` (added to summary)
- Renamed `ip` to `host`.
- Renamed `download_bytes` to `bytes_sent`.
- `upload_bytes` removed since it was incorrect and in its place `elapsed_time`
  is parsed.
- Internally, record parsing was switched from `sed` to `awk`, because `sed`
  could only parse up to 9 groups in regex.  This comes with a slight
  performance hit (a few seconds longer on large logs) but unfortunately `sed`
  is not usable at all since the request record is longer than 9 fields.

[#1]: https://github.com/samrocketman/nexus-requests-analyzer/issues/1

# nexus-requests-analyzer 1.0

Initial release Features

- Converts requests.log to requests YAML.
- YAML output filtering:
  - By timestamp ranges (`--before` or `--after`)
  - By literal field value (`--field-value`)
  - By regex field value (`--filter-regex`).
  - Inverting provided filters to be exclusive. (`--invert-filter`)
- Summarize data by any number of fields:
  - `ip`
  - `timestamp` Common Log Format (CLF) timestamp.
  - `unix_time` Unix timestamp.
  - `http_method`
  - `path`
  - `repository`
  - `http_code`
  - `download_bytes`
  - `upload_bytes`
  - `useragent`
  - `useragent_id`
- Summarized data can output payload bytes or request count.
- Script can write YAML to stdout (for additional processing later) and read
  from stdin requests.log or requests YAML.

# Pre 1.0

Pre-release changelog can be found in my [home repository].

[home repository]: https://github.com/samrocketman/home/commits/89f8feadb986608f0418dcaf14ebe613feab9157/bin/nexus-requests-to-yaml.sh
