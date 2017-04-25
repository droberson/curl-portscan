#!/bin/bash

# curl-portscan.sh -- by Daniel Roberson @dmfroberson
#
# Portscans a host using curl, because its almost always available.
# It is no replacement for nmap, but gets the job done!
#

DEFAULT_PORTS="1-1024"
DEFAULT_TIMEOUT=1

echo "[+] curl-portscan.sh by Daniel Roberson @dmfroberson"
echo

usage() {
    echo "usage: $0 -t <target> -p <ports> [-m <timeout>] [-h]"
    echo "\t-t <target>\t-- singular hostname to scan"
    echo "\t-p <ports>\t-- ports to scan. ex: 1-1024,1055,3333-4444"
    echo "\t-m <timeout>\t-- curl timeout in seconds"
    echo "\t-h\t\t-- this help menu"

    exit 1
}

# set defaults
timeout=$DEFAULT_TIMEOUT
ports=$DEFAULT_PORTS

# CLI args.
while [ $# -gt 0 ]; do
    case $1 in
	-h) usage;
	    ;;
	-t) target=$2
	    shift
	    ;;
	-p) ports=$2
	    shift
	    ;;
	-m) timeout=$2
	    shift
	    ;;
	-*) echo "[-] Unknown flag: $1"
	    echo "[-] Exiting."
	    exit 1
	    ;;
	*) echo "[-] Unknown argument: $1"
	   echo "[-] Exiting."
	   exit 1
	   ;;
    esac

    shift
done

# Make sure a host is set!
if [ ! $target ]; then
    echo "[-] Must specify a host with -t"
    echo "[-] Exiting"
    exit 1
fi

# Make sure port range only has numbers, hyphens, and commas
if [[ ! "$ports" =~ ^[0-9,-]+$ ]]; then
    echo "[-] Syntax Error. Invalid port range: $ports"
    echo "[-] Exiting"
    exit 1
fi

# replace commas with space to make life easier on @dmfroberson
ports=`echo $ports | tr , ' '`

# deal with ranges of ports
for token in $ports; do
    if [[ $token == *"-"* ]]; then
	token=`echo $token | tr \- ' '`

	# Verify that the range makes sense
	tmp=($token)
	if [ ${tmp[0]} -ge ${tmp[1]} ]; then
	    echo "[-] Syntax error. Invalid port range: ${tmp[0]}-${tmp[1]}"
	    echo "[-] Exiting."
	    exit 1
	fi

	token=`seq -s ' ' $token`
    fi
    out="$out $token"
done

# uniq ports list
ports=`echo $out | xargs -n 1 | sort -nu | xargs`

# Do the scan.
echo "[+] Scanning `echo $ports | wc -w` ports on $target"

count=0
for port in $ports; do
    curl -s -m $timeout ${target}:${port} > /dev/null
    case $? in
	6) # Failed to resolve
	    echo "[-] Unable to resolve host: $target"
	    echo "[-] Exiting."
	    exit 1
	    ;;
	7) # Failed to connect
	    continue
	    ;;
	28) # Timeout
	    continue
	    ;;
    esac

    echo "[+] Port $port appears to be open."
    count=$((count+1))
done

echo
echo "[+] Done. $count ports open."
