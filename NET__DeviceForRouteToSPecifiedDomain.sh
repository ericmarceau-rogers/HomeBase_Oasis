#!/bin/sh

############################################################################################################
############################################################################################################
###
###	$Id: NET__DeviceForRouteToSPecifiedDomain.sh,v 1.1 2020/09/07 23:33:39 root Exp $
###
###	Report interface used to reach host for specified domain name.
###
############################################################################################################
############################################################################################################

usage()
{
	echo "\n\t Must provide command line parameter identifying domain name for the remote host, i.e. --domain {domain_name}.\n Bye!\n" ; exit 1
}

if [ $# -eq 0 ]
then
	usage
fi

while [ $# -gt 0 ]
do
	case $1 in
		--domain )	host=${2} ; shift ; shift ;;
		* ) echo "\n\t Invalid parameter '${1}' provided on command line." ; usage ;;
	esac
done

# get the ip of that host (works with dns and /etc/hosts. In case we get  
# multiple IP addresses, we just want one of them
host_ip=$(getent ahosts "${host}" | awk '{ print $1 ; exit}')

# only list the interface used to reach a specific host/IP. We only want the part
# between dev and src (use grep for that)
ip route get "${host_ip}" | grep -Po '(?<=(dev )).*(?= src| proto)'
