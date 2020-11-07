#!/bin/sh

###
###	This script is a Work-In-Progress hack to simplify and automate some very destructive actions for disk scanning and repair of partitions.
###
###	*** NOT *** production ready !!!
###

if [ "$1" != "--force" ] ; then  echo "\n\t WARNING:  This script is VERY DANGEROUS and should not be used unless you completely understand what it sets out t
o do!\n Bye!\n ; exit 1 ; fi

BASE=`basename "$0" ".sh" `
TMP=/tmp/tmp.${BASE}
rm -f ${TMP}.*

DISK=/dev/sdc

df -h >${TMP}
testor=`grep ${DISK} ${TMP} | head -1 `
if [ -n "${testor}" ]
then
	echo "\n\t Disk ${DISK} is mounted and in use.  Unable to proceed.\n Bye!\n" ; exit 1
fi

BAD=${TMP}.FirstBadSector

smartctl -l selftest ${DISK} >${TMP}.selftest

FirstBadBlock=`grep "Conveyance captive" ${TMP}.selftest | awk '{ print $NF }' `
echo "${FirstBadBlock}"

DamageSeverity=`smartctl -A ${DISK} | grep 'Current_Pending_Sector' | awk '{ print $NF }' `
echo "${DamageSeverity}"

fdisk -l ${DISK} | awk 'BEGIN{ doP=0 }{ if( doP == 1 ){ print $0 }else{ if( index($0,"Device") == 1 ){ doP=1 ; } ; }; }' | tr -s ' ' >${TMP}.parts

#/dev/sdc3   307996672  922384383 614387712   293G Linux swap
while read partition pStartS pEndS pSizeS pSizeH pType
do
	pNum=`echo ${partition} | cut -c9- `
	echo "${pNum} ends ${pEndS}"
	if [ ${FirstBadBlock} -le ${pEndS} ]
	then
		break
	fi
done < ${TMP}.parts

echo "${FirstBadBlock} in partition ${pNum}"

partitionBlockOffset=`expr ${FirstBadBlock} - ${pStartS} `
echo "OFFSET = ${partitionBlockOffset}"

### identify filesystem type
#ID-3: /dev/sdc3 size: 314.57G fs: ext4 label: DB002_F2 uuid: 541dd70c-aa9a-4918-8e6c-e36412a43798
pType=`inxi -o -c 0 | grep ${DISK}${pNum} | awk '{ n=index($0, "fs:") ; tmp=substr($0,n+4) ; print tmp }' | awk '{ print $1 }' `
echo "fstype= ${pType}"

blkSiz=`tune2fs -l ${DISK} | grep Block | grep size | awk '{ print $2 }' `
echo "Block size for partition= ${blkSiz}"

### identify the block which contains the bad sector
### Formula:  (SOURCE:  )
#
#	b = (int)( ( ${FirstBadBlock} - ${pStartS} ) * 512 / ${blkSiz} )
#
#	where:
#		               b = File System block number
#		       ${blkSiz} = File system block size in bytes
#		${FirstBadBlock} = LBA of bad sector
#		      ${pStartS} = Starting sector of partition as shown by fdisk -lu
#		(int) restrict to usage of the integer part of the calculated value.

BadBlockAddress=`expr ( ${FirstBadBlock} - ${pStartS} ) * 512 / ${blkSiz} `
echo "BadBlockAddress= ${BadBlockAddress}"

