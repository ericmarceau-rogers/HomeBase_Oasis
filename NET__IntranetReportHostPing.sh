#!/bin/sh

##########################################################################################################
###
###	$Id: NET__IntranetReportHostPing.sh,v 1.2 2020/09/08 00:32:56 root Exp $
###
###	Script using traceroute to scan for host response on the INTRANET and reporting the associated IP address.
###
##########################################################################################################

TMP=/tmp/`basename $0 ".sh" `.tmp
rm -f ${TMP}.*

BASE=192.168.0
routerIP=${BASE}.1

#thisHostIP=`ip -family inet route | grep src | awk '{ print $9 }' `
thisHostIP=`hostname -I | awk '{ print $1 }' `

probeONE()
{
	echo "\n ##########################################################################################################"
	echo " Probing:  ${BASE}.${IP} ..."

	echo "\t S---- TCPTR  TCP SYN Packets ---------------"
	( tcptraceroute -N -S -m 4 -q 2 --dnat ${BASE}.${IP} 2>&1 ) >${TMP}.s
	cat ${TMP}.s | awk '{ printf("\t\t %s\n", $0) }'

	echo "\t A---- TCPTR  TCP ACK Packets ---------------"
	( tcptraceroute -N -A -m 4 -q 2 --dnat ${BASE}.${IP} 2>&1 ) >${TMP}.a
	cat ${TMP}.a | awk '{ printf("\t\t %s\n", $0) }'

	echo "\t E---- TCPTR  ECN SYN Packets ---------------"
	( tcptraceroute -N -E -m 4 -q 2 --dnat ${BASE}.${IP} 2>&1 ) >${TMP}.e
	cat ${TMP}.e | awk '{ printf("\t\t %s\n", $0) }'

	echo "\t --------------------"

	notReached=`for file in ${TMP}.s ${TMP}.a ${TMP}.e ; do  tail -1 ${file} ; done | sort | uniq | tail -1 | grep -v 'Destination not reached' `
	nameField=`for file in ${TMP}.s ${TMP}.a ${TMP}.e ; do  tail -1 ${file} ; done | awk '{ print $2 }' | sort | uniq | tail -1 `
}

probeTWO()
{
	echo "\n\t U---- TR  UDP Packets ---------------"
	( traceroute -U --queries=2 --sim-queries=4 --max-hops=4 ${BASE}.${IP} 2>&1 ) >${TMP}.u 
	cat ${TMP}.u | awk '{ printf("\t\t %s\n", $0) }'

	echo "\n\t I---- TR  ICMP Packets ---------------"
	( traceroute -I --queries=2 --sim-queries=4 --max-hops=4 ${BASE}.${IP} 2>&1 ) >${TMP}.i 
	cat ${TMP}.i | awk '{ printf("\t\t %s\n", $0) }'

	echo "\n\t D---- TR  DCCP Packets ---------------"
	( traceroute -D --queries=2 --sim-queries=4 --max-hops=4 ${BASE}.${IP} 2>&1 ) >${TMP}.d 
	cat ${TMP}.d | awk '{ printf("\t\t %s\n", $0) }'

	echo "\t --------------------"
}


main()
{
	max=16

	while [ true ]
	do
		rm -f ${TMP}.*

		IP=${max}

		MSG=""
		test \( ${thisHostIP} = ${BASE}.${IP} \) && MSG=">> This host!! <<"
		test \( ${routerIP} = ${BASE}.${IP} \) && MSG=">> GateWay Router <<"

		probeONE

		if [ -n "${notReached}" ]
		then
			tester=`echo "${nameField}" | grep -v 192 `

			if [ -z "${tester}" ]
			then
				probeTWO
				echo "\n\t NON_RESPONSE:   ${BASE}.${IP}  ${MSG}"
			else
				echo "\n\t CONTACT:        ${BASE}.${IP}  ${MSG}     Hostname='${nameField}' ..."
			fi
		else
			        echo "\n\t NO_HOST_AT_IP:  ${BASE}.${IP}  ${MSG}"
		fi

		if [ ${max} = 1 ]
		then
			echo "\n ##########################################################################################################\n\n Done.\n"
			exit 0
		fi

		max=`expr ${max} - 1 `
	done
}

main


exit 0
exit 0
exit 0


##########################################################################################################
##########################################################################################################
##########################################################################################################


usePing()
{
	ping -c1  ${BASE}.${IP} 2>&1 >${TMP}

	#testor=`grep 'rtt min/avg/max/mdev' ${TMP} `
	testor=`tail -1 'rtt min/avg/max/mdev' ${TMP} `

	if [ -n "${testor}" ]
	then
		echo "###################################################################################################\n\t CONTACT:  ${BASE}.${IP}  ${MSG}"
		cat ${TMP}
	else
		testor=`grep "Destination Host Unreachable" ${TMP} `
		if [ -n "${testor}" ]
		then
			echo "###################################################################################################\n\t NO_HOST_AT_IP:  ${BASE}.${IP}  ${MSG}"
		else
			echo "###################################################################################################\n\t NON_RESPONSE:  ${BASE}.${IP}  ${MSG}"
			cat ${TMP}
		fi
	fi

}

