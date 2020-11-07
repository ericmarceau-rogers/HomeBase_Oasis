#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: Devices__ReportSmartDetails.sh,v 1.2 2020/10/19 17:20:07 root Exp $
###
###	Script to report all detected partitions, all unique physical devices and saves a report with SMART details for each device.
###
####################################################################################################


BASE=`basename "$0" ".sh" `
TMP=/tmp/${BASE}.partitions
rm -f ${TMP}*

if [ -n "${Local}" ]
then
	REPORT_DIR="${Local}/Devices__SMART"
	if [ ! -d ${REPORT_DIR} ]
	then
		mkdir ${REPORT_DIR}
	fi
else
	REPORT_DIR="."
fi

Now=`date '+%Y%m%d-%H%M' `

Devices__ReportDiskParts.sh  | sort -k3 2>>/dev/null  >${TMP}

###	Report Format:
#/dev/sda7    ext4     DB001_F2   7e9a663e-ff1d-4730-8544-c37519056b6f   Mounted       /DB001_F2
#/dev/sdc1    ext4     DB002_F1   0aa50783-954b-4024-99c0-77a2a54a05c2   Mounted       /media/ericthered/DB002_F1
#/dev/sdc2    swap     DB002_S1   7dd23169-56c6-4c2c-afbb-9e75d4de7652   Enabled       [SWAP]

echo "\n =================================================================================\n Complete Partition Report:"
cat ${TMP} | awk '{ printf("\t %s\n", $0 ) }'


for Device in `cat ${TMP} | awk '{ print $1 }' | cut -c1-8 | sort | uniq `
do
	grep ${Device} ${TMP} | awk '{ print $3, $1 }' | sort -n | head -1
done | sort | awk '{ print $2 }' | cut -c1-8 >${TMP}.dolist

echo "\n =================================================================================\n Unique Devices Report:"
cat ${TMP}.dolist | awk '{ printf("\t %s\n", $0 ) }'

for Device in `cat ${TMP}.dolist `
do
	Label=`grep ${Device} ${TMP} | grep '_F1' | awk '{ print $3 }' `
	echo "\n Generating SMART report for ${Label} [${Device}] ..."

	smartctl -a ${Device} >${REPORT_DIR}/${BASE}__${Label}.${Now}.txt
	ls -l ${REPORT_DIR}/${BASE}__${Label}.${Now}.txt | awk '{ printf("\t %s\n", $0 ) }'
done

echo "\n Done [`basename $0 `].\n"


exit 0
exit 0
exit 0
