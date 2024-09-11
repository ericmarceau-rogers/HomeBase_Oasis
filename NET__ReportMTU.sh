#!/bin/bash

while [ $# -gt 0 ]
do
	case "${1}" in
		"--self" )
			#https://www.whatismyip.com/
			destination_ip="174.116.29.27" ; shift ;;
		"--modem" ) 
			destination_ip="192.168.0.1" ; shift ;;
		"--isp" )
			destination_ip="40.85.218.2" ; shift ;;
		"--google" )
			#BACKUP IP:	destination_ip="8.8.4.4" ; shift ;;
			destination_ip="8.8.8.8" ; shift ;;
		"--cloudflare" )
			destination_ip="103.21.244.12" ; shift ;;
		* ) 
			destination_ip="$1" ; shift ;;
	esac
done

echo -e "\n\t destination_ip = '${destination_ip}' \n"

# Set initial packet size
packet_size=1200

# Loop to find the maximum MTU size
while true
do
	ping -4 -M do -c 1 -s $packet_size $destination_ip >/dev/null
	if [ $? -ne 0 ]
	then
		### ERROR MSG FORMAT:	ping: local error: message too long, mtu=1500
		echo -e "\nMaximum MTU size: $((packet_size + 28 - 2))"
		exit	#break
	fi
	packet_size=$((packet_size + 2))
	echo -e "\t testing MTU = ${packet_size} ..." >&2
done
