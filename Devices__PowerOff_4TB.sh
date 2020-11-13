#!/bin/sh

doSleep=0
if [ "$1" = "--sleep" ]
then
	doSleep=1
fi
TMP=/tmp/`basename "$0" ".sh" `.devices
Devices__ReportDiskParts.sh >${TMP} 2>>/dev/null
grep    'swap' ${TMP} > ${TMP}.swap
grep -v 'swap' ${TMP} > ${TMP}.data

grep DB005 ${TMP}.data | awk '{ print $1 }' | sort -n >  ${TMP}.allD
grep DB006 ${TMP}.data | awk '{ print $1 }' | sort -n >> ${TMP}.allD

grep DB005 ${TMP}.swap | awk '{ print $1 }' | sort -n >  ${TMP}.allS
grep DB006 ${TMP}.swap | awk '{ print $1 }' | sort -n >> ${TMP}.allS

BlockDevice=`cut -c1-8 ${TMP}.allD | sort | uniq `

if [ -n "${BlockDevice}" ]
then
	echo "\n Taking DATA partitions offline ..."
	for part in `cat ${TMP}.allD | cut -c9- `
	do
		#umount ${BlockDevice}${part}
		#RC=$?
		RC=1
		if [ ${RC} -ne 0 ]
		then
			udisksctl unmount -b ${BlockDevice}${part}
			RC=$?
		fi
		sync ; sync
		if [ ${RC} -eq 0 ]
		then
			echo "\t Partition ${part} on ${BlockDevice} was unmounted ..."
		fi
	done

	echo "\n Taking SWAP partitions offline ..."
	for part in `cat ${TMP}.allS | cut -c9- `
	do
		swapoff ${BlockDevice}${part}
		RC=$?
		if [ ${RC} -eq 0 ]
		then
			echo "\t Partition ${part} on ${BlockDevice} was removed from available SWAP partitions ..."
		fi
	done

	RC=1
	if [ ${doSleep} -eq 1 ]
	then
		hdparm -y ${BlockDevice}			###  for FULL power-off use  hdparm -Y ${BlockDevice}
		RC=$?
	fi

	if [ ${RC} -eq 0 ]
	then
		echo "\n\t 4TB MyBOOK USB Drive has been powered-down to standby.  Any access will re-awaken the drive.\n"
	else
		sync
		udisksctl power-off -b ${BlockDevice}
		RC=$?
		if [ ${RC} -eq 0 ]
		then
			echo "\n\t 4TB MyBOOK USB Drive has been powered-down.  You may unplug.\n"
			exit 0
		else
			echo "\n\t Command  'udisksctl power-off -b ${BlockDevice}'  FAILED ..."
		fi
	fi
else
	echo "\n\t Unable to identify device for udisksctl POWER-OFF directive.\n" ; exit 1
fi

exit 0
exit 0
exit 0


BlockDevice=`inxi -o | grep DB005 | cut -f2- -d\- | cut -f2 -d\: | awk '{ print $1 }' | cut -c1-8 | sort | uniq `

if [ -z "${BlockDevice}" ]
then
	echo "\n\t Unable to identify device for udisksctl POWER-OFF directive.\n" ; exit 1
fi


