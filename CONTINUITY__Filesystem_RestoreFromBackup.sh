#!/bin/sh

BASE=`basename "$0" ".sh" `
TMP=/tmp/tmp.$$.${BASE}

rm -f ${TMP}

###	FUTURES:	Prompt for each partition to request which to restore
###	ALT:		Identify which partitions are offline and prompt for each if want to restore from backup

# /dev/sda12   ext4     DB001_F5   14e15125-6c47-499e-b1a9-734a0f928b5e   Not_Mounted   /DB001_F5                      block:scsi:pci
# Devices__ReportDiskParts.sh

Devices__ReportDiskParts.sh 2>&1 | grep -v 'swap' | grep -v 'vfat' | grep -v '/site/DB' | grep '/DB' >${TMP}
if [ -s ${TMP} ]
then
	echo "\n ALL non-ROOT partitions on the ROOT disk drive:\n"
	#cat ${TMP} | awk '{ printf("\t\t %-12s %-12s %s\n", $1, $2, $6 ) ; }'
	cat ${TMP} | awk '{ printf("\t %s\n", $0 ) ; }'
else
	echo "\n\t Only the ROOT partition exists on the ROOT disk drive.  Unable to proceed.\n Bye!\n" ; exit 1
fi

echo ""

rm -f ${TMP}.parts
awk '{ print $6 }' ${TMP} >${TMP}.parts

rm -f ${TMP}.usage
df `cat ${TMP}.parts ` | grep '/dev/' |
	awk '{
		#if( $3 <= 40000000 ){
		if( $3 <= 1000000 ){
			print $6 ;
		} ;
	; }'  >${TMP}.usage

echo "\n Candidate low-usage partitions (<1GB) identified for RESTORE from BACKUP:"

df `cat ${TMP}.usage ` | awk '{ printf("\t %s\n", $0 ) ; }'

DOIT=0
for PARTITION in `cat ${TMP}.usage | cut -c2- `
do
	devREST=`df "/${PARTITION}" 2>>/dev/null | grep '^/dev' | awk '{ print $1 }' `
	devROOT=`df / | grep '^/dev' | awk '{ print $1 }' `
	if [ "${devREST}" = "${devROOT}" ]
	then
		echo " Partition to be restored is offline.  Mount the device ? [y|N] => \c" ; read ans2
		if [ -z "${ans2}" ] ; then  ans2="N" ; fi
		case ${ans2} in
			y* | Y* )
				UUID=`grep "${PARTITION}" ${TMP} | grep -v 'block:scsi:usb:pci' | awk '{ print $4 }' `
				DEVICE=`mount -v -U ${UUID} 2>&1 | awk '{ print $2 }' `
				mount | grep "${DEVICE}" | awk '{ printf("\n\t %s\n", $0 ) ; }'

#				echo "\n\t Contents of partition restore target '/${PARTITION}':"
#				( cd "/${PARTITION}" ; ls -l 2>&1 | awk '{ printf("\t\t %s\n", $0 ) ; }' )
#
#				echo "\n\t OK to proceed with PARTITION restore ? [y|N] => \c" ; read ans3
#				if [ -z "${ans3}" ] ; then  ans3="N" ; fi
#				case ${ans3} in
#					y* | Y* ) echo "\n Proceeding ..." ;;
#					* ) echo "\n\t Process abandoned.\n Bye!\n" ; exit 0 ;;
#				esac
				;;
			* ) echo "\n\t Process abandoned.\n Bye!\n" ; exit 0 ;;
		esac
	fi
	echo "\nCurrent contents of /${PARTITION}:"
	ls -l "/${PARTITION}" 2>&1 | awk '{ printf("\t %s\n", $0 ) ; }'
	echo ""

	echo " Restore /${PARTITION} ? [y|N] => \c" ; read ans
	if [ -z "${ans}" ] ; then  ans="N" ; fi
	case ${ans} in
		y* | Y* )
			echo "\t Are you ABSOLUTELY SURE ? [y|N] => \c" ; read ansV
			if [ -z "${ansV}" ] ; then  ansV="N" ; fi
			case ${ansV} in
				y* | Y* ) DOIT=1 ; break ;;
				* ) ;;
			esac
			;;
		* ) ;;
	esac
done

if [ ${DOIT} -eq 0 ] ; then  echo "\n\t No partition selected for RESTORE process.\n Bye!\n" ; exit ; fi

echo "\t *** PARTITION SELECTED:  '${PARTITION}' ..."

PART_NUM=`echo "${PARTITION}" | cut -c8 `

BACKUP="/site/DB005_F${PART_NUM}/${PARTITION}/"

devBACK=`df ${BACKUP} 2>>/dev/null | grep '^/dev' | awk '{ print $1 }' `
devROOT=`df / | grep '^/dev' | awk '{ print $1 }' `
if [ "${devBACK}" = "${devROOT}" ]
then
	echo "\n\t [A] Backup image for requested device is OFFLINE.\n\t Please correct the condition and re-attempt.\n Bye!\n"
	exit 1
else
	if [ -z "${devBACK}" ]
	then
		echo "\n\t [B] Backup image for requested device is OFFLINE.\n\t Please correct the condition and re-attempt.\n Bye!\n"
		exit 1
	fi
fi

cd ${BACKUP}
RC=$?
if [ $RC -ne 0 ] ; then  echo "\n\t Unable to set PWD to '${BACKUP}' to access BACKUP IMAGE !!!\n\t Unable to proceed.\n Bye!\n" ; exit 1 ; fi

echo "\n\t Contents in partition BACKUP directory: [ ${BACKUP} ]"
ls -l 2>&1 | awk '{ printf("\t\t %s\n", $0 ) ; }'

echo "\n\t OK to proceed with PARTITION restore ? [y|N] => \c" ; read ans4
if [ -z "${ans4}" ] ; then  ans4="N" ; fi
case ${ans4} in
	y* | Y* ) ;;
	* ) echo "\n\t Process abandoned.\n Bye!\n" ; exit 0 ;;
esac

echo "\n\n*****************************************************************************************
*****************************************************************************************
	WARNING		WARNING		WARNING		WARNING		WARNING
*****************************************************************************************
*****************************************************************************************\n"

echo "\t Last chance to abandon PARTITION restore!  PROCEED ? [y|N] => \c" ; read ansA
if [ -z "${ansA}" ] ; then  ansA="N" ; fi
case ${ansA} in
	y* | Y* ) ;;
	* ) echo "\n\t RESTORE process abandoned.\n Bye!\n" ; exit 0 ;;
esac

echo "\n Proceeding.  Starting partition restore with RSYNC ..."

LOG="/site/${PARTITION}_Restore.log"
ERRLOG="/site/${PARTITION}_Restore.err"

nice -17 rsync \
	--checksum \
	--one-file-system \
	--recursive \
	--outbuf=Line \
	--links \
	--perms \
	--times \
	--group \
	--owner \
	--devices \
	--specials \
	--verbose --out-format="%t|%i|%M|%b|%f|" \
	--delete-delay \
	--whole-file \
	--human-readable \
	--protect-args \
	--ignore-errors \
	--msgs2stderr ./ /${PARTITION}/ >${LOG} 2>${ERRLOG} &
sleep 5
echo "\n RSYNC restore process is proceeding in background ...\n"
ps -ef | grep -v 'grep' | grep 'rsync' | awk '{ printf("\t %s\n", $0 ) ; }'
echo ""
ls -l ${LOG} ${ERRLOG}
echo ""


exit 0
exit 0
exit 0

