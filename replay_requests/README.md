# Replaying production-like traffic

`nexus-requests-analyzer.sh` is intended to convert Sonatype Nexus `request.log`
into a machine parseable format.  This directory contains an experiment of mine
to convert the request log into a jmeter traffic load which can be distributed
across multiple hosts (distributing the load means there's nearly no limit in
which I can replay traffic against another host).

# Setup

Download JMeter into the current directory or have `jmeter` in your `$PATH`.

    curl -sSfL https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-5.6.3.tgz | tar -xz

All scripts assume `nexus-requests-analyzer.sh` is also in your `$PATH`.

# JMeter support

Goals:

* Only support GET requests.
* Don't support authentication.  I may revisit this.
* Convert `requests.yaml` into jmeter client requests (replaying similar GET
  requests at the same frequency a previous request load occurred).
* Support jmeter replaying the traffic while managing host memory (in the case
  of this load test I do not care about reporting the results).
* Request traffic must be split across multiple unique clients (some clients can
  be per second).
* Because a desired request load on a destination Nexus host can surpass a
  single load testing host, I want the ability to spread the clients across a
  batch of many hosts initiating requests against Nexus.
* In the future, I may integrate all jmeter support into the
  `nexus_requests_analyzer.sh` script.  For now, these scripts just assume it is
  in my `$PATH`.

# Testing platform

These scripts were tested with:

* Java 11
* Apache JMeter 5.6.3

# Example

Process a request log into clients.  This will create a `clients` directory.

    ./create-clients.sh < ~/Downloads/request.log

Split the clients into batches (i.e. distributed hosts in order to spread client
traffic across a cluster).  The following spreads the number of clients across
multiple hosts.

    ./client-to-batches.sh 50

This will create a `batches/N` set of directories where `N` is meant to be
distributed to a separate physical host.  So if you have 50 batches, then it is
assumed you have 50 computers to execute the `jmeter.sh` script with a request
load.

The following example shows how to launch jmeter.sh.

    ./jmeter.sh -h nexus.example.com

Or if you're doing a batch execution you need to pass in the batch directory.
For a batch of 50 there will be 50 directories numbered 1-50.

    ./jmeter.sh -h nexus.example.com -d ./batches/1

# Other notes

50 is just an example which may depend on limitations of your cluster.  You may
find you need more or less.  You may also need to tune the JVM heap size for
`jmeter` by setting a `HEAP` environment variable.  I have already set this as
the default jmeter memory so that it's easy to know how to increase the memory
if need be.  You want min `-Xms` and max `-Xmx` to be equal when setting the
heap size.  For exammple, if you want a 10GB heap instead of a 1GB heap, then
set the HEAP variable.

    export HEAP='-Xms10g -Xmx10g -XX:MaxMetaspaceSize=256m'

# jmeter.sh help

Result of `./jmeter.sh --help`:

```
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
```
