#!/bin/sh

TARGET="/DB001_F7/00___GPT_Backup"

if [ ! -d "${TARGET}" ]
then
	mkdir "${TARGET}"
fi

cd ${TARGET}
if [ $? -ne 0 ]
then
	echo "\n\t Failed to set "${TARGET}" as working directory for GPT image backup.  Unable to proceed.\n Bye!\n" ; exit 1
fi

echo "\n WORKING DIRECTORY  ==>  `pwd`"

dRoot=`df / | grep '^/dev' | awk '{ print $1 }' | cut -c1-8 `
for DISK in 1 2 3 4 5 6
do
	LABEL="DB00${DISK}"
	dDat=`ls -l "/dev/disk/by-label/${LABEL}_F1" 2>>/dev/null | grep '/dev' | awk '{ print $11 }' `
	echo ${dDat}
    if [ -n "${dDat}" ]
    then
	testorD=`echo "${dDat}" | cut -f3 -d/ `
	echo "testorD= ${testorD}"

	dUUID=`ls -l /dev/disk/by-uuid | grep ${testorD} | awk '{ print $9 }' `
	echo "dUUID= ${dUUID}"
		
	testor=`grep "${dUUID}" /etc/fstab | grep -v '^#' `
	echo "testor= ${testor}"

	if [ -n "${testor}" ]
	then
		dDevP="/dev/${testorD}"
		echo dDepP= ${dDevP}

		dMount=`df ${dDevP} | grep '/dev' | awk '{ print $6 }' `
		echo dMount= ${dMount}

		if [ "${dMount}" = "/" ]
		then
			dDev=`echo "${dDevP}" | cut -c1-8 `
		else
			dDev=`echo "${dDevP}" | cut -c1-8 | grep -v ${dRoot} `
		fi
		echo "dDev= ${dDev}"

		if [ -n "${dDev}" ]
		then
			BackFile="GTP_Backup__${LABEL}${DATE}"
			echo "\n Creating backup of GPT Partition Table for disk ${LABEL} [${dDev}] ..."

			if [ -s ./sgdisk ]
			then
				rm -fv ./sgdisk
			fi

			COM="sgdisk --backup='${BackFile}' '${dDev}'"
			echo "\n\t COMMAND:  ${COM} ..."
			eval ${COM} 2>&1 | awk '{ printf("\t\t %s\n", $0 ) ; }'
			echo "\t\t ==> RC = $?"

			if [ -s ./sgdisk ]
			then
				rm -fv ./sgdisk
			fi
			ls -ltr 2>&1 | awk '{ printf("\t\t %s\n", $0 ) ; }'

			echo "\n\t To restore the GPT Partition Table to original values, use the command:\n\t\t ==>  sgdisk --load-backup='${BackFile}' '${dDev}'\n"
		else
			echo "\n Disk ${LABEL}_F1 is currently offline ...\n"
		fi
	else
		echo "\n ${LABEL}_F1 is not recognized as a disk!  No definition registered in '/etc/fstab' ...\n"
	fi
    else
	echo "\n Disk ${LABEL}_F1 is not registered as a DBUS device! ...\n"
    fi
done

