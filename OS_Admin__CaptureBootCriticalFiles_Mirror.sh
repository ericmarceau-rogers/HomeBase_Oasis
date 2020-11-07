#!/bin/sh

###	$Id: OS_Admin__CaptureBootCriticalFiles_Mirror.sh,v 1.2 2020/10/08 01:07:27 root Exp root $
###	Script to create mirrored failsafe copy of key directories or files on partition other than root.

### PROD

DBG=0

while [ $# -gt 0 ]
do
	case $1 in
		--debug )
			DBG=1 ; shift
			;;
		* )
			echo "\n\t ERROR:  Invalid parameter.  Please try again.\n\n Bye!\n" ; exit 1
			;;
	esac
done

#dirList="boot/grub
#etc/fstab
#etc/default
#etc/grub.d"

dirList="boot/grub
etc"

failSafePartitionLabel="DB001_F2"

mountTest=`df -h | grep DB001_F2 `
if [ -z "${mountTest}" ]
then
	echo "\n\t Partition intended for failsafe image storage, labelled as '${failSafePartitionLabel}', is not mounted.\n\t Abandonning ...\n\n Bye!\n" ; exit 1
fi

thisHost=`hostname`
thisUser=`basename ${HOME}`

if [ "${thisUser}" = "root" ]
then
	if [ -n "${SUDO_USER}" ]
	then
		thisUser="${SUDO_USER}"
	fi
fi

fileList="home/${thisUser}/.bash_logout
home/${thisUser}/.bash_logout.DISTRO
home/${thisUser}/.bashrc
home/${thisUser}/.bashrc.DISTRO
home/${thisUser}/.bashrc-local
home/${thisUser}/.bashrc-local.DISTRO
home/${thisUser}/.bashrc_profile
home/${thisUser}/.bashrc_profile.DISTRO
home/${thisUser}/.bashrc_profile-local
home/${thisUser}/.bashrc_profile-local.DISTRO
home/${thisUser}/.profile
home/${thisUser}/.profile.DISTRO"

fileList2="root/.bash_logout
root/.bash_logout.DISTRO
root/.bashrc
root/.bashrc.DISTRO
root/.bashrc-local
root/.bashrc-local.DISTRO
root/.bashrc_profile
root/.bashrc_profile.DISTRO
root/.bashrc_profile-local
root/.bashrc_profile-local.DISTRO
root/.profile
root/.profile.DISTRO"


case ${thisHost} in
	OasisMega1 )
		#NOTE: Computer's Primary Host personality
		failsafeBackup="/DB001_F2/LO_FailSafe/${thisHost}"
		;;
	OasisMega2 | OasisMidi | OasisMini )
		failsafeBackup="/media/${thisUser}/DB001_F2/LO_FailSafe/${thisHost}"
		;;
	* )
		;;
esac

if [ ! -d ${failsafeBackup} ]
then
	mkdir -v ${failsafeBackup}
	chmod 755 ${failsafeBackup} ; chown root:${thisUser} ${failsafeBackup}
	ls -l ${failsafeBackup}
fi | awk '{ printf("\t\t %s\n", $0 ) }'

cd ${failsafeBackup} ; RC=$?

if [ ${RC} -ne 0 ]
then
	echo "\n\t Unable to set '${failsafeBackup}' as the working directory for prep work before mirroring process.  \n\t Abandoning ...\n\n Bye!\n" ; exit 1
fi

topList=`echo "${dirList}" | cut -f1 -d/ | sort | uniq `
topList2=`echo "${fileList}" | cut -f1 -d/ | sort | uniq `
topList3=`echo "${fileList2}" | cut -f1 -d/ | sort | uniq `

for dSource in `echo ${topList} ` `echo ${topList2} ` `echo ${topList3} `
do
	if [ ${DBG} = 1 ] ; then echo "\n\t dSource = '${dSource}' ..." ; fi

	dir=${dSource}

	if [ -d ${failsafeBackup}/${dir}-1 ]
	then
		echo "\n\t Purging older image under ${failsafeBackup}/${dir}-1 ..."
		if [ ${DBG} = 1 ]
		then
			rm -rfv ${failsafeBackup}/${dir}-1 2>&1 | awk '{ printf("\t\t%s\n", $0 ) }'
		else
			rm -rf ${failsafeBackup}/${dir}-1  2>&1 | awk '{ printf("\t\t%s\n", $0 ) }'
		fi
	fi

	if [ -d ${failsafeBackup}/${dir} ]
	then
		echo "\n\t Moving previous image under ${failsafeBackup}/${dir} to ${dir}-1 ..."
		(
			cd ${failsafeBackup}
			if [ ${DBG} = 1 ] ; then 
				#ls -ld ${failsafeBackup}/${dir} ${failsafeBackup}/${dir}-1 ${failsafeBackup}/${dir}-1/`basename ${dir}` 2>>/dev/null | awk '{ printf("\t\t%s\n", $0 ) }' 
				ls -ld ${dir} ${dir}-1 {dir}-1/`basename ${dir}` 2>>/dev/null | awk '{ printf("\t\t%s\n", $0 ) }' 
			fi
			mv -v ${dir} ${dir}-1 2>&1 | awk '{ printf("\t\t%s\n", $0 ) }'

			if [ -f ${dir}-1_INDEX ] ; then rm -f ${dir}-1_INDEX ; fi
			if [ -f ${dir}_INDEX   ] ; then mv ${dir}_INDEX ${dir}-1_INDEX ; fi
		)

		echo "\t\t Renamed corresponding index for contents to ${failsafeBackup}/${dir}-1_INDEX ..."
	fi

done

#echo "ABANDON"
#exit 0

cd / ; RC=$?

if [ ${RC} -ne 0 ]
then
		echo "\n\t Unable to set '/' as the working directory to start mirroring process.  \n\t Abandoning ... Bye!\n" ; exit 1
fi

echo "${dirList}"      |
while read fSource
do
	echo "\n\t Mirroring '/${fSource}' under '${failsafeBackup}' ..."
	tar cf - --one-file-system ${fSource} | ( cd ${failsafeBackup} ; tar xvpf - ) 2>&1 | sort | awk '{ printf("\t\t %s\n", $0 ) }'
done

echo "${fileList}\n${fileList2}"      |
while read fSource
do
	#echo "INPUT|${fSource}|" >&2

	if [ -f ${fSource} ]
	then
		echo "\n\t Mirroring '/${fSource}' under '${failsafeBackup}' ..."
		tar cf - --one-file-system ${fSource} | ( cd ${failsafeBackup} ; tar xvpf - ) 2>&1 | sort | awk '{ printf("\t\t %s\n", $0 ) }'
	else
		echo "\n\t\t NOT_FOUND|/${fSource}|"
	fi
done

cd ${failsafeBackup}

for dSource in `echo ${topList} ` `echo ${topList2} ` `echo ${topList3} `
do
	dir=${dSource}

	if [ -d ${failsafeBackup}/${dir} ]
	then
		echo "\n\t Creating index of image under '${failsafeBackup}/${dir}' ..."
		if [ -f ${failsafeBackup}/${dir}_INDEX ] ; then  rm -f ${failsafeBackup}/${dir}_INDEX ; fi
		( cd ${dir} ; find . -print ) | sort >${failsafeBackup}/${dir}_INDEX

		if [ -f ${failsafeBackup}/${dir}-1_INDEX.diff ] ; then  rm -f ${failsafeBackup}/${dir}-1_INDEX.diff ; fi
		if [ -f ${failsafeBackup}/${dir}-1_INDEX.diff ] ; then  diff ${failsafeBackup}/${dir}-1_INDEX ${failsafeBackup}/${dir}_INDEX >${failsafeBackup}/${dir}-1_INDEX.diff ; fi

		if [ -s ${failsafeBackup}/${dir}-1_INDEX.diff ]
		then
			echo "\t\t Differences identified between previous backup and current for '${dir}' tree ..."
			ls -l ${failsafeBackup}/${dir}-1_INDEX.diff | awk '{ printf("\t\t %s\n", $0 ) }'
		else
			if [ -d ${failsafeBackup}/${dir}-1 ]
			then
				echo "\t\t No Changes detected compared to previous iteration of '${dir}' tree ..."
			fi
		fi
	fi
done
echo "\n Done.\n"


exit 0
exit 0
exit 0
