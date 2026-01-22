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
