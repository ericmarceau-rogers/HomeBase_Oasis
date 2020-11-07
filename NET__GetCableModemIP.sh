#!/bin/sh

############################################################################################################
############################################################################################################
#
#	$Id: NET__GetCableModemIP.sh,v 1.6 2020/10/07 00:58:25 root Exp $
#       $Locker:  $
#       $State: Exp $
#       $Date: 2020/10/07 00:58:25 $
#
#	Tool for reporting the WAN-facing IP address of the cable modem behind which the computer is operating.
#
############################################################################################################
############################################################################################################

TMP=/tmp/tmp.`basename $0 ".sh" `.$$

INXI=`which inxi`

if [ -n "${INXI}" ]
then
	#           WAN IP: ...
	inxi -Nni -c0 | grep 'WAN IP:' | cut -f2 -d\: | cut -c2-
	exit 0
fi
echo "Unable to locate command 'inxi' in PATH." >&2


#
#	Strategy is to not rely on only one mechanism which might fail or go offline.
#	Instead probe multible and use value based on majority vote.
#	Given constantly evolving web services, this program will never remain static.
#	IP address is reported on stdout.  Failed sources are reported on stderr.
#

Source1()
{
	echo "NULL_Source1"
	return

	ModemIP=`w3m -no-cookie -dump http://whatismyip.com 2>>$TMP.1.err | grep 'Your Public IPv4 is:' | cut -f2 -d\: | awk '{ print $1 }' `
	if [ -n "${ModemIP}" ]
	then
		echo "${ModemIP}"
	else
		echo "NULL_Source1"
	fi
}

Source2()
{
	ModemIP=`w3m -no-cookie -dump http://whatismyipaddress.com 2>>$TMP.2.err | sed -e '1,/My IP Address Is/d' | head -2 | tail -1 `
	if [ -n "${ModemIP}" ]
	then
		echo "${ModemIP}"
	else
		echo "NULL_Source2"
	fi
}

Source3()
{
	echo "NULL_Source3"
	return

	ModemIP=`w3m -no-cookie -dump http://ifconfig.me/ip 2>>$TMP.3.err | awk '{ print $1 }' `
	if [ -n "${ModemIP}" ]
	then
		echo "${ModemIP}"
	else
		echo "NULL_Source3"
	fi
}

Source4()
{
	ModemIP=`dig +short myip.opendns.com @resolver1.opendns.com 2>>$TMP.4.err`
	if [ -n "${ModemIP}" ]
	then
		echo "${ModemIP}"
	else
		echo "NULL_Source4"
	fi
}

Source5()
{
	ModemIP=`wget http://ipecho.net/plain -O - -q  2>>$TMP.5.err; echo `
	if [ -n "${ModemIP}" ]
	then
		echo "${ModemIP}"
	else
		echo "NULL_Source5"
	fi
}

Source6()
{
	ModemIP=`curl ipecho.net/plain 2>>$TMP.6.err; echo `
	if [ -n "${ModemIP}" ]
	then
		echo "${ModemIP}"
	else
		echo "NULL_Source6"
	fi
}

Source7()
{
	ModemIP=`curl icanhazip.com 2>>$TMP.7.err`
	if [ -n "${ModemIP}" ]
	then
		echo "${ModemIP}"
	else
		echo "NULL_Source7"
	fi
}

Source8()
{
	echo "NULL_Source8"
	return

	curl http://ifconfig.me/all >$TMP.8 2>>$TMP.8.err

	ModemIP=`grep \. $TMP.8 | head -1 | awk '{ print $1 }' ` 
	if [ -n "${ModemIP}" ]
	then
		echo "${ModemIP}"
	else
		echo "NULL_Source8"
	fi
	rm -f ${TMP}.8*
}

IP_polling()
{
	echo "\t Polling Source1 ..." >&2
	Source1	# Need to build a timeout mechanism to prevent process hang
	echo "\t Polling Source2 ..." >&2
	Source2
	echo "\t Polling Source3 ..." >&2
	Source3	# Need to build a timeout mechanism to prevent process hang
	echo "\t Polling Source4 ..." >&2
	Source4
	echo "\t Polling Source5 ..." >&2
	Source5
	echo "\t Polling Source6 ..." >&2
	Source6
	echo "\t Polling Source7 ..." >&2
	Source7
	echo "\t Polling Source8 ..." >&2
	Source8	# Need to build a timeout mechanism to prevent process hang

}
IP_polling >$TMP
awk '{ print $1 }' ${TMP} >${TMP}.all

sort ${TMP}.all | uniq | grep -v 'NULL' >$TMP.uniq

lines=`wc -l ${TMP}.uniq | awk '{ print $1 }' `

if [ ${lines} -eq 1 ]
then
	read IP < $TMP.uniq
else
	for item in `cat $TMP.uniq`
	do
		echo "`grep ${item} $TMP | wc -l | awk '{ print $1 }' ` ${item}"
	done | sort -nr | head -1 | awk '{ print $2 }' >$TMP.ip

	read IP < $TMP.ip
fi


echo ${IP}

{
echo "Following Sources failed to report IP for the Cable Modem Router:"
grep -v "${IP}" ${TMP}
} | awk '{ printf("\t %s\n", $0 ) }' >&2



exit 0
exit 0
exit 0
