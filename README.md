# curl-portscan.sh

This port scans a host using curl. Useful for boxes that don't have
netcat, nmap, or anything good on them. Almost every host has curl
because its not typically viewed as malicious.

This scanner sucks, but gets the job done.

Scanning can also be done via a 1 liner to avoid writes to disk:

	 $ for i in {1..1024}; do curl -s -m 1 localhost:$i >/dev/null; if [ ! $? -eq 7 ] && [ ! $? -eq 28 ]; then echo open: $i; fi; done

## WHY? -- "Just use nmap, you weirdo!"

- Bear Grylls drinks his own urine in extreme situations so he doesn't
  die of dehydration. Maybe he should have cracked open an ice cold
  bottle of Smart Water instead!

- A prisoner picked his handcuff keys using a paperclip he found on
  the ground. Perhaps the handcuff key would have been a better
  choice?
  
- You are a professional carpenter on a job and your hammer
  breaks. You have a spare hammer in your tool box, but it isn't as
  good as the one you broke. Do you just go home for the day?

- Living off the land. No need to install extra shit.

- While its pretty common for sysadmins to remove netcat and nmap from
  systems in the name of security, curl is nearly always installed on
  Linux systems.

## TODO

- Add support for IP ranges and/or CIDR
- "Fast" scan using /etc/services for common ports
- Detect DNS servers that catch unresolvable hosts and serve up a crappy page
- Logging
- Delay between trying ports
- Randomize port list
- Shortened version that can be copied/pasted easier through crappy netcat shells

