# Replaying production-like traffic

`nexus-requests-analyzer.sh` is intended to convert Sonatype Nexus `request.log`
into a machine parseable format.  This directory contains an experiment of mine
to convert the request log into a jmeter traffic load which can be distributed
across multiple hosts (distributing the load means there's nearly no limit in
which I can replay traffic against another host).

# Prerequisites

Download [JMeter](https://jmeter.apache.org/) into the current directory or have
`jmeter` in your `$PATH`.

    curl -sSfL https://dlcdn.apache.org//jmeter/binaries/apache-jmeter-5.6.3.tgz | tar -xz

All scripts assume `nexus-requests-analyzer.sh` is also in your `$PATH`.

# Limitations

* Only supports GET requests.

# Features

- Converts `requests.yml` into jmeter client requests (TSV file of requests).
- Low memory footprint while replaying requests.  JMeter isn't being used as a
  request test tool in this case so most of its memory intense features are
  discarded.
- Request traffic can be split into batches where the request load can be
  distributed across a cluster of hosts acting as a group of clients.

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
