#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###     $Id: Devices__UnmountAllPartitions.sh,v 1.2 2020/11/07 19:01:17 root Exp $
###
###     Script to unmount all partitions that detected by the system, with exception of that which is not the current ROOT filesystem.
###
####################################################################################################

reportDataLine()
{
	if [ -n "${ERROR}" ]
	then
		echo "\n ===>  *FAILED*  ${dDev} ${dFtype} ${dLabel} ${dUuid} ${dStatus} ${dPath}   ..."
	else
		echo "\n ===>  ${dDev} ${dFtype} ${dLabel} ${dUuid} ${dStatus} ${dPath}   ..."
	fi
}

TMP=/tmp/`basename $0 ".sh" `.tmp
rm -f ${TMP}.*
rootPref=`df / | grep '/dev' | awk '{ print $1 }' | cut -c1-8 `
echo "\n\t ROOT device is '${rootPref}' ..."

USB=0
DBG=0
VERB=0
DATA=0
SWAP=0
INPUT=0
noroot=0
loginName=`basename ${HOME} `


while [ $# -gt 0 ]
do
	if [ "$1" = "--usb" ]
	then USB=1 ; shift
	fi

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

	if [ "$1" = "--noroot" ]
	then DATA=1 ; SWAP=0 ; shift ; sString="_F" ; noroot=1
	fi
done

# Format of report from Devices__ReportDiskParts.sh
#/dev/sda1    ext4     DB001_F1   f56b6086-229d-4c17-8a5b-e68de1a4e73d   Mounted       /
#/dev/sda3    swap     DB001_S1   c37e53cd-5882-401c-8ba3-172531a082e9   Enabled       [SWAP]
#/dev/sda4    swap     DB001_S2   227afe2c-ee1a-4065-bc9d-24040ea01849   Enabled       [SWAP]
#/dev/sda5    swap     DB001_S3   c16e9d3b-0ea5-4c2b-808b-9962509f04dd   Enabled       [SWAP]
#/dev/sda6    swap     DB001_S4   f9441354-ee42-4cef-912e-82e10a3d18af   Enabled       [SWAP]
#/dev/sda7    ext4     DB001_F2   7e9a663e-ff1d-4730-8544-c37519056b6f   Mounted       /DB001_F2
#/dev/sda8    ext4     DB001_F3   4f7d4192-b136-4a94-b06b-736f76155816   Mounted       /DB001_F3
#/dev/sda9    ext4     DB001_F4   7f37ffd4-779a-46c6-b440-f384fb75eb98   Mounted       /DB001_F4
#/dev/sda10   swap     DB001_S5   3b9a2c7a-67d4-4de7-ae66-214937dc47f4   Enabled       [SWAP]
#/dev/sda11   swap     DB001_S6   78b04c8c-8ace-4b46-817d-7059aa1668b7   Enabled       [SWAP]
#/dev/sda12   ext4     DB001_F5   17a1582c-7dd2-4ea4-bc69-db6d2317ff92   Mounted       /DB001_F5
#/dev/sda13   ext4     DB001_F6   f255b2a2-8549-451f-9b97-f6ebe66c8d3a   Mounted       /DB001_F6
#/dev/sda14   ext4     DB001_F7   58f622cd-2841-4967-8def-86dd38192769   Mounted       /DB001_F7
#/dev/sdb1    ext4     DB002_F1   0aa50783-954b-4024-99c0-77a2a54a05c2   Not_Mounted   /media/ericthered/DB002_F1
#/dev/sdb2    swap     DB002_S1   7dd23169-56c6-4c2c-afbb-9e75d4de7652   Enabled       [SWAP]
#/dev/sdb3    ext4     DB002_F2   7e10c52e-fe20-497b-beab-f67e75cf7d83   Not_Mounted   /media/ericthered/DB002_F2
#/dev/sdc1    ext4     DB003_F1   12d9cfcc-8da0-4ba6-a7f8-cd08870c2890   Not_Mounted   /media/ericthered/DB003_F1
#/dev/sdc2    swap     DB003_S1   48245d59-d265-459d-860c-d0caaf616fa7   Enabled       [SWAP]
#/dev/sdd1    ext4     DB004_F1   35e8b30a-bd60-4648-a101-e502f866bc05   Not_Mounted   /media/ericthered/DB004_F1
#/dev/sdd2    swap     DB004_S1   baaf58d0-df6a-4967-89ea-739b34840530   Enabled       [SWAP]

Devices__ReportDiskParts.sh >${TMP}.parts 2>>/dev/null
classParts=${TMP}.parts

if [ ${DBG} -eq 1 ] ; then echo "\n ======== Report from 'Devices__ReportDiskParts.sh' :" ; cat ${classParts} ; fi

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

		if [ "${dStatus}" != "Enabled" ]
		then

			if [ ${DBG} -eq 1 ] ; then echo "\n=== swap1 ===" ; fi
			if [ ${VERB} -eq 1 ]
			then
				echo "\n\t SWAP partition '${dLabel}' already disabled.  No action taken ..."
			fi

			showLiveSwapDetails
		else
			# Format of swap entry in fstab
			# UUID=7dd23169-56c6-4c2c-afbb-9e75d4de7652	none	swap	sw,pri=1	0	0

			tUuid=`grep -v '^#' /etc/fstab | grep '^UUID=' | grep ${dUuid} | head -1 `
			if [ -n "${tUuid}" ]
			then
				if [ ${DBG} -eq 1 ] ; then echo "\n=== swap2a ===" ; fi

				if [ ${DBG} -eq 1 ]
				then 
					COM="echo \"swapoff -v -U ${dUuid}\" "
				else
					COM="swapoff -v -U ${dUuid}"
				fi

				if [ ${VERB} -eq 1 ] ; then echo "\n\t COMMAND:  '${COM}' ..." ; fi
			else
				if [ ${DBG} -eq 1 ] ; then echo "\n=== swap2b ===" ; fi

				if [ ${DBG} -eq 1 ]
				then 
					COM="echo \"swapoff -v ${dDev}\" "
				else
					COM="swapoff -v ${dDev}"
				fi

				if [ ${VERB} -eq 1 ] ; then echo "\n\t COMMAND:  '${COM}' ..." ; fi
			fi

			eval ${COM} 2>&1 | awk '{ printf("\t   ACTION: %s\n", $0 ) }'

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

		if [ "${dStatus}" != "Mounted" ]
		then
			if [ ${DBG} -eq 1 ] ; then echo "\n=== data1 ===" ; fi
			if [ ${VERB} -eq 1 ]
			then
				echo "\n\t DATA partition '${dLabel}' already unmounted.  No action taken ..."
			fi

			case ${dPath} in
				/?* )
					#df -h 2>&1 | grep ${dLabel} | awk '{ printf("\t %s\n", $0 ) }'
					ls -l ${dPath} 2>&1 | awk '{ printf("\t %s\n", $0 ) }'
					;;
			esac
		else
				if [ ${DBG} -eq 1 ] ; then echo "\n=== data2b ===" ; fi

				if [ ${DBG} -eq 1 ]
				then 
					COM="echo \"umount -v ${dPath}\" "
				else
					COM="umount -v ${dPath}"
				fi

				if [ ${VERB} -eq 1 ] ; then echo "\n\t COMMAND:  '${COM}' ..." ; fi

			{	eval ${COM}
				if [ $? -ne 0 ] ; then ERROR="ERROR" ; reportDataLine ; ERROR="" ; fi 
			} 2>&1 | awk '{ printf("\t   ACTION: %s\n", $0 ) }'

			df -h 2>&1 | grep ${dLabel} | awk '{ printf("\t %s\n", $0 ) }'
		fi
	fi
}

unMountPartitions()
{
	while read dDev dFtype dLabel dUuid dStatus dPath
	do
		bypass=0
		if [ ${noroot} -eq 1 ]
		then
			case ${dLabel} in
				${rootPref}* )	bypass=1 ;;
				* ) ;;
			esac
		fi

		if [ ${bypass} -eq 0 ]
		then
			case ${dFtype} in
				swap )	if [ ${USB} -ne 1 ] ; then  if [ "${dPath}" != "/" ] ; then  logicSWAP ; fi ; fi ;;
				ext? )	if [ ${USB} -ne 1 ] ; then  if [ "${dPath}" != "/" ] ; then  logicDATA ; fi ; fi ;;
				vfat )	if [ "${dPath}" != "/" ] ; then  logicDATA ; fi ;;
				* )	echo "\n\t Logic has not been tested for partition filesystem type '${dFtype}'." >&2
					echo "  \t No action taken for partition labelled '${dLabel}' ..." >&2
					;;
			esac
		fi
	done <${classParts}
}

main()
{
	if [ ${noroot} -eq 1 ]
	then
		rootPref=`cat ${TMP}.parts | awk '{ if( $6 == "/" ){ print $3 } ; }' | cut -c1-5 `
	fi

	for class in DATA SWAP
	do
		classParts=${TMP}.${class}
		rm -f ${classParts}

		case ${class} in
			DATA )
				grep -v swap ${TMP}.parts >${classParts}
				if [ \( ${VERB} -eq 1 \) -a \( ${SWAP} != 1 \) ]
				then
					echo "\n ======== Sub-group for DATA class partitions :" ; cat ${classParts}
				fi
				;;
			SWAP )
				grep    swap ${TMP}.parts >${classParts}
				if [ \( ${VERB} -eq 1 \) -a \( ${DATA} != 1 \) ]
				then
					echo "\n ======== Sub-group for SWAP class partitions :" ; cat ${classParts}
				fi
				;;
		esac
		
		unMountPartitions
	done
}

#mountPartitions
main

exit 0
exit 0
exit 0
