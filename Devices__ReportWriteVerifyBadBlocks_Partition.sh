#!/bin/sh

##################################################################################################
###
###	$Id: Devices__ReportWriteVerifyBadBlocks_Partition.sh,v 1.1 2021/02/20 03:52:17 root Exp root $
###
###	Program to run badblocks on a partition, with write and verify option, and generate a report of badblocks for use with e2fsck.
###
##################################################################################################

DBG=1

BASE=`basename "$0" ".sh" `
TMP=/tmp/${BASE}.tmp

COMg="gdisk"
GDISK=`which ${COMg} | grep ${COMg} `
if [ -z "${GDISK}" ] ; then   echo "\n\t Unable to locate '${COMg}' command.  Unable to proceed.\n Bye!\n" ; exit 1 ; fi

COMp="Devices__ReportDiskParts.sh"
dPARTS=`which ${COMp} | grep ${COMp} `
if [ -z "${dPARTS}" ] ; then   echo "\n\t Unable to locate '${COMp}' command.  Unable to proceed.\n Bye!\n" ; exit 1 ; fi

${dPARTS} 2>&1 | grep 'Not_' >${TMP}.offline
if [ ! -s ${TMP}.offline ] ; then  echo "\n\t Unable to proceed.  All partitions are mounted.\n Bye!\n" ; exit 1 ; fi

# /dev/sdb3    ext2     DB003_F2   26d0b3e5-bfb9-4d02-98ab-defefe888613   Not_Mounted   /site/DB003_F2                 block:scsi:pci
# /dev/sdc2    ext4     DB004_F1   b83711a8-cd74-4286-a8ce-194070572ce7   Not_Mounted   /site/DB004_F1                 block:scsi:pci

while read DISK fsType PartLABEL UUID fsStatus junk
do
	echo "\n\t Rebuild ${PartLABEL} ? [ ${DISK} , ${fsType} ] => \c" ; read doThis <&2
	if [ -z "${doThis}" ] ; then  doThis="N" ; fi
	case ${doThis} in
		y* | Y* ) doThis="Y" ; break ;;
		* ) doThis="N" ;;
	esac
done <${TMP}.offline

if [ "${doThis}" = "N" ] ; then  echo "\n\t No Selection made.\n Bye!\n" ; exit 1 ; fi

#echo "\n\t Following block devices have been identified:\n"
#lsblk -l | awk '{ if( length($1) == 3 ){ print $0 } ; }' | awk '{ printf("\t\t %s\n", $0 ) ; }'

#echo "\n\t Enter the block device's full path (i.e. /dev/sdX) => \c" ; read DISK
#if [ -z "${DISK}" ] ; then  echo "\n\t Empty string.\n Bye!\n" ; exit 1 ; fi

testor=`df | grep ${DISK} `
if [ -n "${testor}" ] ; then  echo "\n\t Drive is mounted on ${DISK} ...  Cannot proceed.\n Bye!\n" ; exit 1 ; fi


	#GPT fdisk (gdisk) version 1.0.5
	#
	#Partition table scan:
	#  MBR: protective
	#  BSD: not present
	#  APM: not present
	#  GPT: present
	#
	#Found valid GPT with protective MBR; using GPT.
	#Disk /dev/sdb: 976773168 sectors, 465.8 GiB
	#Model: WDC WD5000AAKS-0
	#Sector size (logical/physical): 512/512 bytes
	#Disk identifier (GUID): B4DE4571-9E19-4B1B-B99B-79B53227474F
	#Partition table holds up to 128 entries
	#Main partition table begins at sector 2 and ends at sector 33
	#First usable sector is 34, last usable sector is 976773134
	#Partitions will be aligned on 2048-sector boundaries
	#Total free space is 2029 sectors (1014.5 KiB)
	#
	#Number  Start (sector)    End (sector)  Size       Code  Name
	#   1            2048         8388607   4.0 GiB     8200  DB003_S1
	#   2         8388608       218095615   100.0 GiB   8300  DB003_F1
	#   3       218095616       976773119   361.8 GiB   8300  DB003_F2

DISKbase=`echo ${DISK} | cut -f3- -d/ `

rm -f ${TMP}.${DISKbase}.gdisk
DRIVE=`echo ${DISK} | cut -c1-8 `
${GDISK} -l ${DRIVE} >${TMP}.${DISKbase}.gdisk

testor=`grep ${PartLABEL} ${TMP}.${DISKbase}.gdisk `
if [ -z "${testor}" ] ; then  echo "\n\t No references to chosen partition in '${GDISK}' report!  Unable to proceed.\n Bye!\n" ; exit 1 ; fi

###	Disk /dev/sdd: 149.5 GiB, 160041885696 bytes, 312581808 sectors
#SECTORS_LGCL=`grep '^Disk /dev' ${TMP}.${DISKbase}.gdisk | awk '{ print $3 }' `
#echo "\t\t  SECTORS_LOGICAL = ${SECTORS_LGCL}"

###	Sector size (logical/physical): 512 bytes / 4096 bytes
SECT_SIZE_LGCL=`grep '^Sector size' ${TMP}.${DISKbase}.gdisk | awk '{ print $4 }' | cut -f1 -d/ `
SECT_SIZE_PSCL=`grep '^Sector size' ${TMP}.${DISKbase}.gdisk | awk '{ print $4 }' | cut -f2 -d/ `

###	Sector size (logical/physical): 512 bytes / 4096 bytes
PART_SECT_STRT=`grep ${PartLABEL} ${TMP}.${DISKbase}.gdisk | awk '{ print $2 }' `
PART_SECT_LAST=`grep ${PartLABEL} ${TMP}.${DISKbase}.gdisk | awk '{ print $3 }' `

BADBLOCKS_REPORT="./${BASE}.${PartLABEL}.partition.log"

if [ ${DBG} -eq 1 ]
then
	echo "\n===================================================================="
	echo "\t||                   DISK = ${DISK}"
        echo "\t||                 fsType = ${fsType}"
	echo "\t||              PartLABEL = ${PartLABEL}"
	echo "\t||               DISKbase = ${DISKbase}\n"

	cat ${TMP}.${DISKbase}.gdisk
       
	echo "\n\t|| SECTOR Size - Logical  = ${SECT_SIZE_LGCL}"
	#echo "\t|| SECTOR Size - Physical = ${SECT_SIZE_PSCL}"

	echo "\t|| PARTITION - 1st Block  = ${PART_SECT_STRT}"
	echo "\t|| PARTITION - LAST Block = ${PART_SECT_LAST}"

	echo "\t|| BAD BLOCKS REPORT      = ${BADBLOCKS_REPORT}"
	echo "====================================================================\n"
fi

COM="date +%F_%T ; badblocks -v -s -w -b ${SECT_SIZE_LGCL} -p 0 -e 0 -o ${BADBLOCKS_REPORT} ${DRIVE} ${PART_SECT_LAST} ${PART_SECT_STRT} ; date +%F_%T"

echo "\n COMMAND:  ${COM} ..."

if [ "$1" = "--force" ]
then
	${COM}
	echo "\n Done.\n"
else
	echo "\n\t The above would have been the command executed. \n\t If that is what you truly expected, either copy+paste the command \n\t or re-run the script with the '--force' command line option. \n Bye!\n" ; exit 1
fi


exit 0
exit 0
exit 0


