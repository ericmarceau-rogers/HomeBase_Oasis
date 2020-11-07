#!/bin/sh

#23456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+123456789+
####################################################################################################
###
###	$Id: OS_Admin__PostInstall_PackageListSnapshot.sh,v 1.2 2020/08/19 21:04:51 root Exp $
###
###	This script generates report on packages on the system following installation of a new DISTRO.
###
####################################################################################################

##FIRSTBOOT##

STRT=`pwd`
BASE=`basename "$0" ".sh" `
thisHOST=`hostname`

repLabel=""

if [ -s "${STRT}/${BASE}.${thisHOST}.DISTRO.ListOnly.txt" ]
then
	echo "\n\t First SNAPSHOT after DISTRO installation already exists.\n\t Creating normal post-installation SNAPSHOT ...\n"
	repLabel=".`date +%Y%m%d-%H%M%S `"
else
	echo "\n\t Creating first SNAPSHOT after DISTRO installation ...\n"
	repLabel=".DISTRO"
fi

ListOnly="${STRT}/${BASE}.${thisHOST}${repLabel}.ListOnly.txt"			; rm -f ${ListOnly}
ListAndVersion="${STRT}/${BASE}.${thisHOST}${repLabel}.ListAndVersion.txt"	; rm -f ${ListAndVersion}
ListVerbose="${STRT}/${BASE}.${thisHOST}${repLabel}.ListVerbose.txt"		; rm -f ${ListVerbose}

## FUTURES: md5sum for all files on system

#dpkg --get-selections >z3							# to get simple list of package names
dpkg-query -W --showformat="\${Package}\n" >"${ListOnly}"			# to get simple list of package names

dpkg-query -W --showformat="\${Package}|\${Version}\n" >"${ListAndVersion}"	# to get list of package names with versions

dpkg-query -l >"${ListVerbose}"							# to get list of packages with details of dpkg interractive session
#dpkg --list >z2								# to get list of packages with details of dpkg interractive session

( cd "${STRT}" ; ls -l "${BASE}.${thisHOST}${repLabel}."* )

echo "\n Done.\n"


exit 0
exit 0
exit 0
