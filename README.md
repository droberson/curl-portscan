# curl-portscan.sh

This port scans a host using curl. Useful for boxes that don't have netcat,
nmap, or anything good on them. Almost every host has curl because its not
typically viewed as malicious.

This scanner sucks, but gets the job done.

Scanning can also be done via a 1 liner:
	$ for i in {1..1024}; do curl -s -m 1 localhost:$i >/dev/null; if [ ! $? -eq 7 ] && [ ! $? -eq 28 ]; then echo open: $i; fi; done


## TODO

- Add support for IP ranges and/or CIDR
- "Fast" scan using /etc/services for common ports
- Detect DNS servers that catch unresolvable hosts and serve up a crappy page
- Logging
- Delay between trying ports
- Randomize port list
- Shortened version that can be copied/pasted easier through crappy netcat shells

