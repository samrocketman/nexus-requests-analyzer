# Replaying production-like traffic

Now that request.log is in a machine parsable format I'm going to experiment
with JMeter to see if I can get the utility to replay requests in a similar
manner.  The goal is to emulate prod-like traffic using a real request.log.

## JMeter support

[JMeter homepage](https://jmeter.apache.org/)

Goals:

* Convert `requests.yaml` into jmeter client requests (replaying similar GET
  requests at the same frequency a previous request load occurred).
* Use jmeter to replay the traffic.  I don't care about assembling test results.
  Just simulating the request load.
* If possible, support splitting traffic in a way the client request load can be
  sent from multiple client hosts in a cluster.  The idea here is a large
  traffic load may actually attempt to download more data than a single client
  host can handle.  So having multiple clients downloading at the same time
  would handle this concern.
* In the future, I may integrate all jmeter support into the
  `nexus_requests_analyzer.sh` script.  However, it will likely increase the
  lines of code by a lot.  I haven't decided.  For now, I plan to organize my
  thoughts in this subdirectory.
