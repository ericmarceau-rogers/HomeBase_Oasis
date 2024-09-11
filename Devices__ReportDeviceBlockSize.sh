#!/bin/sh

###############################################################################################
###
###	$Id: Devices__ReportDeviceBlockSize.sh,v 1.2 2022/08/17 19:50:07 root Exp $
###
###	Script to report block size for devices.
###
###############################################################################################

BASE=`basename "$0" ".sh" `
TMP=/tmp/${BASE}.tmp
STRT=`pwd`

PartList="${TMP}.parts"

Devices__ReportDiskParts.sh 2>>/dev/null | grep -v 'swap' | sort -n --key=6 >${PartList}

###	Report Format:
#/dev/sdb1    ext4     DB001_F1   f56b6086-229d-4c17-8a5b-e68de1a4e73d   Mounted       /DB001_F1
#/dev/sdc3    ext4     DB003_F1   1a3ab410-2639-44aa-b0ca-72da4f8027e8   Not_Mounted   /site/DB003_F1
#/dev/sda1    swap     DB004_S1   22da1040-af94-4767-becf-aa9aa400f8f2   Enabled       [SWAP]
#/dev/sdb3    swap     DB001_S1   c37e53cd-5882-401c-8ba3-172531a082e9   Not_Enabled   [SWAP_OFFLINE]

if [ "$1" = "--disk" ]
then
	tune2fs -l $2 | grep -i block
	exit 0
fi

cat ${PartList} | awk '{ print $1, $3 }' |
while [ true ]
do
	read DISK DISKlabel
	if [ -z "${DISK}" ] ; then  echo "" ; exit 0 ; fi

	tune2fs -l ${DISK} | grep '^Block size' | cut -f2 -d\: | awk -v Label="${DISKlabel}" '{ printf("%s %6d\n", Label, $1 ) ; }'
done

exit 0
exit 0
exit 0

