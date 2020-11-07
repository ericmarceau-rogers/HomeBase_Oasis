#!/bin/sh

#####################################################################################
###
###	$Id: NET__IdentifyConnectionRemoteHost.sh,v 1.1 2020/09/06 21:56:12 root Exp $
###
###	Script to report on open network connections; option to report only IPs for remote/local interface.
###
#####################################################################################

TMP=/tmp/`basename "$0" ".sh" `.tmp
rm -f ${TMP}

indir=0
list=0

while [ $# -gt 0 ]
do
	case $1 in
		--iplist ) list=1 ; indir=0 ; shift ;;
		--in )     list=1 ; indir=1 ; shift ;;
		--out )    list=1 ; indir=0 ; shift ;;
		* ) echo "\n\t Invalid parameter '$1' used on command line.  Only valid options:  [ --iplist | --in | -out ] \n Bye!\n" ; exit 1 ;;
	esac
done

#IFACE=`ifconfig | grep 'BROADCAST' | cut -f1 -d\: `
#IP=`ifconfig ${IFACE} | grep 'inet ' | awk '{print $2}' | cut -f2 -d\: `
#echo $IP

IP=`hostname -I | awk '{ print $1 }' `
	if [ -z "${IP}" ]
	then
		echo "\n\t Unable to get IP address of this host.\n"
		exit 1
	fi

for remote in `ss -a -e -p | grep $IP | awk '{print $6}' | cut -f1 -d\: `
do
	if [ -z "${remote}" ]
	then
		echo "\n\t Unable to get address of remote host.\n"
		exit 1
	fi

	#nslookup  ${remote}	>sample.${remote}.nslookup
	#whois     ${remote}	>sample.${remote}.whois
	#ping -c 1  ${remote}	| tee sample.${remote}.ping
	ss -a -e -p | grep $IP | 
	awk '{ printf("%s %-10s %2s %2s %21s %21s %-44s %-9s %-11s %s %s %s\n", $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12 ) ; }'

done | sort | uniq > ${TMP}

if [ ${list} -eq 1 ]
then
	if [ ${indir} -eq 1 ]
	then
		awk '{ print $5 }' ${TMP} | cut -f1 -d\: | awk '{ print $1 }' | sort -n | uniq 
	else
		awk '{ print $6 }' ${TMP} | cut -f1 -d\: | awk '{ print $1 }' | sort -n | uniq 
	fi
else
	cat ${TMP}
fi

exit 0
exit 0
exit 0
