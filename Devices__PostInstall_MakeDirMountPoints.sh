#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###     $Id: Devices__PostInstall_MakeDirMountPoints.sh,v 1.3 2020/11/14 03:56:27 root Exp $
###
###     Script to create mount points for all devices detected by the system. Expectation that all partitions have LABELS according to convention.
###
####################################################################################################

echo "\n\t This script expects that you have updated every DATA and SWAP partition that is available on your computer with its own unique LABEL.\n\t Have you done this ? [y|N] => \c"

read labels
if [ -z "${labels}" ] ; then labels="N" ; fi

case ${labels} in
	y* | Y* )
		echo "\n\t Proceeding ..."
		;;
	* )
		echo "\n\t Unable to proceed.  Please assign LABEL to each partition before re-attempting. \n Bye! \n" ; exit 1
		;;
esac

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
	case $1 in
		"--debug" )	DBG=1 ; shift ;;
		"--verbose" )	VERB=1 ; shift ;;
		"--input" )	INPUT=1 ; shift ;;
		"--data" )	DATA=1 ; SWAP=0 ; shift ; sString="_F" ;;
		"--swap" )	SWAP=1 ; DATA=0 ; shift ; sString="_S" ;;
	esac
done

classParts=${TMP}.parts

COM_repParts="Devices__ReportDiskParts.sh"

tester=`which ${COM_repParts} `
if [ -z "${tester}" ]
then
        echo "\n\t Unable to proceed.  Unable to locate '${COM_repParts}'\n\n Bye!\n" ; exit 1
fi
${COM_repParts} >${classParts}

###	Report Format:
#/dev/sda14   ext4     DB001_F7   58f622cd-2841-4967-8def-86dd38192769   Mounted       /DB001_F7
#/dev/sdb1    ext4     DB002_F1   0aa50783-954b-4024-99c0-77a2a54a05c2   Not_Mounted   /site/DB002_F1
#/dev/sdb2    swap     DB002_S1   7dd23169-56c6-4c2c-afbb-9e75d4de7652   Enabled       [SWAP]

if [ ${DBG} -eq 1 ] ; then echo "\n ======== Report from '${COM_repParts}' :" ; cat ${classParts} ; fi

grep -v swap ${classParts} >${TMP}.DATA
classParts=${TMP}.DATA

if [ ${DBG} -eq 1 ] ; then echo "\n ======== Partial report excluding swap partitions :" ; cat ${TMP}.DATA ; fi

cd /

echo "\n\t Creating mount points for all identified partitions for which a mount point does not yet exist ...\n"

###	Root partition label /DB001_F1, no need for mount directory at root.

createMountPointFootprint()
{
	if [ -f ${dPath}/${dLabel}_NotMounted.txt ] ; then rm -f ${dPath}/${dLabel}_NotMounted.txt ; fi
				
	{	echo "Created: `date`\n"
		echo "VISIBILITY OF THIS FILE IMPLIES PARTITION IS NOT MOUNTED UNDER MOUNT-POINT  !!!"
	} >${dPath}/${dLabel}__NotMounted.txt

	chmod 444 ${dPath}/${dLabel}__NotMounted.txt
}

logicSYMLINK()
{
	if [ ${INPUT} -eq 1 ] ; then reportDataLine ; fi

	if [ -L /${dLabel} ]
	then
		if [ ${VERB} -eq 1 ] ; then ls -l /${dLabel} | awk '{ printf("\t %s\n", $0 ) }' ; fi

		if [ ${VERB} -eq 1 ] ; then echo "\t Symbolic link '/${dLabel}' already exists.  No action taken ..." ; fi
	else
		rm -f /${dLabel}

		ln -s / /${dLabel}

		echo "\t Created symbolic link '/${dLabel}' pointing to root ..." 
	fi
}

logicDATA()
{
	if [ ${INPUT} -eq 1 ] ; then reportDataLine ; fi

	if [ -d ${dPath} ]
	then
		if [ ${dStatus} = "Not_Mounted" ]
		then
			chmod 755 ${dPath}

			if [ ! -s ${dPath}/${dLabel}__NotMounted.txt ]
			then
				if [ ${VERB} -eq 1 ] ; then echo "Creating: ${dPath}/${dLabel}__NotMounted.txt" ; fi
				createMountPointFootprint
			fi
		fi

		echo "\t Mountpoint '${dPath}' already exists:"
		ls -l ${dPath}/${dLabel}__NotMounted.txt | awk '{ printf("\t\t %s\n", $0 ) }'
		echo "\t\t No action taken ...\n"
	else
		mkdir -v ${dPath} | awk '{ printf("\t %s\n", $0 ) }'

		chmod 755 ${dPath}

		createMountPointFootprint
		echo "\t\t Mount point '${dPath}' created ...\n"
	fi
}

main()
{
	while read dDev dFtype dLabel dUuid dStatus dPath
	do
		if [ -z "${dPath}" ]
		then
			echo "\n\t FATAL ERROR - 6 parameters expected on every line!  Admin intervention required. \n Bye!\n" ; exit 1
		fi

		case ${dDev} in
			${rootPref} )
				doit="N"
				;;
			${rootPref}?* )
				#FUTURES - check if already mounted then skip
				doit="Y"
				;;
			* )
				doit="Y"
				;;
		esac

		if [ ${doit} = "Y" ]
		then
			case ${dFtype} in
				ext? )
					#if [ \( "${dPath}" != "/" \) -a \( -n "${dPath}" \) ]
					if [ "${dStatus}" = "Not_Mounted" ]
					then
						logicDATA
					else
						if [ "${dPath}" = "/" ]
						then
							logicSYMLINK
						else
							echo "\t Partition '${dLabel}' already mounted.  No action required ...\n"
						fi
					fi
					;;
				swap )
					echo "\n No action taken for SWAP partition '${dLabel}' ..."
					;;
				* )	echo "\n\t Logic has not been tested for partition filesystem type '${dFtype}'." >&2
					echo "  \t No action taken for partition labelled '${dLabel}' ..." >&2
					;;
			esac
		fi
	done <${classParts}
}

main

echo "\n\t Done.\n"

exit 0
exit 0
exit 0
