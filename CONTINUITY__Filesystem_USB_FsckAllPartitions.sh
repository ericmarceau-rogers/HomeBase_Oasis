#!/bin/sh

BASE=`basename "$0" ".sh" `
TMP="/tmp/tmp.$$.${BASE}"

Devices__ReportDiskParts.sh | grep 'block:scsi:usb:pci' | grep -v 'swap' | awk '{ printf("%s|%s|%s\n", $1, $2, $3 ) }' >${TMP}

if [ ! -s ${TMP} ] ; then  echo "\n\t No USB partitions detected.\n Bye!\n" ; exit 0 ; fi

while [ true ]
do
	read line
	if [ -z "${line}" ] ; then  exit 0 ; fi
	echo "\n================================================================================="
	date
	DEVICE=`echo "${line}" | awk -F \| '{ print $1 }' `
	FSTYPE=`echo "${line}" | awk -F \| '{ print $2 }' `
	LABEL=`echo "${line}" | awk -F \| '{ print $3 }' `
	echo "${LABEL}  => ${DEVICE} [${FSTYPE}]"

	COMMAND="fsck -V -C -t ${FSTYPE} ${DEVICE} -f -y"
	${COMMAND}
done <${TMP}
