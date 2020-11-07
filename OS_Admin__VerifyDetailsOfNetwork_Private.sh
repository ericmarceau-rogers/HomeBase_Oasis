#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: OS_Admin__VerifyDetailsOfNetwork_Private.sh,v 1.2 2020/08/19 21:04:51 root Exp $
###
###	This script will use nmap to report on scan of the computer's ports to identify any exposures.
###
####################################################################################################

##FIRSTBOOT##

BASE=`basename "$0" ".sh" `
STRT=`pwd`

REPORT="${STRT}/${BASE}_report.`date +%Y%m%d-%H%M%S `.txt"
rm -f "${REPORT}"

TMP=/tmp/${BASE}.tmp

testor=`which netstat`
if [ -z "${testor}" ]
then
	echo "\n\t Unable to find 'netstat' in PATH.  Unable to proceed.\n Bye!\n" ; exit 1
fi

echo "
####################################################################################################
#
#    Extent of scans attempted below are limited to 'host-private' NETWORK interfaces/services.
#
####################################################################################################"

###
###	Report current IP address for connection provided by ISP (i.e. IP address of firewall modem)
###
	modemIP=`curl ipecho.net/plain 2>>/dev/null ; echo `

echo "\n IP address for Firewall Modem = ${modemIP} ..."
echo "\t ( == ignored in this context == )"

myIP=`ip -o addr 2>&1 | grep -v 'lo\\\' | awk '{ print $4 }' | cut -f1 -d/ `
echo "\n Outward-facing NETWORK interface address = ${myIP} ..."
echo "\t ( == ignored in this context == )"

hostNAME=`hostname`
thisHOST=`grep ${hostNAME} /etc/hosts | awk '{ print $1 }' `
loclHOST=`grep localhost /etc/hosts | grep '^127' | awk '{ print $1 }' `

{

echo "\n\n Identifying host-private NETWORK interfaces ...\n"
###	FUTURES CONSIDER:	ip -o addr   OR   ip -a addr
INTERFACES=`netstat --interfaces | tail --lines=+3 | awk '{ print $1 }' | grep '^lo$' `

if [ "${thisHOST}" != "${loclHOST}" ]
then
	testor1=`echo "${INTERFACES}" | grep "${hostNAME}" `
	testor2=`echo "${INTERFACES}" | grep "${thisHOST}" `
	if [ -z "${testor1}" ]
	then
		if [ -z "${testor2}" ]
		then
			echo "\t No interface explicitly associated with  /etc/hosts  line entry  '`grep ${hostNAME} /etc/hosts`' ...\n"
		else
			echo "\t '${thisHOST}' is included in list of INTERFACES ..."
		fi
	else
		echo "\t '${hostNAME}' is included in list of INTERFACES ..."
	fi
fi

allIPs=""
count=0
for IF in `echo $INTERFACES `
do
	iNetAddr=`ifconfig ${IF} | grep 'inet' | awk '{ printf("%s\n", $2 ) ; }' `
	if [ -n "${iNetAddr}" ]
	then
		allIPs="${iNetAddr},${allIPs}"
		echo "\t Interface:  ${IF}|${iNetAddr}"
		count=`expr ${count} + 1 `
	fi
done
echo "\t Done."
#echo "allIPs= ${allIPs}"

###
###	The following 2 commands provide the same response
###
###	1) hostname --all-ip-addresses`
###
###	2) INTERFACES=`netstat --interfaces | tail --lines=+3 | awk '{ print $1 }' | grep -v '^lo$' `
###	   for IF in ${INTERFACES} ; do  ifconfig ${IF} | grep 'inet' | awk '{ print $2 }' ; done
###


if [ ${count} -eq 0 ] 
then
	echo "\n\t No interenet interfaces identified, hence no IP address identified.  Unable to proceed.\n Bye!\n" ; exit 1
fi

###
###		for IP in `hostname --all-ip-addresses` `hostname` localhost
###	is equivalent to
###		for IP in 192.168.0.11  OasisMini localhost
###

echo "\n\n Will perform scan using 'nmap' on above-reported to identify exposures ...\n\t (NOTE: this can take some time)\n"
for IP in `echo "${allIPs}" | awk 'BEGIN{ FS="," }{ for ( i = 1 ; i<=NF-1 ; i++ ) { print $i } ; }' `
do
	#COM="nmap -v -sS -p1-65535 --max-retries 3 --max-scan-delay 5 --max-parallelism 5 -A ${IP}"
	COM="nmap -v -sS -p1-65535 -T5 ${IP}"
	echo "Scanning ${IP}  [ ${COM} ] ...\n"
	${COM}
done 2>&1	# | awk '{ printf("\t %s\n", $0 ) ; }'

echo "\n\n Performing scans using 'netstat' to identify exposures ..."

for standard in inet inet6
do
	case ${standard} in
		inet )	descr="IPv4" ; dir="ipv4" ;;
		inet6 )	descr="IPv6" ; dir="ipv6" ;;
	esac

	if [ -d "/proc/sys/net/${dir}" ]
	then
		for protocol in tcp udp
		do
			echo "\nReport of ports listening to `echo ${protocol} | tr '[a-z]' '[A-Z]' ` on ${descr}:  \c"

			rm -f ${TMP}
			netstat --listening --numeric --${protocol} --program --${standard} 2>&1 >${TMP}
			testor=`grep '^'${protocol} ${TMP} | awk '{ print $4 }' | cut -f1 -d\: | grep -v "${myIP}" | sort | uniq `
			if [ -n "${testor}" ]
			then
				echo ""
				cat ${TMP} | awk '{ printf("\t %s\n", $0 ) ; }'
			else
				echo "None listening to external ..."
			fi
		done
	else
		echo "\nAll services for ${descr} standard have been disabled.  Skipping scan for those services ..."
	fi
done 2>&1 | awk '{ printf("\t %s\n", $0 ) ; }'

echo "\n\t Done.\n Bye!\n"

} 2>&1 | tee "${REPORT}" 


exit 0
exit 0
exit 0
