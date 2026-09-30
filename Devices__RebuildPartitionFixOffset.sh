#!/bin/sh

###	$Id: Devices__RebuildPartitionFixOffset.sh,v 1.1 2020/10/10 03:08:40 root Exp root $
###	Script to generate a list of revised Start and End sector numbers for partitions that are not aligned with physical sector boundaries, and could therefore be impacting disk/processing performance, then use those to rebuild the partitions for proper sector alignment with physical sectors.
###
###	IMPORTANT:  Script logic assumes first partition on disk drive is swap and all others are ext4.


#############################################################################################################
#############################################################################################################

# intended for test on DB002_F8 then apply on DB002_F2

LabelPref="DB002"

tableFile=""
partPrefix=""
debug=0
verbose=0

FORCE_IT=0

while [ $# -gt 0 ]
do
	case $1 in
		--force )	FORCE_IT=1	; shift ;;
		--table )	tableFile="$2"	; break ; shift ; shift ;;
		--disk )	partPrefix="$2"	; shift ; shift ;;
		--debug )	debug=1		; shift ;;
		--verbose )	verbose=1	; shift ;;
		* ) echo "\n\t Invalid parameter used on command line.  Only options: [ --debug | --verbose | --disk {disk_device} | --table {previous_report} ]\n Bye!\n" ; exit 1 ;;
	esac
done

if [ ${FORCE_IT} -eq 0 ] ; then  echo "\n\t *** HAZARD *** HAZARD *** HAZARD *** HAZARD *** HAZARD ***\n\t Please review script for actions before proceeding.\n Bye!\n" ; exit 0 ; fi

#############################################################################################################
#############################################################################################################

reportNewPart()
{
	test ${debug} -eq 1 && echo "OFFSET_next= ${OFFSET_next}"
	test ${debug} -eq 1 && echo "newend= ${newEnd}"

	echo "${PART_this} ${newStart} ${newEnd}" | awk '{ printf("%-10s %12d %12d\n", $1, $2, $3 ) ; }'

	if [ ${atEnd} -eq 0 ]
	then
		echo "${oldStart} ${oldEnd} ${OFFSET_this} ${OFFSET_next}" | awk '{ printf("#          %12d %12d | %5s %5s\n", $1, $2, $3, $4 ) ; }' >>${TMP}.details
	else
		echo "${oldStart} ${oldEnd} ${OFFSET_this} ${OFFSET_next} ${lastSector}" | awk '{ printf("#          %12d %12d | %5s %5s %d\n", $1, $2, $3, $4, $5 ) ; }' >>${TMP}.details
	fi
}

scanExtractRedefine()
{
	####################################################################
	#Disk /dev/sdc: 1.8 TiB, 2000398934016 bytes, 3907029168 sectors
	fdisk -l ${partPrefix} 2>>/dev/null >${TMP}.tmp


	####################################################################
	#Device          Start        End   Sectors  Size Type
	#/dev/sdc1       16065    8385929   8369865    4G Linux swap
	cat ${TMP}.tmp | awk 'BEGIN{ doP=0 }{ if( doP == 1 ){ print $0 }else{ if( index($0,"Device") == 1 ){ doP=1 ; } ; }; }' | tr -s ' ' >${TMP}

	lastDev=""
	lastEnd=""
	lastStart=""
	atEnd=0
	partition=1

	while [ true ]
	do
		PART_this="${partPrefix}${partition}"
		PART_next="${partPrefix}`expr ${partition} + 1 `"

		OFFSET_this=`blockdev --getalignoff ${PART_this} `

		dataline=`eval grep \'^${PART_this}\' ${TMP} `
		#test ${debug} -eq 1 && cho dataline= $dataline

		oldStart=`echo "${dataline}" | awk '{ print $2 }' `
		#test ${debug} -eq 1 && cho oldstart= $oldStart

		newStart=`expr ${oldStart} - ${OFFSET_this} `
		#test ${debug} -eq 1 && cho newstart= $newStart

		oldEnd=`echo "${dataline}" | awk '{ print $3 }' `
		#test ${debug} -eq 1 && cho oldend= $oldEnd

		OFFSET_next=`blockdev --getalignoff ${PART_next} 2>>/dev/null`
		if [ $? -ne 0 ]
		then
			atEnd=1
		fi

		if [ ${atEnd} -eq 0 ]
		then
			atEnd=0	
			newEnd=`expr ${oldEnd} - ${OFFSET_next} `

			reportNewPart
		else
			OFFSET_next="N/A"
			lastSector=`head -1 ${TMP}.tmp | awk '{ print $7 }' `
			lastSector=`expr ${lastSector} - 1 `
			test ${debug} -eq 1 && echo "lastSector= ${lastSector}"

			newEnd=${lastSector}

			reportNewPart
			break
		fi
		partition=`expr ${partition} + 1`
	done >${TMP}.todo

	{	if [ ${verbose} -eq 1 ]
		then
			echo "#\n####################################################################################################"
			cat ${TMP}.tmp | awk '{ printf("# %s\n", $0 ) }'
			echo "\n####################################################################################################"
		fi

		if [ ${debug} -eq 1 ]
		then
			cat ${TMP}.details
			echo "\n####################################################################################################"
		fi
		cat ${TMP}.todo 
	} >${BASE}.RevisedSectorLimits.txt

	cat ${BASE}.RevisedSectorLimits.txt
	ls -l ${BASE}.RevisedSectorLimits.txt | awk '{ printf("\n\t %s\n", $0 ) }' >&2
}


#############################################################################################################
#############################################################################################################

BASE=`basename "$0" ".sh" `
TMP=/tmp/${BASE}.parts
rm -f ${TMP}
rm -f ${TMP}.tmp
rm -f ${TMP}.details
rm -f ${TMP}.todo

if [ -n "${tableFile}" ]
then
	cp -p ${tableFile} ${TMP}.todo
else
	if [ -z "${partPrefix}" ]
	then
		echo "\n\t Command line must provide specification of disk for analysis and reporting of modified partition boundaries.\n\t Use:  --disk ${physical_disk} (i.e. /dev/sdc)\n Bye!\n" ; exit 1
	fi

	echo "\n\t PHASE I - Scan, Analysis and Re-defining Partition Start and End Sectors ...\n" 

	scanExtractRedefine

	echo "\n\t Hit return to continue with PHASE II - Re-alignment of partitions ...\n" ; read k
fi

while read dataline
do
	if [ -z "${dataline}" ] ; then  echo "\n Done!\n" ; exit 0 ; fi
	#disk=/dev/sdc

	#dataline="/dev/sdc1         12481      8382857"
	#dataline="/dev/sdc2       8382858    322954182"

	PART_this=`echo "${dataline}" | awk '{ print $1 }' `
	disk=`echo "${PART_this}" | cut -c1-8 `
	partPosn=`echo "${PART_this}" | cut -c9- `
	partStart=`echo "${dataline}" | awk '{ print $2 }' ` ; partStart=`expr ${partStart} / 2000 `
	partEnd=`echo "${dataline}" | awk '{ print $3 }' ` ; partEnd=`expr ${partEnd} / 2000 `
	echo ${disk}
	echo ${partPosn}

	echo ${partStart}
	echo ${partEnd}

	echo "\n\t Deleting partition #${partPosn} on ${disk} ..."

	parted ${disk} rm ${partPosn} 2>>/dev/null
	if [ $? -eq 0 ] ; then echo "\t Done.\n" ; fi

	fdisk -l ${disk}

	echo "\n\t Hit return to continue with re-creating aligned partition ..." ; read k <&2

	swapCount=0
	partCount=0

	case ${partPosn} in
		1 ) 
			swapCount=`expr ${swapCount} + 1 `
			partLabel="${LabelPref}_S${swapCount}"
			partType="linux-swap"
			parted ${disk} mkpart primary ${partType} ${partStart} ${partEnd} >>/dev/null
			#parted ${disk} name ${partPosn} ${partLabel} >>/dev/null
			;;
		2)
			partCount=`expr ${partCount} + 1 `
			partLabel="${LabelPref}_F${partCount}"
			partType="ext4"
			parted ${disk} mkpart primary ${partType} ${partStart} ${partEnd} >>/dev/null
			#parted ${disk} name ${partPosn} ${partLabel} >>/dev/null
			;;
	esac

	fdisk -l ${disk}

	echo "\t Alignment offset for ${disk}${partPosn}: `blockdev --getalignoff ${PART_this} `"

	echo "\n\t Hit return to continue with next partition ..." ; read k <&2
done <${TMP}.todo

exit 0
exit 0
exit 0

		#fsck -l -C -V -t ext4 ${PARTITION} -f -F -k -p -v  		# -l ${badblocks_list_file}

		# check:	tune2fs, debug2fs

