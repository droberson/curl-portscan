#!/bin/bash

# curl-portscan.sh -- by Daniel Roberson @dmfroberson
#
# Portscans a host using curl, because its almost always available.
# It is no replacement for nmap, but gets the job done!
#

DEFAULT_PORTS="1-1024"
DEFAULT_TIMEOUT=1
PORTINDEX=""
VERBOSE=0

echo "[+] curl-portscan.sh by Daniel Roberson @dmfroberson"
echo

usage() {
    echo "usage: $0 -t <target> -p <ports> [-m <timeout>] [-h]"
    echo -e "\t-t <target>\t-- singular hostname to scan"
    echo -e "\t-p <ports>\t-- ports to scan. ex: 1-1024,1055,3333-4444"
    echo -e "\t-m <timeout>\t-- curl timeout in seconds"
    echo -e "\t-v\t\t-- toggle verbose output"
    echo -e "\t-h\t\t-- this help menu"

    exit 1
}

# Populate PORTINDEX array with service names
populate_port_index() {
    if [ ! -r "/etc/services" ]; then
	return
    fi

    services=$(grep "[0-9]/tcp" /etc/services)

    while read -r line; do
	tmp=($line)

	port=$(echo "${tmp[1]}" | cut -d / -f 1)
	service=${tmp[0]}

	PORTINDEX[$port]=$service
    done < <(echo "$services")
}

# Print service name if it exists in PORTINDEX array or unknown if it doesn't
get_port_index() {
    service=${PORTINDEX[$1]}

    if [ ! "$service" ]; then
	service="unknown"
    fi

    echo $service
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
	-p) # Deal with ports
	    if [ "$2" == "all" ]; then
		ports="1-65535"
	    else
		ports=$2
	    fi
	    shift
	    ;;
	-m) timeout=$2
	    shift
	    ;;
	-v) VERBOSE=$((VERBOSE+1))
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
if [ ! "$target" ]; then
    echo "[-] Syntax Error. Must specify a host with -t"
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
ports=$(echo "$ports" | tr , ' ')

# deal with ranges of ports
for token in $ports; do
    if [[ $token == *"-"* ]]; then
	token=$(echo "$token" | tr - ' ')

	# Verify that the range makes sense
	tmp=($token)
	if [ "${tmp[0]}" -ge "${tmp[1]}" ]; then
	    echo "[-] Syntax error. Invalid port range: ${tmp[0]}-${tmp[1]}"
	    echo "[-] Exiting."
	    exit 1
	fi

	token=$(seq -s ' ' "${tmp[0]}" "${tmp[1]}")
    fi
    out="$out $token"
done

# uniq ports list
# TODO: This is slow AF.. fix it.
echo -n "[+] Building list of ports.. "
ports=$(echo "$out" | xargs -n 1 | sort -nu | xargs)
echo "Done."

populate_port_index

# Do the scan.
portcount=$(echo "$ports" | wc -w)
echo [+] Scanning "$portcount" ports on "$target"
echo

count=0
for port in $ports; do
    service=$(get_port_index "$port")
    curl -s -m "$timeout" "${target}":"${port}" > /dev/null

    case $? in
	6) # Failed to resolve
	    echo "[-] Unable to resolve host: $target"
	    echo "[-] Exiting."
	    exit 1
	    ;;
	7) # Failed to connect
	    if [ $VERBOSE -eq 1 ]; then
		echo "[*] Port ${port}/${service} -- Failed to connect"
	    fi
	    continue
	    ;;
	28) # Operation Timeout
	    if [ $VERBOSE -eq 1 ]; then
		echo "[*] Port ${port}/${service} -- Operation Timeout"
	    fi
	    continue
	    ;;
    esac

    echo "[+] Port ${port}/${service} appears to be open."

    count=$((count+1))
done

echo
echo "[+] Done. $count ports open."
