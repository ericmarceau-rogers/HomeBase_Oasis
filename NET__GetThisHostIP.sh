#!/bin/sh

###############################################################################################
###
###	$Id: NET__GetThisHostIP.sh,v 1.5 2020/11/07 21:20:07 root Exp $
###
###	Script to obtain label for INTERNET interface device on this host and the IP addess associated with it.
###
###############################################################################################

TMP=/tmp/`basename $0 ".sh" `.tmp

###	Note: inxi behaviour changed with Ubuntu 20.04
###	New output format:
#Network:   Device-1: Qualcomm Atheros AR8121/AR8113/AR8114 Gigabit or Fast Ethernet driver: ATL1E 
#           IF: enp2s0 state: up speed: 1000 Mbps duplex: full mac: 00:26:18:8a:b5:7a 
#           IP v4: 192.168.0.11/24 type: dynamic noprefixroute scope: global 
#           WAN IP: 174.115.236.50 

v4=1
v6=0
ipVER=v4

doINFO=0	# 0= BOTH, 1= IP, 2= INTERFACE
doIP=1
doInt=0

if [ $# -gt 0 ]
then
	for opt in $*
	do
		case ${opt} in
			--ipv4 )	v4=1	; v6=0		; ipVER="v4"	; shift ;;
			--ipv6 )	v6=1	; v4=0		; ipVER="v6"	; shift ;;
			--ip )		doINFO=1	; shift ;;
			--interface )	doINFO=2	; shift ;;
			* ) echo "\n\t Usage:  `basename $0 `  [ --ipv4 | --ipv6 ] [ --ip | --interface ]\n\t\t (note: defaults are '--ip' and '--ipv4' )\n Bye!\n" ; exit 1 ;;
		esac
	done
fi

INXI=`which inxi `

if [ -n "${INXI}" ]
then
	if [ "${ipVER}" = "v4" ]
	then
		RAW=`inxi -Nni -c0 | grep "IP ${ipVER}:" `
        	address=`echo "${RAW}" | cut -f2 -d\: | cut -f1 -d/ | cut -c2- | awk '{ print $1 }' | sort | uniq `
	fi

	if [ -d "/proc/sys/net/ip${ipVER}" -a "${ipVER}" = "v6" ]
	then
		###	This logic to be confirmed
		#address=""
		RAW=`inxi -Nni -c0 | grep "IP ${ipVER}:" `
        	address=`echo "${RAW}" | cut -f2 -d\: | cut -f1 -d/ | cut -c2- | awk '{ print $1 }' | sort | uniq `
	fi

	iNetFace=`inxi -Nni -c0 | grep 'IF:' | cut -f2 -d\: | cut -c2- | awk '{ print $1 }' | sort | uniq `

	case ${doINFO} in
		0 )	echo "${iNetFace} ${address}" | awk '{ printf("\t %8s = %s\n", $1, $2 ) }' ;;
		2 )	echo "${iNetFace}" | awk '{ printf("%s\n", $1 ) }' ;;
		1 )	if [ "${address}" = "N/A" ]
			then
				echo "NO_ADDRESS: IP${ipVER} functionality and support is disabled on this host."
			else
				echo "${address}" | awk '{ printf("%s\n", $1 ) }'
			fi
		 	;;
	esac

       	exit 0
fi
echo "Unable to locate command 'inxi' in PATH." >&2

rm -f ${TMP}
ifconfig | grep 'flags=' | grep -v 'LOOPBACK' | grep 'BROADCAST' | cut -f1 -d\: | sort | uniq >${TMP}

rm -f ${TMP}.6
ifconfig | grep 'inet6' >${TMP}.6

if [ -s ${TMP} ]
then
	for iNetFace in `cat ${TMP} | sort | uniq `
	do
		if [ ${v4} -eq 1 ]
		then
			#address=`ifconfig ${iNetFace} | grep 'inet ' | awk '{print $2}' | cut -f2 -d\: `
			address=`ifconfig ${iNetFace} | grep 'inet ' | grep -v 'inet6' | awk '{print $2}' | sort | uniq `

			case ${doINFO} in
				0 ) echo "${iNetFace} ${address}" | awk '{ printf("\t %8s = %s\n", $1, $2 ) }' ;;
				1 ) echo "${address}" | awk '{ printf("%s\n", $1 ) }' ;;
				2 ) echo "${iNetFace}" | awk '{ printf("%s\n", $1 ) }' ;;
			esac
		fi

		if [ -d "/proc/sys/net/ip${ipVER}" -a ${v6} -eq 1 ]
		then
			if [ -s ${TMP}.6 ]
			then
				for address in `ifconfig ${iNetFace} | grep 'inet6' | awk '{print $2}' | sort | uniq `
				do
					case ${doINFO} in
						0 ) echo "${iNetFace} ${address}" | awk '{ printf("\t %8s = %s\n", $1, $2 ) }' ;;
						1 ) echo "${address}" | awk '{ printf("%s\n", $1 ) }' ;;
						2 ) echo "${iNetFace}" | awk '{ printf("%s\n", $1 ) }' ;;
					esac
				done
			else
				if [ ${doINFO} -eq 0 ]
				then
					echo "NO_ADDRESS: IPv6 functionality and support is disabled on this host."
				else
					echo ""
				fi
			fi
		fi
	done
fi

rm -f ${TMP}*
exit 0
