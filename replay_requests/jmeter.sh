jmeter -n -t replay_traffic.jmx \
  -Jprotocol=https \
  -Jhost=localhost \
  -Jport=8000 \
  -Jclient_dir=./clients \
  -l results.jtl
