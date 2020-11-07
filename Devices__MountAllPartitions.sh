#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: Devices__MountAllPartitions.sh,v 1.3 2020/11/07 18:57:57 root Exp $
###
###	Script to mount all partitions that are detected by the system and are not mounted.
###
####################################################################################################

reportDataLine()
{
	echo "\n ===>  ${dDev} ${dFtype} ${dLabel} ${dUuid} ${dStatus} ${dPath}   ..."
}

TMP=/tmp/`basename $0 ".sh" `.tmp
rm -f ${TMP}.*
rootPref=`df / | grep '/dev' | awk '{ print $1 }' | cut -c1-8 `
echo "\n\t ROOT device is '${rootPref}' ..."

DBG=0
VERB=0
DATA=0
SWAP=0
INPUT=0

while [ $# -gt 0 ]
do
	if [ "$1" = "--debug" ]
	then DBG=1 ; shift
	fi

	if [ "$1" = "--verbose" ]
	then VERB=1 ; shift
	fi

	if [ "$1" = "--input" ]
	then INPUT=1 ; shift
	fi
	
	if [ "$1" = "--data" ]
	then DATA=1 ; SWAP=0 ; shift ; sString="_F"
	fi
	
	if [ "$1" = "--swap" ]
	then SWAP=1 ; DATA=0 ; shift ; sString="_S"
	fi
done

#classParts=${TMP}.parts
allParts=${TMP}.parts

COM_repParts="Devices__ReportDiskParts.sh"

tester=`which ${COM_repParts} `
if [ -z "${tester}" ]
then
	echo "\n\t Unable to proceed.  Unable to locate '${COM_repParts}'\n\n Bye!\n" ; exit 1
fi
${COM_repParts} >${allParts} 2>>/dev/null

###	Report Format:
#/dev/sda14   ext4     DB001_F7   58f622cd-2841-4967-8def-86dd38192769   Mounted       /DB001_F7
#/dev/sdb1    ext4     DB002_F1   0aa50783-954b-4024-99c0-77a2a54a05c2   Not_Mounted   /media/ericthered/DB002_F1
#/dev/sdb2    swap     DB002_S1   7dd23169-56c6-4c2c-afbb-9e75d4de7652   Enabled       [SWAP]

if [ ${DBG} -eq 1 ] ; then echo "\n ======== Report from '${COM_repParts}' :" ; cat ${allParts} ; fi

showLiveSwapDetails()
{
	COM=" swapon --show 2>&1 >${TMP}.swap ; if [ ${DBG} -eq 1 ] ; then head -1 ${TMP}.swap ; fi ; cat ${TMP}.swap | grep '${dDev} ' "
	echo "${COM}" >${TMP}.job
	if [ ${VERB} -eq 1 ] ; then echo "\n\t COMMAND:  \"${COM}\" ..." ; fi
	. ${TMP}.job | awk '{ printf("\t %-12s  %-12s  %-12s  %-12s  %-12s\n", $1, $2, $3, $4, $5 ) }'

	if [ ${DBG} -eq 1 ] ; then echo "\n=== Contents of '${TMP}.swap' :" ; cat ${TMP}.swap ; fi
	if [ ${DBG} -eq 1 ] ; then echo "\n=== Contents of '${TMP}.job' :"  ; cat ${TMP}.job  ; fi
}

logicSWAP()
{
	if [ ${DATA} != 1 ]
	then
		if [ ${INPUT} -eq 1 ] ; then reportDataLine ; fi

		if [ "${dStatus}" = "Enabled" ]
		then

			if [ ${DBG} -eq 1 ] ; then echo "\n=== swap1 ===" ; fi
			if [ ${VERB} -eq 1 ]
			then echo "\n\t SWAP partition '${dLabel} [${dDev}|${dFtype}]' already mounted.  No action taken ..." ; fi

			showLiveSwapDetails
		else
			tUuid=`grep -v '^#' /etc/fstab | grep '^UUID=' | grep ${dUuid} | head -1 `
			if [ -n "${tUuid}" ]
			then
				# Format of swap entry in fstab
				# UUID=7dd23169-56c6-4c2c-afbb-9e75d4de7652	none	swap	sw,pri=1	0	0
				pri=`echo "${tUuid}" | awk '{ print $4 }' | cut -f2 -d\= `

				if [ ${DBG} -eq 1 ] ; then echo "\n=== swap2a ===" ; fi
				if [ -n "${pri}" ]
				then
					COM="swapon -v -p${pri} -U ${dUuid}"
				else
					COM="swapon -v -U ${dUuid}"
				fi
				if [ ${VERB} -eq 1 ] ; then echo "\n\t COMMAND:  '${COM}' ..." ; fi
			else
				tDev=`grep -v '^#' /etc/fstab | grep "^${dDev} " | head -1 `
				if [ -n "${tDev}" ]
				then
					# Format of swap entry in fstab
					# UUID=7dd23169-56c6-4c2c-afbb-9e75d4de7652	none	swap	sw,pri=1	0	0
					pri=`echo "${tDev}" | grep 'pri=' | awk '{ print $4 }' | cut -f2 -d= `
				fi

				if [ ${DBG} -eq 1 ] ; then echo "\n=== swap2b ===" ; fi
				if [ -n "${pri}" ]
				then
					COM="swapon -v -p${pri} ${dDev}"
				else
					COM="swapon -v ${dDev}"
				fi
				if [ ${VERB} -eq 1 ] ; then echo "\n\t COMMAND:  '${COM}' ..." ; fi
			fi

			eval ${COM} 2>&1 | awk '{ printf("\n\t   ACTION: %s\n", $0 ) }'

			showLiveSwapDetails
		fi

		#if [ ${DBG} -eq 1 ] ; then exit 0 ; fi
	fi
}

logicDATA()
{
	if [ ${SWAP} != 1 ]
	then
		if [ ${INPUT} -eq 1 ] ; then reportDataLine ; fi

		if [ "${dStatus}" = "Mounted" ]
		then
			if [ ${DBG} -eq 1 ] ; then echo "\n=== data1 ===" ; fi
			if [ ${VERB} -eq 1 ]
			then echo "\n\t DATA partition '${dLabel} [${dDev}|${dFtype}]' already mounted.  No action taken ..." ; fi
			#if [ ${VERB} -eq 1 ] ; then echo "\n\t COMMAND:  '${COM}' ..." ; fi

			case ${dPath} in
				/ )
					df -h / 2>&1 | grep '/dev'  | awk '{ printf("\t %s\n", $0 ) }'
					;;
				* )
					df -h 2>&1 | grep ${dLabel} | awk '{ printf("\t %s\n", $0 ) }'
					;;
			esac
		else
			tUuid=`grep -v '^#' /etc/fstab | grep '^UUID=' | grep ${dUuid} | head -1 `


			###	Auto-mounted USB
			#rw,codepage=437,iocharset=iso8859-1,shortname=mixed,utf8,uhelper=udisks2
			#uid=1000,gid=1000
			#fmask=0022,dmask=0022,nosuid,nodev,relatime,showexec,flush,errors=remount-ro

			case ${dFtype} in
				vfat )	OPTIONS_1="noauto,rw,user,group,exec,dev,suid,mand,async,dirsync"
					OPTIONS_2="uid=1000,gid=1000,codepage=437,iocharset=iso8859-1,shortname=mixed,utf8,uhelper=udisks2"
					#OPTIONS_2="codepage=437,iocharset=iso8859-1,shortname=mixed,utf8,uhelper=udisks2"
					mOptions="--options ${OPTIONS_1},${OPTIONS_2}"
				       	;;
				* )	mOptions="" ;;
			esac

			if [ -n "${tUuid}" ]
			then
				if [ ${DBG} -eq 1 ] ; then echo "\n=== data2a ===" ; fi
				#COM="echo \"mount -v -t ${dFtype} ${mOptions} --uuid ${dUuid} ${dPath}\""
				COM="mount -v -t ${dFtype} ${mOptions} --uuid ${dUuid} ${dPath}"
				if [ ${VERB} -eq 1 ] ; then echo "\n\t COMMAND:  '${COM}' ..." ; fi
				#COM="mount -v -t ${dFtype} ${mOptions} --uuid ${dUuid} ${dPath}"
			else
				if [ ${DBG} -eq 1 ] ; then echo "\n=== data2b ===" ; fi
				#COM="echo \"mount -v -t ${dFtype} ${mOptions} ${dDev} ${dPath}\""
				COM="mount -v -t ${dFtype} ${mOptions} ${dDev} ${dPath}"
				if [ ${VERB} -eq 1 ] ; then echo "\n\t COMMAND:  '${COM}' ..." ; fi
				#COM="mount -v -t ${dFtype} ${mOptions} ${dDev} ${dPath}"
			fi

			{	set -x
				eval ${COM}
				if [ $? -ne 0 ] ; then reportDataLine ; fi 
			} 2>&1 | awk '{ printf("\n\t   ACTION: %s\n", $0 ) }'

			df -h 2>&1 | grep ${dLabel} | awk '{ printf("\t %s\n", $0 ) }'
		fi

		#if [ ${DBG} -eq 1 ] ; then exit 0 ; fi
	fi
}

mountPartitions()
{
	while read dDev dFtype dLabel dUuid dStatus dPath
	do
		case ${dFtype} in
			swap )
				logicSWAP
				;;
			ext? | vfat | ntfs )
				logicDATA
				;;
			* )	echo "\n\t Logic has not been tested for partition filesystem type '${dFtype}'." >&2
				echo "  \t No action taken for partition labelled '${dLabel}' ..." >&2
				;;
		esac

	done <${classParts}
}

main()
{
	for class in DATA SWAP
	do
		classParts=${TMP}.${class}
		rm -f ${classParts}

		case ${class} in
			DATA )
				grep -v swap ${allParts} >${classParts}
				if [ \( ${VERB} -eq 1 \) -a \( ${SWAP} != 1 \) ]
				then
					echo "\n ======== Sub-group for DATA class partitions :" ; cat ${classParts}
				fi
				;;
			SWAP )
				grep    swap ${allParts} >${classParts}
				if [ \( ${VERB} -eq 1 \) -a \( ${DATA} != 1 \) ]
				then
					echo "\n ======== Sub-group for SWAP class partitions :" ; cat ${classParts}
				fi
				;;
		esac

		mountPartitions

		echo ""
	done
}

main

rm -f ${TMP}.*

exit 0
exit 0
exit 0
