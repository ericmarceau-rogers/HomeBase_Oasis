#!/bin/bash

####################################################################################################
###
###	Script to monitor ongoing backlog for journal commit of EXT4 partitions on ROOT or BACKUP USB drive
###
###	REF:  https://unix.stackexchange.com/questions/48235/can-i-watch-the-progress-of-a-sync-operation/48241#48241
###
###	History:
###	2024-12-12	E. Marceau	Initial script
###	2024-12-12	E. Marceau	Reworked with options and logic to allow choice
###					of drive:  ROOT drive or BACKUP USB drive
###
###	NOTE:	Script "Devices__ReportDiskParts.sh" is available from
###		   https://github.com/ericmarceau-rogers/HomeBase_Oasis
###
####################################################################################################
#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+

scan_interval=5
doRoot=1
labPref="DB001"
fType="ext4"

while [ $# -gt 0 ]
do
	case "${1}" in
		"--interval" ) scan_interval="${2}" ; shift ; shift ;;
		"--root" ) doRoot=1 ; labPref="DB001" ; shift ;;
		"--bkup" ) doRoot=0 ; labPref="DB005" ; shift ;;
		"--ftype" ) fType="${2}" ; shift ; shift ;;
		* ) printf "\n Invalid option used on command line.  Unable to proceed.\n Bye!\n\n" ; exit ;;
	esac
done

###
###	Path to root hard drive
###
if [ ${doRoot} -eq 1 ]
then
	prefDev=$( df / | grep '^/dev' | awk '{ print $1 }' | cut -f3 -d/ | sed 's+[0-9]++g' )
else
	prefDev=$( Devices__ReportDiskParts.sh | grep "${labPref}" | grep -v 'Not_' | grep "${fType}" | head -1 | awk '{ print $1 }' | cut -f3 -d/ | sed 's+[0-9]++g' )
fi

if [ -z "${prefDev}" ]
then
	printf "\n Options chosen did not locate the corresponding drive.  Unable to proceed.\n Bye!\n\n" ; exit 1
fi

echo ${prefDev}

physDev="/sys/block/${prefDev}"

cd "${physDev}"

#details=$( mount | grep "/${prefDev}" | grep 'ext4' | awk '{ print $1, $3 ; }' | sort --version-sort )
details=$( mount | grep "/${labPref}" | grep 'ext4' | awk '{ print $1, $3 ; }' | sort --version-sort )

#listDev=$( echo "${details}" | grep "/${dev}" | awk '{ print $1 }' )
#echo "${listDev}"
#baseDev=$( echo "${listDev}" | sed 's+/dev/++' )
#echo "${baseDev}"

printf "\n Partitions identified on ROOT device:\n"
echo "${details}" | awk '{ printf "\t %-12s %s\n", $2, $1 }END{ print "\n" }'

while [ true ]
do
	date
	printf "\n\n Journal queue per partition:\n"
	echo "${details}" | sed 's+/dev/++' |
	while [ true ]
	do
		read part label
		test $? -eq 0 || exit
		###
		###	Report value #9 of /sys/block/${dev}/${part}/stat
		###
		cat "${physDev}/${part}/stat" | awk -v lab="${label}" '{ printf("%15d  %-12s\n", $9, lab ) ; }'
	done
	sleep ${scan_interval}
	clear
done
