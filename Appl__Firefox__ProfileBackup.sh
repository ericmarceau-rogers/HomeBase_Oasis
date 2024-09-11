#!/bin/sh

####################################################################################################
###
###	$Id: Appl__Firefox__ProfileBackup.sh,v 1.3 2021/12/14 02:18:14 root Exp $
###
###	Script to create backup archive file for the Firefox installation for the current user.
###
####################################################################################################

today=`date +%Y%m%d-%H%M`
thisHost=`hostname`

if [ -n "${SUDO_USER}" ]
then
	thisUser="${SUDO_USER}"
else
	#{username}:x:1000:1000:,Oasis,,,:/home/{username}:/bin/bash
	thisUser=`grep -v nologin /etc/passwd | grep -v '/false' | grep -v '/sync' | grep -v '/root' | grep '/home' | head -1 | cut -f1 -d\: `
fi

case ${thisHost} in
	OasisMega1 )
		TARGETpar="/DB001_F2/LO"
		;;
	* )
		TARGETpar="/site/DB001_F2/LO"
		;;
esac

if [ \( ! -d /home/${thisUser}/.mozilla \) -o \( ! -d /home/${thisUser}/.mozilla/firefox \) ]
then
	echo "\n\t Mozilla Firefox application has not been installed, or installation was corrupted.\n\t Bye!\n" ; exit 1
fi

Appl__Firefox__CachePurge.sh

#####################################################################################################
###	Logic to ensure TARGETpar is on confirmed different partition from root, 
###	and not simply mountpoint on same partition.
#####################################################################################################

rootDev=`df / | tail -1 | awk '{ print $1 }' `
#echo ${rootDev}

trgtDev=`df "${TARGETpar}" | tail -1 | awk '{ print $1 }' `
#echo ${trgtDev}

if [ ${rootDev} = ${trgtDev} ]
then
	echo "\n\t TARGETdir should not be on root disk.  Partition was not properly mounted.\n\t Bye!\n" ; exit 1
fi
	

#####################################################################################################
###	Reconsider desirability of this test loop
#####################################################################################################

if [ ! -d "${TARGETpar}" ]
then
	echo "\n\t Backup target directory '${TARGETpar}' does not exist.  Trying alternate target ..."
	TARGETpar="/Oasis"

	if [ ! -d "${TARGETpar}" ]
	then
		echo "\n\t Backup target directory '${TARGETpar}' does not exist.  Abandoning process.\n\t Bye!\n" ; exit 1
	fi
fi


#####################################################################################################
###	Create backup directory if non-existent
#####################################################################################################

thisGID=`grep  "^${thisUser}" /etc/passwd | cut -f4 -d: `
thisGroup=`grep ":${thisGID}:" /etc/group | cut -f1 -d: `

TARGETdir="${TARGETpar}/Backup_Firefox_${thisHost}"

if [ ! -d "${TARGETdir}" ]
then
	mkdir ${TARGETdir}
	
	chown ${thisUser}:${thisGroup} ${TARGETdir}
	echo "\n\t Created directory '${TARGETdir}' :"
	ls -ld ${TARGETdir} | awk '{ printf("\t %s\n", $0 ) }'
fi


#####################################################################################################
###	Create backup as labelled tar file
#####################################################################################################

echo ""
cd /home/${thisUser}/.mozilla

{
	ls -ld /home/${thisUser}/.mozilla
	if [ -L /home/${thisUser}/.mozilla ]
	then
		ls -Lld /home/${thisUser}/.mozilla
	fi

	echo ""
	ls -ld firefox/*.FirefoxProfile*
} | awk '{ printf("\t %s\n", $0 ) }'

#default=`ls -ld firefox/${thisHost}.FirefoxProfile_DEFAULT | cut -f2 -d/ | cut -f1 -d. `
default=`ls -ld firefox/*.FirefoxProfile_DEFAULT | cut -f2 -d/ | cut -f1 -d. | uniq `

if [ -z "${default}" ]
then
	echo "\n\t Unable to identify default profile per script logic.\n\n Bye!\n" ; exit 1
else
	if [ "${default}" = "${thisHost}" ]
	then
		TARGET="${TARGETdir}/firefox-browser-profile_${thisHost}_DEFAULT_${today}.tar"
	else
		TARGET="${TARGETdir}/firefox-browser-profile_${thisHost}_${default}_${today}.tar"
	fi
fi

echo ""

echo "\n\t TARGET LOCATION = ${TARGETdir} ..."
echo "\t TARGET FILE     = `basename ${TARGET}` ..."
echo "\n\t Hit return to continue (or Break) => \c"
read k
echo""


echo "\n\t Creating tar file ..."
cd /home/${thisUser}
tar -cvf ${TARGET} .mozilla*
xcode=$?
echo "\n\t Exit code = ${xcode}"

echo "\n\t Creating index of tar file contents ..."

tar tvf ${TARGET} | sort --key 6.1,7.0 >${TARGET}.INDEX

echo "\n\t Firefox browser profile has been saved as \n\t ==>> ${TARGET} \n"

cd `dirname ${TARGET} `
ls -l

exit 0
exit 0
exit 0